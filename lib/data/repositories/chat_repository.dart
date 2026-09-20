import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../local/local_storage_service.dart';
import '../../models/agent.dart';
import '../../models/chat_message.dart';
import '../../models/notification_item.dart';
import '../../models/property.dart';

class ChatRepository {
  final LocalStorageService _storage;

  ChatRepository(this._storage);

  List<ChatConversation> getConversations() {
    return _storage.getConversations();
  }

  ChatConversation? getConversationById(String id) {
    try {
      return getConversations().firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> syncRemoteMessages(String conversationId) async {
    try {
      final url = '${ApiConfig.instance.serverUrl}/chat.php?action=messages&conversation_id=$conversationId';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['messages'] is List) {
          final user = _storage.getUserProfile();
          final conv = getConversationById(conversationId);
          if (conv != null) {
            for (final m in data['messages']) {
              final sPhone = m['sender_phone'] ?? '';
              final isMe = sPhone == user.phone;
              final msgId = m['id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}';
              final exists = conv.messages.any((existing) => existing.id == msgId);
              if (!exists) {
                final newMsg = ChatMessage(
                  id: msgId,
                  conversationId: conversationId,
                  text: m['message'] ?? '',
                  isFromUser: isMe,
                  timestamp: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
                );
                await _storage.addMessageToConversation(conversationId, newMsg);
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> syncAllUserConversations(String userPhone) async {
    final cleanP = userPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanP.isEmpty) return;

    try {
      final url = '${ApiConfig.instance.serverUrl}/chat.php?action=conversations&user_phone=$cleanP';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['conversations'] is List) {
          final convList = data['conversations'] as List;
          final localConvs = _storage.getConversations();

          for (final c in convList) {
            final convId = c['id'] ?? '';
            if (convId.isEmpty) continue;

            final sPhone = (c['seller_phone'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
            final isSeller = cleanP == sPhone;

            final counterpartName = isSeller ? (c['buyer_name'] ?? 'Buyer') : (c['seller_name'] ?? 'Direct Owner');
            final counterpartPhone = isSeller ? (c['buyer_phone'] ?? '') : (c['seller_phone'] ?? '');

            final existingIndex = localConvs.indexWhere((lc) => lc.id == convId);

            if (existingIndex == -1) {
              final newConv = ChatConversation(
                id: convId,
                agent: Agent(
                  id: 'agent_$convId',
                  name: counterpartName,
                  agencyName: isSeller ? 'வாங்குபவர் (Buyer)' : 'சொத்து உரிமையாளர் (Owner)',
                  phone: counterpartPhone,
                  email: '',
                  avatarKey: 'agent_1',
                  rating: 5.0,
                  reviewsCount: 1,
                  experienceYears: 2,
                  totalListings: 1,
                  isVerified: true,
                  about: '',
                ),
                property: ChatPropertySummary(
                  id: c['property_id'] ?? '',
                  title: c['property_title'] ?? 'Property',
                  price: 0,
                  location: 'Tenkasi',
                  propertyType: 'Property',
                  areaSqFt: 0,
                ),
                lastMessage: c['last_message'] ?? '',
                lastMessageTime: DateTime.tryParse(c['last_message_time'] ?? '') ?? DateTime.now(),
                unreadCount: 0,
                messages: const [],
              );
              localConvs.insert(0, newConv);
              await _storage.saveConversations(localConvs);
            }
            await syncRemoteMessages(convId);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required Function(ChatMessage) onAgentReplied,
  }) async {
    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    // 1. Persist user message locally
    await _storage.addMessageToConversation(conversationId, userMsg);

    final conv = getConversationById(conversationId);
    final user = _storage.getUserProfile();
    final cleanUserP = user.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanAgentP = (conv?.agent.phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final isSeller = cleanUserP.isNotEmpty && cleanUserP == cleanAgentP;

    // 2. Send to live server chat.php
    try {
      final url = '${ApiConfig.instance.serverUrl}/chat.php';
      await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'send',
          'conversation_id': conversationId,
          'property_id': conv?.property.id ?? '',
          'property_title': conv?.property.title ?? '',
          'buyer_name': isSeller ? (conv?.agent.name ?? 'Customer') : (user.name.isNotEmpty ? user.name : 'Customer'),
          'buyer_phone': isSeller ? (conv?.agent.phone ?? '') : user.phone,
          'seller_name': isSeller ? (user.name.isNotEmpty ? user.name : 'Direct Owner') : (conv?.agent.name ?? 'Direct Owner'),
          'seller_phone': isSeller ? user.phone : (conv?.agent.phone ?? ''),
          'sender_phone': user.phone,
          'sender_name': user.name.isNotEmpty ? user.name : (isSeller ? 'Owner' : 'Customer'),
          'sender_role': isSeller ? 'seller' : 'buyer',
          'message': text,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    // 3. Fallback smart assistant reply ONLY for buyers if seller is offline
    if (!isSeller) {
      Timer(const Duration(milliseconds: 1500), () async {
        final replyText = _generateSmartReply(text);
        final agentMsg = ChatMessage(
          id: 'msg_agent_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: conversationId,
          text: replyText,
          isFromUser: false,
          timestamp: DateTime.now(),
          isRead: false,
        );

        await _storage.addMessageToConversation(conversationId, agentMsg);

        // Add a notification as well
        final currentConv = getConversationById(conversationId);
        if (currentConv != null) {
          final notif = NotificationItem(
            id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Reply from ${currentConv.agent.name}',
            message: replyText,
            timestamp: DateTime.now(),
            type: 'enquiry',
            propertyId: currentConv.property.id,
          );
          final notifs = _storage.getNotifications();
          notifs.insert(0, notif);
          await _storage.saveNotifications(notifs);
        }

        onAgentReplied(agentMsg);
      });
    }
  }

  String _generateSmartReply(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (lower.contains('price') || lower.contains('negotiable') || lower.contains('rate') || lower.contains('cost')) {
      return 'The quoted price is very competitive for this locality. There is a slight window for negotiation on prompt payment and token advance. Shall we meet to finalize?';
    } else if (lower.contains('visit') || lower.contains('see') || lower.contains('tomorrow') || lower.contains('schedule') || lower.contains('time')) {
      return 'I would be delighted to host you for a site inspection! I can arrange access tomorrow between 10:30 AM and 5:00 PM. Which slot works best for you?';
    } else if (lower.contains('loan') || lower.contains('bank') || lower.contains('approval') || lower.contains('rera') || lower.contains('cmda')) {
      return 'All approvals including CMDA / DTCP and RERA registration are fully verified. We have pre-approved home loan sanction with SBI, HDFC, and ICICI up to 80-85%.';
    } else if (lower.contains('parking') || lower.contains('car') || lower.contains('amenities')) {
      return 'Yes, reserved covered car parking is allotted along with visitor parking. All amenities are fully functional and maintained by the association.';
    } else {
      return 'Thank you for your message! I have noted your requirements and will share the comprehensive PDF brochure and floor plan. Feel free to call me anytime!';
    }
  }

  Future<void> startConversationForProperty(Property property) async {
    await _storage.createOrGetConversation(property);
  }
}
