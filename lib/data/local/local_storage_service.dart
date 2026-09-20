import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/buyer_requirement.dart';
import '../../models/chat_message.dart';
import '../../models/notification_item.dart';
import '../../models/property.dart';
import '../../models/user_profile.dart';
import 'seed_data.dart';

class LocalStorageService {
  static const String _keyProperties = 'nestprime_properties_v1';
  static const String _keyFavorites = 'nestprime_favorites_v1';
  static const String _keyConversations = 'nestprime_conversations_v1';
  static const String _keyNotifications = 'nestprime_notifications_v1';
  static const String _keyRecentSearches = 'nestprime_recent_searches_v1';
  static const String _keySavedSearches = 'nestprime_saved_searches_v1';
  static const String _keyUserProfile = 'nestprime_user_profile_v1';
  static const String _keyCurrentLocation = 'nestprime_current_location_v1';
  static const String _keyBuyerRequirements = 'tenkasi_buyer_requirements_v1';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = LocalStorageService(prefs);
    await service._ensureInitialized();
    return service;
  }

  Future<void> _ensureInitialized() async {
    // Check if properties exist; if not, seed default properties
    if (!_prefs.containsKey(_keyProperties)) {
      await saveProperties(SeedData.initialProperties);
    }
    // Check conversations
    if (!_prefs.containsKey(_keyConversations)) {
      await saveConversations(SeedData.initialConversations);
    }
    // Check notifications
    if (!_prefs.containsKey(_keyNotifications)) {
      await saveNotifications(SeedData.initialNotifications);
    }
    // Check recent searches
    if (!_prefs.containsKey(_keyRecentSearches)) {
      await _prefs.setStringList(_keyRecentSearches, SeedData.initialRecentSearches);
    }
    // Check user profile
    if (!_prefs.containsKey(_keyUserProfile)) {
      await saveUserProfile(SeedData.initialProfile);
    }
    // Check current location
    if (!_prefs.containsKey(_keyCurrentLocation)) {
      await _prefs.setString(_keyCurrentLocation, 'Tenkasi, Tamil Nadu');
    }
    // Check buyer requirements (மக்களின் தேவை)
    if (!_prefs.containsKey(_keyBuyerRequirements)) {
      await saveBuyerRequirements(SeedData.initialBuyerRequirements);
    }
  }

  // ==========================================
  // PROPERTIES CRUD & PERSISTENCE
  // ==========================================

  List<Property> getProperties() {
    final raw = _prefs.getString(_keyProperties);
    if (raw == null || raw.isEmpty) {
      return List<Property>.from(SeedData.initialProperties);
    }
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => Property.fromMap(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return List<Property>.from(SeedData.initialProperties);
    }
  }

  Future<void> saveProperties(List<Property> properties) async {
    final raw = jsonEncode(properties.map((p) => p.toMap()).toList());
    await _prefs.setString(_keyProperties, raw);
  }

  Future<void> addProperty(Property property) async {
    final list = getProperties();
    list.insert(0, property);
    await saveProperties(list);
  }

  Future<void> updateProperty(Property property) async {
    final list = getProperties();
    final index = list.indexWhere((p) => p.id == property.id);
    if (index != -1) {
      list[index] = property;
      await saveProperties(list);
    }
  }

  Future<void> deleteProperty(String id) async {
    final list = getProperties();
    list.removeWhere((p) => p.id == id);
    await saveProperties(list);
  }

  // ==========================================
  // FAVORITES
  // ==========================================

  List<String> getFavoriteIds() {
    return _prefs.getStringList(_keyFavorites) ?? ['prop_1', 'prop_3', 'prop_5', 'prop_8', 'prop_11'];
  }

  Future<void> toggleFavorite(String propertyId) async {
    final favorites = getFavoriteIds();
    if (favorites.contains(propertyId)) {
      favorites.remove(propertyId);
    } else {
      favorites.add(propertyId);
    }
    await _prefs.setStringList(_keyFavorites, favorites);

    // Also update property isFavorite flag in properties list
    final props = getProperties();
    final index = props.indexWhere((p) => p.id == propertyId);
    if (index != -1) {
      props[index] = props[index].copyWith(isFavorite: favorites.contains(propertyId));
      await saveProperties(props);
    }
  }

  // ==========================================
  // CHATS
  // ==========================================

  List<ChatConversation> getConversations() {
    final raw = _prefs.getString(_keyConversations);
    if (raw == null || raw.isEmpty) {
      return List<ChatConversation>.from(SeedData.initialConversations);
    }
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => ChatConversation.fromMap(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return List<ChatConversation>.from(SeedData.initialConversations);
    }
  }

  Future<void> saveConversations(List<ChatConversation> convs) async {
    final raw = jsonEncode(convs.map((c) => c.toMap()).toList());
    await _prefs.setString(_keyConversations, raw);
  }

  Future<void> addMessageToConversation(String conversationId, ChatMessage message) async {
    final convs = getConversations();
    final index = convs.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final old = convs[index];
      final updatedMsgs = List<ChatMessage>.from(old.messages)..add(message);
      convs[index] = old.copyWith(
        messages: updatedMsgs,
        lastMessage: message.text,
        lastMessageTime: message.timestamp,
        unreadCount: message.isFromUser ? old.unreadCount : old.unreadCount + 1,
      );
      await saveConversations(convs);
    }
  }

  Future<void> createOrGetConversation(Property property) async {
    final convs = getConversations();
    final existingIndex = convs.indexWhere((c) => c.property.id == property.id);
    if (existingIndex == -1) {
      final newConv = ChatConversation(
        id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
        agent: property.agent,
        property: ChatPropertySummary(
          id: property.id,
          title: property.title,
          price: property.price,
          location: property.location,
          propertyType: property.propertyType,
          areaSqFt: property.areaSqFt,
        ),
        lastMessage: 'Enquired about ${property.title}',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        messages: [
          ChatMessage(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: 'conv_${DateTime.now().millisecondsSinceEpoch}',
            text: 'Hello! I am interested in "${property.title}" listed for ${property.location}. Please share further details.',
            isFromUser: true,
            timestamp: DateTime.now(),
          ),
        ],
      );
      convs.insert(0, newConv);
      await saveConversations(convs);
    }
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================

  List<NotificationItem> getNotifications() {
    final raw = _prefs.getString(_keyNotifications);
    if (raw == null || raw.isEmpty) {
      return List<NotificationItem>.from(SeedData.initialNotifications);
    }
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => NotificationItem.fromMap(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return List<NotificationItem>.from(SeedData.initialNotifications);
    }
  }

  Future<void> saveNotifications(List<NotificationItem> items) async {
    final raw = jsonEncode(items.map((n) => n.toMap()).toList());
    await _prefs.setString(_keyNotifications, raw);
  }

  Future<void> markNotificationAsRead(String id) async {
    final notifs = getNotifications();
    final idx = notifs.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifs[idx] = notifs[idx].copyWith(isRead: true);
      await saveNotifications(notifs);
    }
  }

  Future<void> markAllNotificationsRead() async {
    final notifs = getNotifications();
    final updated = notifs.map((n) => n.copyWith(isRead: true)).toList();
    await saveNotifications(updated);
  }

  // ==========================================
  // RECENT & SAVED SEARCHES
  // ==========================================

  List<String> getRecentSearches() {
    return _prefs.getStringList(_keyRecentSearches) ?? [];
  }

  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final list = getRecentSearches();
    list.removeWhere((q) => q.toLowerCase() == query.trim().toLowerCase());
    list.insert(0, query.trim());
    if (list.length > 10) list.removeLast();
    await _prefs.setStringList(_keyRecentSearches, list);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.setStringList(_keyRecentSearches, []);
  }

  List<String> getSavedSearches() {
    return _prefs.getStringList(_keySavedSearches) ?? [
      '3 BHK Villa in Porur under ₹1 Cr',
      'Residential Plots in Tambaram',
      'OMR Commercial Office with Power Backup',
    ];
  }

  Future<void> addSavedSearch(String query) async {
    final list = getSavedSearches();
    if (!list.contains(query)) {
      list.insert(0, query);
      await _prefs.setStringList(_keySavedSearches, list);
    }
  }

  Future<void> removeSavedSearch(String query) async {
    final list = getSavedSearches();
    list.remove(query);
    await _prefs.setStringList(_keySavedSearches, list);
  }

  // ==========================================
  // USER PROFILE & LOCATION
  // ==========================================

  UserProfile getUserProfile() {
    final raw = _prefs.getString(_keyUserProfile);
    if (raw == null) return SeedData.initialProfile;
    try {
      return UserProfile.fromMap(jsonDecode(raw));
    } catch (_) {
      return SeedData.initialProfile;
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs.setString(_keyUserProfile, jsonEncode(profile.toMap()));
  }

  String getCurrentLocation() {
    return _prefs.getString(_keyCurrentLocation) ?? 'Tenkasi, Tamil Nadu';
  }

  Future<void> setCurrentLocation(String location) async {
    await _prefs.setString(_keyCurrentLocation, location);
  }

  String getLocale() {
    return _prefs.getString('tenkasi_locale_v2') ?? 'ta';
  }

  Future<void> saveLocale(String locale) async {
    await _prefs.setString('tenkasi_locale_v2', locale);
  }

  // ==========================================
  // UNLOCKED PROPERTIES & FREE CONTACTS
  // ==========================================

  static const String _keyUnlockedProperties = 'tenkasi_unlocked_properties_v1';
  static const String _keyFreeContactsUsed = 'tenkasi_free_contacts_used_v1';

  List<String> getUnlockedPropertyIds() {
    return _prefs.getStringList(_keyUnlockedProperties) ?? [];
  }

  Future<void> addUnlockedProperty(String propId) async {
    final list = getUnlockedPropertyIds();
    if (!list.contains(propId)) {
      list.add(propId);
      await _prefs.setStringList(_keyUnlockedProperties, list);
    }
  }

  int getFreeContactsUsed() {
    return _prefs.getInt(_keyFreeContactsUsed) ?? 0;
  }

  Future<void> incrementFreeContactsUsed() async {
    final count = getFreeContactsUsed() + 1;
    await _prefs.setInt(_keyFreeContactsUsed, count);
  }


  // ==========================================
  // BUYER REQUIREMENTS (மக்களின் தேவை)
  // ==========================================

  List<BuyerRequirement> getBuyerRequirements() {
    final raw = _prefs.getString(_keyBuyerRequirements);
    if (raw == null || raw.isEmpty) return SeedData.initialBuyerRequirements;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) => BuyerRequirement.fromMap(item)).toList();
    } catch (_) {
      return SeedData.initialBuyerRequirements;
    }
  }

  Future<void> saveBuyerRequirements(List<BuyerRequirement> reqs) async {
    final encoded = jsonEncode(reqs.map((r) => r.toMap()).toList());
    await _prefs.setString(_keyBuyerRequirements, encoded);
  }

  Future<void> addBuyerRequirement(BuyerRequirement req) async {
    final current = getBuyerRequirements();
    final updated = [req, ...current];
    await saveBuyerRequirements(updated);
  }

  // ==========================================
  // RESET DEMO DATA
  // ==========================================

  Future<void> resetDemoData() async {
    await saveProperties(SeedData.initialProperties);
    await _prefs.setStringList(_keyFavorites, ['prop_1', 'prop_3', 'prop_5', 'prop_8', 'prop_11']);
    await saveConversations(SeedData.initialConversations);
    await saveNotifications(SeedData.initialNotifications);
    await _prefs.setStringList(_keyRecentSearches, SeedData.initialRecentSearches);
    await saveUserProfile(SeedData.initialProfile);
    await _prefs.setString(_keyCurrentLocation, 'Tenkasi, Tamil Nadu');
  }
}
