import 'agent.dart';

class Property {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final String city;
  final String propertyType; // Land, Plots, House, Apartment, Rental, Commercial, Shop, Office, Farm Land
  final int areaSqFt;
  final int? bedrooms;
  final int? bathrooms;
  final String furnishingStatus; // Fully Furnished, Semi-Furnished, Unfurnished, N/A
  final String facing; // North, East, etc.
  final String floor; // e.g. '3rd of 5 floors' or 'Ground floor'
  final List<String> imageKeys;
  final List<String> amenities;
  final Agent agent;
  final DateTime postedDate;
  final String status; // active, pending, sold, draft
  final bool isFavorite;
  final int views;
  final int enquiries;
  final bool isVerified;
  final bool isFeatured;
  final bool isUserPosted; // True if listed by the user (appears in My Ads)
  final int? superBuiltUpSqFt;
  final int? carpetAreaSqFt;
  final double? maintenanceMonthly;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final String? customImageBase64;
  final String? landUnit; // Cents, Grounds, Acres, Sq.Ft
  final double? landUnitValue;

  const Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.city,
    required this.propertyType,
    required this.areaSqFt,
    this.bedrooms,
    this.bathrooms,
    this.furnishingStatus = 'Unfurnished',
    this.facing = 'North',
    this.floor = 'Ground Floor',
    this.imageKeys = const [],
    this.amenities = const [],
    required this.agent,
    required this.postedDate,
    this.status = 'active',
    this.isFavorite = false,
    this.views = 0,
    this.enquiries = 0,
    this.isVerified = true,
    this.isFeatured = false,
    this.isUserPosted = false,
    this.superBuiltUpSqFt,
    this.carpetAreaSqFt,
    this.maintenanceMonthly,
    this.landmark,
    this.latitude,
    this.longitude,
    this.customImageBase64,
    this.landUnit,
    this.landUnitValue,
  });

  bool get isRental => propertyType.toLowerCase() == 'rental';

  Property copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? location,
    String? city,
    String? propertyType,
    int? areaSqFt,
    int? bedrooms,
    int? bathrooms,
    String? furnishingStatus,
    String? facing,
    String? floor,
    List<String>? imageKeys,
    List<String>? amenities,
    Agent? agent,
    DateTime? postedDate,
    String? status,
    bool? isFavorite,
    int? views,
    int? enquiries,
    bool? isVerified,
    bool? isFeatured,
    bool? isUserPosted,
    int? superBuiltUpSqFt,
    int? carpetAreaSqFt,
    double? maintenanceMonthly,
    String? landmark,
    double? latitude,
    double? longitude,
    String? customImageBase64,
    String? landUnit,
    double? landUnitValue,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      location: location ?? this.location,
      city: city ?? this.city,
      propertyType: propertyType ?? this.propertyType,
      areaSqFt: areaSqFt ?? this.areaSqFt,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      furnishingStatus: furnishingStatus ?? this.furnishingStatus,
      facing: facing ?? this.facing,
      floor: floor ?? this.floor,
      imageKeys: imageKeys ?? this.imageKeys,
      amenities: amenities ?? this.amenities,
      agent: agent ?? this.agent,
      postedDate: postedDate ?? this.postedDate,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      views: views ?? this.views,
      enquiries: enquiries ?? this.enquiries,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      isUserPosted: isUserPosted ?? this.isUserPosted,
      superBuiltUpSqFt: superBuiltUpSqFt ?? this.superBuiltUpSqFt,
      carpetAreaSqFt: carpetAreaSqFt ?? this.carpetAreaSqFt,
      maintenanceMonthly: maintenanceMonthly ?? this.maintenanceMonthly,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      customImageBase64: customImageBase64 ?? this.customImageBase64,
      landUnit: landUnit ?? this.landUnit,
      landUnitValue: landUnitValue ?? this.landUnitValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'city': city,
      'propertyType': propertyType,
      'areaSqFt': areaSqFt,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'furnishingStatus': furnishingStatus,
      'facing': facing,
      'floor': floor,
      'imageKeys': imageKeys,
      'amenities': amenities,
      'agent': agent.toMap(),
      'postedDate': postedDate.toIso8601String(),
      'status': status,
      'isFavorite': isFavorite,
      'views': views,
      'enquiries': enquiries,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'isUserPosted': isUserPosted,
      'superBuiltUpSqFt': superBuiltUpSqFt,
      'carpetAreaSqFt': carpetAreaSqFt,
      'maintenanceMonthly': maintenanceMonthly,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'customImageBase64': customImageBase64,
      'landUnit': landUnit,
      'landUnitValue': landUnitValue,
    };
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      location: map['location'] ?? '',
      city: map['city'] ?? '',
      propertyType: map['propertyType'] ?? 'House',
      areaSqFt: map['areaSqFt'] ?? 1000,
      bedrooms: map['bedrooms'],
      bathrooms: map['bathrooms'],
      furnishingStatus: map['furnishingStatus'] ?? 'Unfurnished',
      facing: map['facing'] ?? 'North',
      floor: map['floor'] ?? 'Ground Floor',
      imageKeys: List<String>.from(map['imageKeys'] ?? []),
      amenities: List<String>.from(map['amenities'] ?? []),
      agent: Agent.fromMap(map['agent'] ?? {}),
      postedDate: map['postedDate'] != null
          ? DateTime.tryParse(map['postedDate']) ?? DateTime.now()
          : DateTime.now(),
      status: map['status'] ?? 'active',
      isFavorite: map['isFavorite'] ?? false,
      views: map['views'] ?? 0,
      enquiries: map['enquiries'] ?? 0,
      isVerified: map['isVerified'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      isUserPosted: map['isUserPosted'] ?? false,
      superBuiltUpSqFt: map['superBuiltUpSqFt'],
      carpetAreaSqFt: map['carpetAreaSqFt'],
      maintenanceMonthly: (map['maintenanceMonthly'] as num?)?.toDouble(),
      landmark: map['landmark'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      customImageBase64: map['customImageBase64'],
      landUnit: map['landUnit'],
      landUnitValue: (map['landUnitValue'] as num?)?.toDouble(),
    );
  }
}
