import 'package:flutter/material.dart';
import '../../models/property.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'animated_favorite_btn.dart';
import 'property_visual.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final bool isHorizontal;
  final double? width;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    required this.onFavoriteToggle,
    this.isHorizontal = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return _buildHorizontalCard(context);
    }
    return _buildVerticalCard(context);
  }

  // Large Featured Horizontal Slider Card
  Widget _buildHorizontalCard(BuildContext context) {
    final cardWidth = width ?? 290.0;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with tags
              Stack(
                children: [
                  PropertyVisual(
                    propertyType: property.propertyType,
                    customImageBase64: property.customImageBase64,
                    height: 148,
                    width: double.infinity,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  ),
                  // Top badges
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBadge(
                          text: property.propertyType,
                          backgroundColor: AppColors.primary,
                          textColor: Colors.white,
                        ),
                        if (property.isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColors.accentGoldLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.accentGold, width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 12, color: AppColors.accentGold),
                                SizedBox(width: 3),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: AppColors.accentGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Heart button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: AnimatedFavoriteButton(
                      isFavorite: property.isFavorite,
                      onToggle: onFavoriteToggle,
                    ),
                  ),
                  // Price pill over image bottom
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 0.6),
                      ),
                      child: Text(
                        CurrencyFormatter.formatIndianPrice(property.price, isRental: property.isRental),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content Details
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge.copyWith(fontSize: 14.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 8),
                    // Quick Specs
                    _buildSpecsRow(property),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Full-width Vertical Listing Card
  Widget _buildVerticalCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Stack
              Stack(
                children: [
                  PropertyVisual(
                    propertyType: property.propertyType,
                    customImageBase64: property.customImageBase64,
                    height: 180,
                    width: double.infinity,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  ),
                  // Badges top-left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBadge(
                          text: property.propertyType,
                          backgroundColor: AppColors.primary,
                          textColor: Colors.white,
                        ),
                        if (property.isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColors.accentGoldLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.accentGold, width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 12, color: AppColors.accentGold),
                                SizedBox(width: 3),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: AppColors.accentGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Heart top-right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: AnimatedFavoriteButton(
                      isFavorite: property.isFavorite,
                      onToggle: onFavoriteToggle,
                    ),
                  ),
                  // Posted time badge
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        DateFormatter.timeAgo(property.postedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Details Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price & per sqft row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          CurrencyFormatter.formatIndianPrice(property.price, isRental: property.isRental),
                          style: AppTextStyles.priceLarge.copyWith(fontSize: 21),
                        ),
                        if (property.areaSqFt > 0 && !property.isRental)
                          Text(
                            CurrencyFormatter.formatPerSqFt(property.price, property.areaSqFt),
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 12),
                    // Specs row: sqft, beds, baths, furnishing
                    _buildSpecsRow(property),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecsRow(Property prop) {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Area / Land Unit
        _buildSpecChip(
          icon: Icons.straighten_rounded,
          label: prop.landUnit != null && prop.landUnit != 'Sq.Ft' && prop.landUnitValue != null
              ? '${prop.landUnitValue} ${prop.landUnit}'
              : '${CurrencyFormatter.formatNumber(prop.areaSqFt)} sq.ft',
        ),
        if (prop.bedrooms != null)
          _buildSpecChip(
            icon: Icons.bed_outlined,
            label: '${prop.bedrooms} Beds',
          ),
        if (prop.bathrooms != null)
          _buildSpecChip(
            icon: Icons.bathtub_outlined,
            label: '${prop.bathrooms} Baths',
          ),
      ],
    );
  }

  Widget _buildSpecChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
