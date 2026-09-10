import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_estate_app/core/utils/currency_formatter.dart';
import 'package:real_estate_app/data/local/local_storage_service.dart';
import 'package:real_estate_app/data/repositories/property_repository.dart';
import 'package:real_estate_app/data/repositories/chat_repository.dart';
import 'package:real_estate_app/models/property.dart';
import 'package:real_estate_app/models/agent.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formats Crores correctly', () {
      expect(CurrencyFormatter.formatIndianPrice(10000000), '₹1 Cr');
      expect(CurrencyFormatter.formatIndianPrice(13500000), '₹1.35 Cr');
      expect(CurrencyFormatter.formatIndianPrice(49500000), '₹4.95 Cr');
    });

    test('formats Lakhs correctly', () {
      expect(CurrencyFormatter.formatIndianPrice(8800000), '₹88 Lakhs');
      expect(CurrencyFormatter.formatIndianPrice(4200000), '₹42 Lakhs');
      expect(CurrencyFormatter.formatIndianPrice(6400000), '₹64 Lakhs');
    });

    test('formats Rental prices with /mo suffix', () {
      expect(CurrencyFormatter.formatIndianPrice(24000, isRental: true), '₹24,000/mo');
      expect(CurrencyFormatter.formatIndianPrice(65000, isRental: true), '₹65,000/mo');
    });

    test('calculates and formats price per sq.ft correctly', () {
      expect(CurrencyFormatter.formatPerSqFt(8800000, 2150), '₹4,093 / sq.ft');
    });
  });

  group('Offline Storage & Repository Integration Tests', () {
    late LocalStorageService storage;
    late PropertyRepository propRepo;
    late ChatRepository chatRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await LocalStorageService.init();
      propRepo = PropertyRepository(storage);
      chatRepo = ChatRepository(storage);
    });

    test('seeds 22+ properties on first boot', () {
      final properties = propRepo.getAllProperties();
      expect(properties.length, greaterThanOrEqualTo(20));
      expect(properties.any((p) => p.location.contains('Porur')), isTrue);
      expect(properties.any((p) => p.location.contains('Sholinganallur')), isTrue);
      expect(properties.any((p) => p.location.contains('Tenkasi')), isTrue);
    });

    test('toggles favorite and persists state', () async {
      final initialFavs = propRepo.getFavoriteProperties();
      const targetId = 'prop_2'; // Initially not favorite
      expect(initialFavs.any((p) => p.id == targetId), isFalse);

      await propRepo.toggleFavorite(targetId);
      final updatedFavs = propRepo.getFavoriteProperties();
      expect(updatedFavs.any((p) => p.id == targetId), isTrue);

      await propRepo.toggleFavorite(targetId);
      final revertedFavs = propRepo.getFavoriteProperties();
      expect(revertedFavs.any((p) => p.id == targetId), isFalse);
    });

    test('searches and filters properties offline', () {
      // Search by text
      final searchResults = propRepo.searchAndFilter(query: 'Villa');
      expect(searchResults, isNotEmpty);
      expect(searchResults.every((p) => p.title.toLowerCase().contains('villa') || p.description.toLowerCase().contains('villa')), isTrue);

      // Filter by category
      final apartments = propRepo.searchAndFilter(categoryId: 'apartment');
      expect(apartments, isNotEmpty);
      expect(apartments.every((p) => p.propertyType == 'Apartment'), isTrue);

      // Filter by price range
      final budgetProps = propRepo.searchAndFilter(maxPrice: 5000000); // <= 50L
      expect(budgetProps, isNotEmpty);
      expect(budgetProps.every((p) => p.price <= 5000000), isTrue);

      // Filter by BHK
      final threeBhk = propRepo.searchAndFilter(bhkList: ['3 BHK']);
      expect(threeBhk, isNotEmpty);
      expect(threeBhk.every((p) => p.bedrooms == 3), isTrue);
    });

    test('adds user property to My Ads and persists', () async {
      final newProperty = Property(
        id: 'test_user_ad_1',
        title: '4 BHK Luxury Bungalow in Adyar',
        description: 'Exclusive beachfront bungalow with private garden and elevator.',
        price: 35000000,
        location: 'Adyar, Chennai',
        city: 'Chennai',
        propertyType: 'House',
        areaSqFt: 3400,
        bedrooms: 4,
        bathrooms: 4,
        agent: const Agent(
          id: 'user_agent',
          name: 'Murugan N (You)',
          agencyName: 'Direct Owner',
          phone: '+91 98401 98765',
          email: 'murugan.properties@gmail.com',
          avatarKey: 'avatar_user',
          rating: 5.0,
          reviewsCount: 12,
          experienceYears: 4,
          totalListings: 4,
          isVerified: true,
          about: 'Direct verified owner',
        ),
        postedDate: DateTime.now(),
        status: 'active',
        isUserPosted: true,
      );

      await propRepo.addProperty(newProperty);

      final myAds = propRepo.getUserPostedProperties(status: 'active');
      expect(myAds.any((p) => p.id == 'test_user_ad_1'), isTrue);

      // Update property
      final updated = newProperty.copyWith(price: 34000000);
      await propRepo.updateProperty(updated);
      final retrieved = propRepo.getPropertyById('test_user_ad_1');
      expect(retrieved?.price, 34000000);

      // Delete property
      await propRepo.deleteProperty('test_user_ad_1');
      final afterDelete = propRepo.getPropertyById('test_user_ad_1');
      expect(afterDelete, isNull);
    });

    test('chat conversation handles messages and intelligent offline replies', () async {
      final convs = chatRepo.getConversations();
      expect(convs, isNotEmpty);

      final firstConv = convs.first;
      final initialCount = firstConv.messages.length;

      await chatRepo.sendMessage(
        conversationId: firstConv.id,
        text: 'Is the price negotiable?',
        onAgentReplied: (agentMsg) {
          expect(agentMsg.isFromUser, isFalse);
          expect(agentMsg.text, contains('negotiation'));
        },
      );

      final updatedConvs = chatRepo.getConversations();
      final updatedConv = updatedConvs.firstWhere((c) => c.id == firstConv.id);
      expect(updatedConv.messages.length, greaterThan(initialCount));
    });
  });
}
