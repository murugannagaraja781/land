import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/common/app_bar_widget.dart';
import '../../components/common/empty_state_widget.dart';
import '../../components/home/category_chip.dart';
import '../../components/home/featured_property_card.dart';
import '../../components/home/olx_grid_card.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/property.dart';
import '../../state/app_state_providers.dart';
import '../auth/login_screen.dart';
import '../calculator/land_calculator_screen.dart';
import '../legal/legal_advice_bottom_sheet.dart';
import '../post_property/post_property_wizard.dart';
import '../property_detail/property_detail_screen.dart';
import '../requirements/buyer_requirements_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToSearch;

  const HomeScreen({super.key, this.onNavigateToSearch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCategory = ref.watch(selectedCategoryProvider);
    final featured = ref.watch(featuredPropertiesProvider);
    final latest = ref.watch(latestPropertiesProvider);
    final nearby = ref.watch(nearbyPropertiesProvider);

    // Filter properties if category selected
    final List<Property> displayedList;
    if (activeCategory == 'all') {
      displayedList = latest;
    } else {
      final repo = ref.watch(propertyRepositoryProvider);
      ref.watch(propertiesProvider); // reactivity
      displayedList = repo.getPropertiesByCategory(activeCategory);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.read(propertiesProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // 1. Navy Blue App Bar (Logo, Location, Search)
            SliverToBoxAdapter(
              child: AppBarWidget(onNavigateToSearch: onNavigateToSearch),
            ),

            // 2. Hero Banner
            SliverToBoxAdapter(
              child: _buildHeroBanner(context, ref),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),

            // 3. Quick Services: மக்களின் தேவை & நில அளவை கால்குலேட்டர்
            SliverToBoxAdapter(
              child: _buildQuickToolsRow(context, ref),
            ),

            // 3.1 Legal Advice Lawyer Consultation Banner (NEW!)
            SliverToBoxAdapter(
              child: _buildLegalAdviceBanner(context),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 14),
            ),

            // 4. Category Image Grid (Balanced 2×3: வீடு, நிலம், தோட்டம், கடை, அபார்ட்மெண்ட், வாடகைக்கு)
            SliverToBoxAdapter(
              child: _buildCategoryGrid(context, ref, activeCategory),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),

            // 5. Verification Banner
            SliverToBoxAdapter(
              child: _buildVerificationBanner(context, ref),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 8),
            ),

            // 5. Category-filtered view or Full Feed
            if (activeCategory != 'all') ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${displayedList.length} ${ref.tr('sec_available')}',
                        style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(selectedCategoryProvider.notifier).setCategory('all');
                        },
                        child: Text(ref.tr('sec_show_all')),
                      ),
                    ],
                  ),
                ),
              ),
              // Dynamic Post Ad CTA Banner specifically adapted to the selected Category
              SliverToBoxAdapter(
                child: _buildCategoryPostBanner(context, ref, activeCategory),
              ),
              if (displayedList.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    onAction: () {
                      ref.read(selectedCategoryProvider.notifier).setCategory('all');
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.67,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final prop = displayedList[index];
                        return OlxGridCard(
                          property: prop,
                          onTap: () => _openDetail(context, prop),
                        );
                      },
                      childCount: displayedList.length,
                    ),
                  ),
                ),
            ] else ...[
              // Recommended Properties Section Header
              SliverToBoxAdapter(
                child: _buildRecommendedHeader(context, ref),
              ),

              // Featured Properties Carousel
              if (featured.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 290,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: featured.length,
                      itemBuilder: (context, index) {
                        final prop = featured[index];
                        return FeaturedPropertyCard(
                          property: prop,
                          onTap: () => _openDetail(context, prop),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Nearby Properties Section
              if (nearby.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ref.tr('sec_nearby'),
                          style: AppTextStyles.h3.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          ref.tr('sec_recommended_sub'),
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 290,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: nearby.length,
                      itemBuilder: (context, index) {
                        final prop = nearby[index];
                        return FeaturedPropertyCard(
                          property: prop,
                          width: 260,
                          onTap: () => _openDetail(context, prop),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // Fresh Recommendations / Latest Listings Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ref.tr('sec_latest'),
                        style: AppTextStyles.h3.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${latest.length} ${ref.tr('sec_available')}',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),

              // 2-Column Grid Feed
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.67,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final prop = latest[index];
                      return OlxGridCard(
                        property: prop,
                        onTap: () => _openDetail(context, prop),
                      );
                    },
                    childCount: latest.length,
                  ),
                ),
              ),
            ],

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Hero Banner with exact screenshot image =====
  Widget _buildHeroBanner(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (onNavigateToSearch != null) {
              onNavigateToSearch!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            }
          },
          child: Image.asset(
            'assets/images/hero_banner.png',
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              color: const Color(0xFF0D47A1),
              child: Center(
                child: Text(
                  ref.tr('hero_title'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== Category Grid (Balanced 3×2: வீடு, நிலம், தோட்டம் / கடை, அபார்ட்மெண்ட், வாடகைக்கு) =====
  Widget _buildCategoryGrid(BuildContext context, WidgetRef ref, String activeCategory) {
    final catList = AppConstants.categories.where((c) => c.id != 'all').toList();
    final row1 = catList.take(3).toList();
    final row2 = catList.skip(3).take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header: சொத்து வகைகள்
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF0D47A1)),
                    const SizedBox(width: 6),
                    Text(
                      ref.tr('sec_categories'),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (activeCategory != 'all')
                  GestureDetector(
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).setCategory('all');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ref.tr('sec_show_all'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Row 1: 3 categories (வீடு, நிலம் / மனை, தோட்டம்)
          Row(
            children: row1.map((cat) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: PropertyCategoryChip(
                    category: cat,
                    isSelected: activeCategory == cat.id,
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).setCategory(
                        activeCategory == cat.id ? 'all' : cat.id,
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Row 2: 3 categories (கடை / வணிகம், அபார்ட்மெண்ட், வாடகைக்கு)
          Row(
            children: row2.map((cat) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: PropertyCategoryChip(
                    category: cat,
                    isSelected: activeCategory == cat.id,
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).setCategory(
                        activeCategory == cat.id ? 'all' : cat.id,
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===== Verification Banner =====
  Widget _buildVerificationBanner(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD0E4FF),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Shield Icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: const Center(
              child: Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF1565C0),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ref.tr('verify_title'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ref.tr('verify_subtitle'),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // CTA Button
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ref.tr('verify_cta'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Quick Tools: மக்களின் தேவை & நில அளவை கால்குலேட்டர் =====
  Widget _buildQuickToolsRow(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // 1. மக்களின் தேவை (Buyer Requirements Board)
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuyerRequirementsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF581C87), Color(0xFF7E22CE), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7E22CE).withValues(alpha: 0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'புதியது',
                            style: TextStyle(
                              color: Color(0xFF78350F),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'மக்களின் தேவை',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'தேவை பதிவு & வாங்குபவர்கள்',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 2. நில அளவை கால்குலேட்டர் (Land Unit Converter)
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LandCalculatorScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF047857).withValues(alpha: 0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'அளவை',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'நில அளவை மாற்றி',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'சென்ட், குழி, ஏக்கர், ஹெக்டேர்',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Recommended Header =====
  Widget _buildRecommendedHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 20, color: Color(0xFF0284C7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ref.tr('sec_recommended_title'),
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
            child: Text(
              ref.tr('sec_recommended_view_all'),
              style: const TextStyle(
                color: Color(0xFF0284C7),
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Legal Advice Banner =====
  Widget _buildLegalAdviceBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => LegalAdviceBottomSheet.show(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                  ),
                  child: const Center(
                    child: Icon(Icons.gavel_rounded, color: Color(0xFFFBBF24), size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '⚖️ வழக்கறிஞர் சட்ட ஆலோசனை',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'நேரடி உதவி',
                              style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'பத்திர பதிவு, பட்டா, EC & சொத்து ஆவண சரிபார்ப்பு',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'கேட்க',
                        style: TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF0F172A)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== Dynamic Category Post Ad CTA Banner =====
  Widget _buildCategoryPostBanner(BuildContext context, WidgetRef ref, String activeCategory) {
    IconData icon;
    String titleTa;
    String subTa;
    String buttonText;
    Color primaryColor;
    Color accentColor;

    switch (activeCategory.toLowerCase()) {
      case 'farmland':
      case 'farm':
        icon = Icons.agriculture_rounded;
        titleTa = '🌴 உங்கள் தோட்டத்தை விற்க வேண்டுமா?';
        subTa = 'விவசாய பூமி, போர்வெல், இலவச EB விவரங்களுடன் எளிதாக விளம்பரம் செய்க';
        buttonText = '+ தோட்டம் விளம்பரம்';
        primaryColor = const Color(0xFF14532D);
        accentColor = const Color(0xFF16A34A);
        break;
      case 'apartment':
        icon = Icons.apartment_rounded;
        titleTa = '🏢 உங்கள் அபார்ட்மெண்ட் / பிளாட் விற்க வேண்டுமா?';
        subTa = 'BHK, லிப்ட், UDS, அப்ரூவல் விவரங்களுடன் வாங்குபவர்களை உடனடியாக சென்றடையுங்கள்';
        buttonText = '+ பிளாட் விளம்பரம்';
        primaryColor = const Color(0xFF1E3A8A);
        accentColor = const Color(0xFF2563EB);
        break;
      case 'rental':
      case 'rent':
        icon = Icons.vpn_key_rounded;
        titleTa = '🔑 வாடகைக்கு / லீசுக்கு விட வேண்டுமா?';
        subTa = 'வீடு, கடை, காம்ப்ளக்ஸ், இடம் - சரியான வாடகைதாரரை உடனே கண்டறியுங்கள்';
        buttonText = '+ வாடகை விளம்பரம்';
        primaryColor = const Color(0xFF7C2D12);
        accentColor = const Color(0xFFEA580C);
        break;
      case 'shop':
      case 'commercial':
        icon = Icons.storefront_rounded;
        titleTa = '🏪 கடை / வணிக இடத்தை விற்க அல்லது வாடகைக்கு விடவா?';
        subTa = 'மெயின் ரோடு, பஜார், ஷோரூம், அலுவலக இடங்களை நேரடி வாடிக்கையாளர்களிடம் விளம்பரப்படுத்துங்கள்';
        buttonText = '+ கடை விளம்பரம்';
        primaryColor = const Color(0xFF78350F);
        accentColor = const Color(0xFFD97706);
        break;
      case 'land':
      case 'plots':
        icon = Icons.landscape_rounded;
        titleTa = '📐 உங்கள் வீட்டுமனையை / காலி இடத்தை விற்க வேண்டுமா?';
        subTa = 'DTCP / RERA அப்ரூவல், சென்ட், சதுர அடி விவரங்களுடன் உடனடியாக விற்கலாம்';
        buttonText = '+ இடம் விளம்பரம்';
        primaryColor = const Color(0xFF064E3B);
        accentColor = const Color(0xFF059669);
        break;
      case 'house':
      default:
        icon = Icons.home_rounded;
        titleTa = '🏠 உங்கள் தனி வீட்டை விரைவாக விற்க வேண்டுமா?';
        subTa = 'தனி வீடு, வில்லா, பண்ணை வீடு - நேரடி வாங்குபவர்களிடம் விளம்பரம் செய்க';
        buttonText = '+ வீடு விளம்பரம்';
        primaryColor = const Color(0xFF0F172A);
        accentColor = const Color(0xFF0284C7);
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            final user = ref.read(userProfileProvider);
            final catToUse = (activeCategory == 'all' || activeCategory.isEmpty) ? 'land' : activeCategory;
            if (!user.isLoggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    onLoginSuccess: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostPropertyWizard(initialCategory: catToUse),
                        ),
                      );
                    },
                  ),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostPropertyWizard(initialCategory: catToUse),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.88)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titleTa,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subTa,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Property property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailScreen(propertyId: property.id),
      ),
    );
  }
}
