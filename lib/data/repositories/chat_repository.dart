import 'dart:async';
import '../local/local_storage_service.dart';
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

    // Persist user message
    await _storage.addMessageToConversation(conversationId, userMsg);

    // Simulate Agent intelligent reply after 1.8 seconds
    Timer(const Duration(milliseconds: 1800), () async {
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
      final conv = getConversationById(conversationId);
      if (conv != null) {
        final notif = NotificationItem(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Reply from ${conv.agent.name}',
          message: replyText,
          timestamp: DateTime.now(),
          type: 'enquiry',
          propertyId: conv.property.id,
        );
        final notifs = _storage.getNotifications();
        notifs.insert(0, notif);
        await _storage.saveNotifications(notifs);
      }

      onAgentReplied(agentMsg);
    });
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
