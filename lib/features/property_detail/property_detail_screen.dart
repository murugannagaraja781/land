import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/land_units.dart';
import '../../core/utils/location_service.dart';
import '../../core/widgets/animated_favorite_btn.dart';
import '../../core/widgets/property_visual.dart';
import '../../models/property.dart';
import '../../state/app_state_providers.dart';
import '../chat/conversation_screen.dart';
import 'agent_profile_screen.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);
    final property = properties.cast<Property?>().firstWhere(
          (p) => p?.id == widget.propertyId,
          orElse: () => null,
        );

    if (property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property Details')),
        body: const Center(child: Text('Property not found.')),
      );
    }

    final totalImages = property.imageKeys.isNotEmpty ? property.imageKeys.length : 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main Scrollable Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Image Carousel Header
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    SizedBox(
                      height: 320,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: totalImages,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return PropertyVisual(
                            propertyType: property.propertyType,
                            visualIndex: index,
                            customImageBase64: property.customImageBase64,
                            height: 320,
                            width: double.infinity,
                            borderRadius: BorderRadius.zero,
                          );
                        },
                      ),
                    ),

                    // Top navigation floating buttons
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back Button
                            _buildCircleButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            Row(
                              children: [
                                // Share Button
                                _buildCircleButton(
                                  icon: Icons.share_outlined,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Listing link copied for "${property.title}"'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: AppColors.primaryDark,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 10),
                                // Favorite Button
                                AnimatedFavoriteButton(
                                  isFavorite: property.isFavorite,
                                  onToggle: () {
                                    ref.read(propertiesProvider.notifier).toggleFavorite(property.id);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Carousel Dots Indicator & Count Badge
                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dots
                          Row(
                            children: List.generate(totalImages, (index) {
                              final isSelected = index == _currentImageIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 5),
                                width: isSelected ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),

                          // Image Counter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1} / $totalImages Photos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Main Content Body
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -16, 0),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge & Status Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  property.propertyType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (property.isVerified) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGoldLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.accentGold, width: 0.8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.verified_rounded, size: 13, color: AppColors.accentGold),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified Listing',
                                        style: TextStyle(
                                          color: AppColors.accentGold,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            DateFormatter.timeAgo(property.postedDate),
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Price & Per Sq.ft
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            CurrencyFormatter.formatIndianPrice(property.price, isRental: property.isRental),
                            style: AppTextStyles.priceLarge.copyWith(fontSize: 28),
                          ),
                          if (property.areaSqFt > 0 && !property.isRental) ...[
                            const SizedBox(width: 10),
                            Text(
                              CurrencyFormatter.formatPerSqFt(property.price, property.areaSqFt),
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Title
                      Text(
                        property.title,
                        style: AppTextStyles.h2.copyWith(fontSize: 20),
                      ),

                      const SizedBox(height: 8),

                      // Location & Landmark
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.location,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (property.landmark != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    property.landmark!,
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 20),

                      // 3. Quick Specs Grid
                      Text('Property Overview', style: AppTextStyles.h4),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.3,
                        children: [
                          _buildSpecBox(
                            icon: Icons.straighten_rounded,
                            title: 'Area',
                            value: '${CurrencyFormatter.formatNumber(property.areaSqFt)} sq.ft',
                          ),
                          if (property.bedrooms != null)
                            _buildSpecBox(
                              icon: Icons.bed_outlined,
                              title: 'Bedrooms',
                              value: '${property.bedrooms} BHK',
                            ),
                          if (property.bathrooms != null)
                            _buildSpecBox(
                              icon: Icons.bathtub_outlined,
                              title: 'Bathrooms',
                              value: '${property.bathrooms} Baths',
                            ),
                          _buildSpecBox(
                            icon: Icons.chair_outlined,
                            title: 'Furnishing',
                            value: property.furnishingStatus,
                          ),
                          _buildSpecBox(
                            icon: Icons.explore_outlined,
                            title: 'Facing',
                            value: property.facing,
                          ),
                          _buildSpecBox(
                            icon: Icons.layers_outlined,
                            title: 'Floor',
                            value: property.floor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 20),

                      // 4. Description
                      Text('Description', style: AppTextStyles.h4),
                      const SizedBox(height: 10),
                      Text(
                        property.description,
                        maxLines: _isDescriptionExpanded ? null : 4,
                        overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _isDescriptionExpanded ? 'Read Less' : 'Read More',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 20),

                      // 5. Amenities
                      if (property.amenities.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Amenities', style: AppTextStyles.h4),
                            Text(
                              '${property.amenities.length} features',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: property.amenities.map((amenity) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    amenity,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 20),
                      ],

                      // 6. Property Specifications Table
                      Text('Property Details & Compliance', style: AppTextStyles.h4),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Property ID', property.id.toUpperCase()),
                            _buildDetailRow('Super Built-Up Area', '${property.superBuiltUpSqFt ?? property.areaSqFt} sq.ft'),
                            _buildDetailRow('Carpet Area', '${property.carpetAreaSqFt ?? (property.areaSqFt * 0.85).round()} sq.ft'),
                            _buildDetailRow(
                              'Land Measurement',
                              LandUnitConverter.formatWithConversion(
                                sqFt: property.areaSqFt,
                                preferredUnit: property.landUnit,
                                unitValue: property.landUnitValue,
                              ),
                            ),
                            _buildDetailRow('Legal Approvals', 'CMDA & RERA Approved', isHighlight: true),
                            _buildDetailRow('Water Supply', 'Borewell & Kaveri Metro Water'),
                            if (property.maintenanceMonthly != null)
                              _buildDetailRow('Monthly Maintenance', '₹${property.maintenanceMonthly!.toInt()}/mo'),
                            _buildDetailRow('Availability Status', 'Ready to Move', isLast: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 20),

                      // Location & Live GPS Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Location & Live GPS', style: AppTextStyles.h4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.gps_fixed_rounded, size: 12, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'GPS VERIFIED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    property.location,
                                    style: AppTextStyles.labelLarge.copyWith(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            if (property.landmark != null && property.landmark!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.near_me_outlined, size: 16, color: AppColors.textMuted),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Landmark: ${property.landmark}',
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            // GPS HUD Bar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${(property.latitude ?? 13.0382).toStringAsFixed(5)}° N, ${(property.longitude ?? 80.1565).toStringAsFixed(5)}° E',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Open Google Maps Live Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final lat = property.latitude ?? 13.0382;
                                  final lng = property.longitude ?? 80.1565;
                                  final url = LocationService.getGoogleMapsUrl(lat, lng, label: property.title);
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Opening Google Maps...')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.map_rounded, size: 18),
                                label: const Text('Open in Google Maps / Navigation'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 20),

                      // 7. Agent / Owner Card
                      Text('Listed By', style: AppTextStyles.h4),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryMedium],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      property.agent.name.isNotEmpty ? property.agent.name[0] : 'A',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              property.agent.name,
                                              style: AppTextStyles.h4.copyWith(fontSize: 16),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (property.agent.isVerified) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        property.agent.agencyName,
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, size: 15, color: AppColors.accentGold),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${property.agent.rating} (${property.agent.reviewsCount} reviews)',
                                            style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AgentProfileScreen(agent: property.agent),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                                  ),
                                  child: const Text('Profile', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 8. Sticky Bottom CTA Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Call button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                      onPressed: () => _handleCallAgent(context, property),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // WhatsApp direct button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4), width: 1),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366), size: 20),
                      onPressed: () async {
                        final cleanPhone = property.agent.phone.replaceAll(RegExp(r'[^0-9]'), '');
                        final text = Uri.encodeComponent('Hi ${property.agent.name}, I am interested in "${property.title}" listed on Tenkasi Dreams Land.');
                        final uri = Uri.parse('https://wa.me/$cleanPhone?text=$text');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Chat CTA Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleChatAgent(context, property),
                        icon: const Icon(Icons.forum_outlined, size: 18),
                        label: const Text('Chat with Seller'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.textPrimary),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSpecBox({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleCallAgent(BuildContext context, Property property) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Call Agent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact ${property.agent.name} regarding "${property.title}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_iphone_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    property.agent.phone,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final cleanPhone = property.agent.phone.replaceAll(RegExp(r'[^0-9]'), '');
              final text = Uri.encodeComponent('Hi ${property.agent.name}, I am interested in "${property.title}" listed on Tenkasi Dreams Land.');
              final uri = Uri.parse('https://wa.me/$cleanPhone?text=$text');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.chat_outlined, size: 16, color: Color(0xFF25D366)),
            label: const Text('WhatsApp'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF25D366)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final clean = property.agent.phone.replaceAll(RegExp(r'[^0-9+]'), '');
              final telUri = Uri(scheme: 'tel', path: clean);
              if (await canLaunchUrl(telUri)) {
                await launchUrl(telUri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dialing ${property.agent.phone}...'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _handleChatAgent(BuildContext context, Property property) async {
    await ref.read(conversationsProvider.notifier).startConversation(property);
    final convs = ref.read(conversationsProvider);
    final conv = convs.firstWhere(
      (c) => c.property.id == property.id,
      orElse: () => convs.first,
    );

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationScreen(conversationId: conv.id),
        ),
      );
    }
  }
}
