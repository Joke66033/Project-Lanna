import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lanna/widgets/bottom.dart';

import 'camera.dart';
import 'dictionary.dart';
import 'favorite.dart';
import 'package:lanna/page/profile.dart';

import 'package:lanna/page/lean/learn.dart';
import 'package:lanna/page/translate_guest.dart';
import 'package:lanna/page/translate_user.dart';
import 'package:lanna/page/auth/login.dart';
import 'package:lanna/services/auth_provider.dart';

// Visual Tab Indices (BottomNav):
// 0 = แปลภาษา
// 1 = กล้อง
// 2 = เรียนรู้
// 3 = พจนานุกรม
// 4 = เข้าสู่ระบบ (guest) / รายการโปรด (user)

class HomeShell extends StatefulWidget {
  final bool isGuest;
  final int initialTab;
  const HomeShell({super.key, required this.isGuest, this.initialTab = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _selectedTab;
  final GlobalKey<LearnPageState> _learnPageKey = GlobalKey<LearnPageState>();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  // Map visual tab index directly to IndexedStack child index
  int get _stackIndex => _selectedTab;

  void _onTabTap(int tab) {
    final authProvider = context.read<AuthProvider>();
    final bool isGuest = !authProvider.isLoggedIn && widget.isGuest;
    if (isGuest && tab == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }
    if (tab == 2) {
      _learnPageKey.currentState?.resetToMenu();
    }
    setState(() => _selectedTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bool isGuest = !authProvider.isLoggedIn && widget.isGuest;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      body: IndexedStack(
        index: _stackIndex,
        children: [
          // index 0 → แปลภาษา
          isGuest
              ? const TranslateGuestPage()
              : const TranslateUserPage(),
          // index 1 → กล้อง
          CameraPage(isActive: _selectedTab == 1),
          // index 2 → เรียนรู้
          LearnPage(key: _learnPageKey, isGuest: isGuest),
          // index 3 → พจนานุกรม
          const DictionaryPage(),
          // index 4 → รายการโปรด (user) / โปรไฟล์ (guest)
          isGuest
              ? ProfileContent(isGuest: isGuest)
              : const FavoritePage(),
        ],
      ),

      // ── BottomNav ──
      bottomNavigationBar: isKeyboardOpen
          ? null
          : BottomNav(
              index: _selectedTab,
              isGuest: isGuest,
              onLoginTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              onTap: _onTabTap,
            ),
    );
  }



  // ─── Dialog ───
      void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'ต้องเข้าสู่ระบบ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D1A00),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'กรุณาเข้าสู่ระบบหรือสมัครสมาชิกก่อน\nจึงจะสามารถใช้งานรายการโปรดได้',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  height: 1.5,
                  color: Color(0xFF7A5C3A),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFEADBC8), height: 1, thickness: 1),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'เข้าสู่ระบบ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF924E19),
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFEADBC8), height: 1, thickness: 1),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/register');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'สมัครสมาชิก',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF924E19),
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFEADBC8), height: 1, thickness: 1),
            InkWell(
              onTap: () => Navigator.pop(ctx),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'ยกเลิก',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7A5C3A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
