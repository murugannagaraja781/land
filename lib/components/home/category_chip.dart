import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';

class PropertyCategoryChip extends ConsumerWidget {
  const PropertyCategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final CategoryItem category;
  final bool isSelected;
  final VoidCallback onTap;

  String _getCategoryName(WidgetRef ref, String id, String defaultName) {
    switch (id) {
      case 'all':
        return ref.tr('cat_all');
      case 'land':
      case 'plots':
        return ref.tr('cat_plots');
      case 'farmland':
      case 'farm land':
        return ref.tr('cat_farmland');
      case 'house':
      case 'villa':
        return ref.tr('cat_house');
      case 'apartment':
        return ref.tr('cat_apartment');
      case 'commercial':
      case 'shop':
      case 'office':
        return ref.tr('cat_commercial');
      case 'rental':
        return ref.tr('cat_rental');
      default:
        return defaultName;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = _getCategoryName(ref, category.id, category.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Icon (Classic OLX Avatar)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.olxNavy : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.olxNavy : AppColors.olxBorder,
                  width: isSelected ? 2 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isSelected ? category.activeIcon : category.icon,
                  size: 24,
                  color: isSelected ? AppColors.olxYellow : AppColors.olxNavy,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Label underneath
            Text(
              displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.olxNavy : AppColors.olxTextSecondary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
