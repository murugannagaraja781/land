import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/common/bottom_nav_bar.dart';
import '../../state/app_state_providers.dart';
import '../../core/theme/app_colors.dart';
import '../account/account_screen.dart';
import '../auth/login_screen.dart';
import '../chat/chat_list_screen.dart';
import '../home/home_screen.dart';
import '../my_ads/my_ads_screen.dart';
import '../post_property/post_property_wizard.dart';
import '../search/search_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _openPostAdWizard() {
    final user = ref.read(userProfileProvider);
    if (!user.isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    final activeCat = ref.read(selectedCategoryProvider);
    final catToUse = (activeCat == 'all' || activeCat.isEmpty) ? 'land' : activeCat;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostPropertyWizard(initialCategory: catToUse),
        fullscreenDialog: true,
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'விளம்பரம் செய்ய உள்நுழைக',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'சொத்து விளம்பரம் பதிவிட உங்கள் கணக்கில் உள்நுழைந்திருக்க வேண்டும். உள்நுழைந்து உங்கள் விளம்பரங்களை எளிதாக நிர்வகிக்கலாம்.',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ரத்து செய்', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    onLoginSuccess: () {
                      _openPostAdWizard();
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('உள்நுழைக'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Unread messages count for chat badge
    final conversations = ref.watch(conversationsProvider);
    final totalUnreadChats = conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

    final screens = [
      HomeScreen(
        onNavigateToSearch: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          );
        },
      ),
      const ChatListScreen(),
      const MyAdsScreen(),
      AccountScreen(onNavigateToMyAds: () => _onTabTapped(2)),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onPostAdTap: _openPostAdWizard,
        unreadChatsCount: totalUnreadChats,
      ),
    );
  }
}
