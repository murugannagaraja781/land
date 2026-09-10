import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Tenkasi Dreams Land';
  static const String appTagline = 'தென்காசி கனவுகள் - Land Promoters';

  // Categories mentioned in prompt
  static const List<CategoryItem> categories = [
    CategoryItem(
      id: 'all',
      name: 'All',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    CategoryItem(
      id: 'land',
      name: 'Land',
      icon: Icons.landscape_outlined,
      activeIcon: Icons.landscape_rounded,
    ),
    CategoryItem(
      id: 'plots',
      name: 'Plots',
      icon: Icons.crop_square_outlined,
      activeIcon: Icons.crop_square_rounded,
    ),
    CategoryItem(
      id: 'house',
      name: 'House',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    CategoryItem(
      id: 'apartment',
      name: 'Apartment',
      icon: Icons.apartment_outlined,
      activeIcon: Icons.apartment_rounded,
    ),
    CategoryItem(
      id: 'rental',
      name: 'Rental',
      icon: Icons.vpn_key_outlined,
      activeIcon: Icons.vpn_key_rounded,
    ),
    CategoryItem(
      id: 'commercial',
      name: 'Commercial',
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
    ),
    CategoryItem(
      id: 'shop',
      name: 'Shop',
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
    ),
    CategoryItem(
      id: 'office',
      name: 'Office',
      icon: Icons.business_outlined,
      activeIcon: Icons.business_rounded,
    ),
    CategoryItem(
      id: 'farmLand',
      name: 'Farm Land',
      icon: Icons.nature_people_outlined,
      activeIcon: Icons.nature_people_rounded,
    ),
  ];

  // Locations for switching and filtering
  static const List<String> popularLocations = [
    'Porur, Chennai',
    'Tambaram, Chennai',
    'Sholinganallur, Chennai',
    'Guindy, Chennai',
    'Egmore, Chennai',
    'Anna Nagar, Chennai',
    'Velachery, Chennai',
    'OMR, Chennai',
    'Adyar, Chennai',
    'Tenkasi, Tamil Nadu',
    'Tirunelveli, Tamil Nadu',
    'Coimbatore, Tamil Nadu',
  ];

  // Amenities
  static const List<String> availableAmenities = [
    '24x7 Security',
    'Power Backup',
    'Covered Car Parking',
    'Swimming Pool',
    'Gymnasium',
    'Club House',
    'Children Play Area',
    'High Speed Elevator',
    'Rainwater Harvesting',
    'CCTV Surveillance',
    'Landscaped Garden',
    'Water Treatment Plant',
    'Intercom Facility',
    'Vaastu Compliant',
    'Fire Safety System',
    'EV Charging Station',
  ];

  // BHK filters
  static const List<String> bhkOptions = ['1 BHK', '2 BHK', '3 BHK', '4+ BHK'];

  // Furnishing options
  static const List<String> furnishingOptions = [
    'Fully Furnished',
    'Semi-Furnished',
    'Unfurnished',
  ];

  // Facing directions
  static const List<String> facingDirections = [
    'North',
    'East',
    'North-East',
    'South',
    'West',
  ];
}

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final IconData activeIcon;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.activeIcon,
  });
}
