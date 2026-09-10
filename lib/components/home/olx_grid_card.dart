import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/animated_favorite_btn.dart';
import '../../core/widgets/property_visual.dart';
import '../../models/property.dart';
import '../../state/app_state_providers.dart';

class OlxGridCard extends ConsumerWidget {
  const OlxGridCard({
    super.key,
    required this.property,
    this.onTap,
  });

  final Property property;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceStr = CurrencyFormatter.formatIndianPrice(
      property.price,
      isRental: property.isRental,
    );

    final areaDisplay = property.landUnit != null && property.landUnitValue != null
        ? '${property.landUnitValue} ${property.landUnit}'
        : '${property.areaSqFt} sq.ft';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.olxBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Thumbnail with Featured Badge & Favorite Icon
              Stack(
                children: [
                  PropertyVisual(
                    propertyType: property.propertyType,
                    visualIndex: property.id.hashCode.abs() % 4,
                    customImageBase64: property.customImageBase64,
                    height: 120,
                    width: double.infinity,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),

                  // OLX Signature Yellow "FEATURED" pill
                  if (property.isFeatured)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.olxYellow,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          ref.tr('sec_hot'),
                          style: const TextStyle(
                            color: AppColors.olxNavy,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),

                  // Circular Favorite Heart Button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedFavoriteButton(
                          isFavorite: property.isFavorite,
                          size: 16,
                          onToggle: () {
                            ref.read(propertiesProvider.notifier).toggleFavorite(property.id);
                          },
                        ),
                      ),
                    ),
                  ),

                  // Verified badge
                  if (property.isVerified)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.olxNavy.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 9, color: Color(0xFF23E5DB)),
                            const SizedBox(width: 2.5),
                            Text(
                              ref.tr('verified_badge'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // 2. Card Content (OLX Typography)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bold Price (Classic OLX Dark Navy)
                          Text(
                            priceStr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.olxNavy,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),

                          // Area & Facing
                          Text(
                            '$areaDisplay ${property.facing.isNotEmpty ? "• ${property.facing}" : ""}',
                            style: const TextStyle(
                              color: AppColors.olxNavy,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),

                          // Title
                          Text(
                            property.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.olxTextSecondary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),

                      // Location & Date (OLX Footer in small uppercase)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              property.location.split(',').first.trim().toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.olxTextMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.timeAgo(property.postedDate).toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.olxTextMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
