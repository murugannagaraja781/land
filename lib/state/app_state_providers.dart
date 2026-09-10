import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/local_storage_service.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/property_repository.dart';
import '../models/chat_message.dart';
import '../models/notification_item.dart';
import '../models/property.dart';
import '../models/user_profile.dart';

// 1. Core Services Providers (initialized at app boot)
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('LocalStorageService must be initialized in main()');
});

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return PropertyRepository(storage);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return ChatRepository(storage);
});

// 2. Location & Active Category State
class SelectedLocationNotifier extends Notifier<String> {
  @override
  String build() {
    final storage = ref.watch(localStorageServiceProvider);
    return storage.getCurrentLocation();
  }

  void setLocation(String location) {
    state = location;
  }
}

final selectedLocationProvider = NotifierProvider<SelectedLocationNotifier, String>(
  SelectedLocationNotifier.new,
);

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setCategory(String category) {
    state = category;
  }
}

final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String>(
  SelectedCategoryNotifier.new,
);

// 3. Properties State Notifier
class PropertiesNotifier extends Notifier<List<Property>> {
  late final PropertyRepository _repo;

  @override
  List<Property> build() {
    _repo = ref.watch(propertyRepositoryProvider);
    return _repo.getAllProperties();
  }

  void refresh() {
    state = _repo.getAllProperties();
  }

  Future<void> toggleFavorite(String propertyId) async {
    await _repo.toggleFavorite(propertyId);
    state = _repo.getAllProperties();
  }

  Future<void> addProperty(Property property) async {
    await _repo.addProperty(property);
    state = _repo.getAllProperties();
  }

  Future<void> updateProperty(Property property) async {
    await _repo.updateProperty(property);
    state = _repo.getAllProperties();
  }

  Future<void> deleteProperty(String propertyId) async {
    await _repo.deleteProperty(propertyId);
    state = _repo.getAllProperties();
  }

  Future<void> markAsSold(String propertyId) async {
    final prop = _repo.getPropertyById(propertyId);
    if (prop != null) {
      final updated = prop.copyWith(status: 'sold');
      await _repo.updateProperty(updated);
      state = _repo.getAllProperties();
    }
  }

  Future<bool> syncWithServer() async {
    final synced = await _repo.syncWithRemoteServer();
    if (synced) {
      state = _repo.getAllProperties();
    }
    return synced;
  }

  Future<void> resetAllData() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.resetDemoData();
    ref.read(selectedLocationProvider.notifier).setLocation('Porur, Chennai');
    ref.read(selectedCategoryProvider.notifier).setCategory('all');
    state = _repo.getAllProperties();
  }
}

final propertiesProvider = NotifierProvider<PropertiesNotifier, List<Property>>(
  PropertiesNotifier.new,
);

// 4. Computed Providers for Home Sections
final featuredPropertiesProvider = Provider<List<Property>>((ref) {
  final all = ref.watch(propertiesProvider);
  return all.where((p) => p.isFeatured && p.status == 'active').toList();
});

final nearbyPropertiesProvider = Provider<List<Property>>((ref) {
  final location = ref.watch(selectedLocationProvider);
  final all = ref.watch(propertiesProvider).where((p) => p.status == 'active').toList();
  final cityOrArea = location.split(',').first.trim().toLowerCase();
  final matching = all.where((p) => p.location.toLowerCase().contains(cityOrArea)).toList();
  if (matching.length >= 3) return matching;
  return all.take(6).toList();
});

final latestPropertiesProvider = Provider<List<Property>>((ref) {
  final all = List<Property>.from(ref.watch(propertiesProvider).where((p) => p.status == 'active'));
  all.sort((a, b) => b.postedDate.compareTo(a.postedDate));
  return all;
});

final recommendedPropertiesProvider = Provider<List<Property>>((ref) {
  final all = ref.watch(propertiesProvider).where((p) => p.status == 'active').toList();
  return all.reversed.take(6).toList();
});

final favoritesListProvider = Provider<List<Property>>((ref) {
  final all = ref.watch(propertiesProvider);
  return all.where((p) => p.isFavorite).toList();
});

// 5. My Ads Tab & Provider
class MyAdsStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'active';

  void setFilter(String status) {
    state = status;
  }
}

final myAdsStatusFilterProvider = NotifierProvider<MyAdsStatusFilterNotifier, String>(
  MyAdsStatusFilterNotifier.new,
);

final myAdsListProvider = Provider<List<Property>>((ref) {
  final all = ref.watch(propertiesProvider).where((p) => p.isUserPosted).toList();
  final filter = ref.watch(myAdsStatusFilterProvider);
  if (filter == 'all') return all;
  return all.where((p) => p.status.toLowerCase() == filter.toLowerCase()).toList();
});

// 6. Search & Filter State
class SearchFilterState {
  final String query;
  final String categoryId;
  final String location;
  final double minPrice;
  final double maxPrice;
  final List<String> bhkList;
  final String furnishing;
  final bool verifiedOnly;
  final String sortBy; // 'price_low_to_high', 'price_high_to_low', 'newest', 'popular'

  const SearchFilterState({
    this.query = '',
    this.categoryId = 'all',
    this.location = 'All Locations',
    this.minPrice = 0,
    this.maxPrice = 50000000, // ₹5 Cr
    this.bhkList = const [],
    this.furnishing = 'Any',
    this.verifiedOnly = false,
    this.sortBy = 'newest',
  });

  bool get hasActiveFilters =>
      categoryId != 'all' ||
      location != 'All Locations' ||
      minPrice > 0 ||
      maxPrice < 50000000 ||
      bhkList.isNotEmpty ||
      furnishing != 'Any' ||
      verifiedOnly ||
      sortBy != 'newest';

  int get activeFilterCount {
    int count = 0;
    if (categoryId != 'all') count++;
    if (location != 'All Locations') count++;
    if (minPrice > 0 || maxPrice < 50000000) count++;
    if (bhkList.isNotEmpty) count += bhkList.length;
    if (furnishing != 'Any') count++;
    if (verifiedOnly) count++;
    if (sortBy != 'newest') count++;
    return count;
  }

  SearchFilterState copyWith({
    String? query,
    String? categoryId,
    String? location,
    double? minPrice,
    double? maxPrice,
    List<String>? bhkList,
    String? furnishing,
    bool? verifiedOnly,
    String? sortBy,
  }) {
    return SearchFilterState(
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      location: location ?? this.location,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      bhkList: bhkList ?? this.bhkList,
      furnishing: furnishing ?? this.furnishing,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class SearchFilterNotifier extends Notifier<SearchFilterState> {
  @override
  SearchFilterState build() => const SearchFilterState();

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  void updateCategory(String categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void updateLocation(String location) {
    state = state.copyWith(location: location);
  }

  void updatePriceRange(double min, double max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  void toggleBhk(String bhk) {
    final current = List<String>.from(state.bhkList);
    if (current.contains(bhk)) {
      current.remove(bhk);
    } else {
      current.add(bhk);
    }
    state = state.copyWith(bhkList: current);
  }

  void updateFurnishing(String furnishing) {
    state = state.copyWith(furnishing: furnishing);
  }

  void toggleVerifiedOnly(bool value) {
    state = state.copyWith(verifiedOnly: value);
  }

  void updateSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void resetFilters() {
    state = SearchFilterState(query: state.query);
  }
}

final searchFilterProvider = NotifierProvider<SearchFilterNotifier, SearchFilterState>(
  SearchFilterNotifier.new,
);

// 7. Search Results Provider
final searchResultsProvider = Provider<List<Property>>((ref) {
  final repo = ref.watch(propertyRepositoryProvider);
  final filter = ref.watch(searchFilterProvider);

  // Trigger rebuild when master properties list changes
  ref.watch(propertiesProvider);

  return repo.searchAndFilter(
    query: filter.query,
    categoryId: filter.categoryId,
    location: filter.location,
    minPrice: filter.minPrice,
    maxPrice: filter.maxPrice,
    bhkList: filter.bhkList,
    furnishing: filter.furnishing,
    verifiedOnly: filter.verifiedOnly,
    sortBy: filter.sortBy,
  );
});

// 8. Conversations Notifier
class ConversationsNotifier extends Notifier<List<ChatConversation>> {
  late final LocalStorageService _storage;
  late final ChatRepository _chatRepo;

  @override
  List<ChatConversation> build() {
    _storage = ref.watch(localStorageServiceProvider);
    _chatRepo = ref.watch(chatRepositoryProvider);
    return _storage.getConversations();
  }

  void refresh() {
    state = _storage.getConversations();
  }

  Future<void> sendMessage(String conversationId, String text) async {
    await _chatRepo.sendMessage(
      conversationId: conversationId,
      text: text,
      onAgentReplied: (agentMsg) {
        state = _storage.getConversations();
        ref.read(notificationsProvider.notifier).refresh();
      },
    );
    state = _storage.getConversations();
  }

  Future<void> startConversation(Property property) async {
    await _chatRepo.startConversationForProperty(property);
    state = _storage.getConversations();
  }
}

final conversationsProvider = NotifierProvider<ConversationsNotifier, List<ChatConversation>>(
  ConversationsNotifier.new,
);

// 9. Notifications Notifier
class NotificationsNotifier extends Notifier<List<NotificationItem>> {
  late final LocalStorageService _storage;

  @override
  List<NotificationItem> build() {
    _storage = ref.watch(localStorageServiceProvider);
    return _storage.getNotifications();
  }

  void refresh() {
    state = _storage.getNotifications();
  }

  Future<void> markAsRead(String id) async {
    await _storage.markNotificationAsRead(id);
    state = _storage.getNotifications();
  }

  Future<void> markAllAsRead() async {
    await _storage.markAllNotificationsRead();
    state = _storage.getNotifications();
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<NotificationItem>>(
  NotificationsNotifier.new,
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider);
  return list.where((n) => !n.isRead).length;
});

// 10. User Profile Notifier
class UserProfileNotifier extends Notifier<UserProfile> {
  late final LocalStorageService _storage;

  @override
  UserProfile build() {
    _storage = ref.watch(localStorageServiceProvider);
    return _storage.getUserProfile();
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _storage.saveUserProfile(profile);
    state = profile;
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(
  UserProfileNotifier.new,
);
