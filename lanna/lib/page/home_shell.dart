import 'package:flutter/material.dart';
import 'package:lanna/widgets/bottom.dart';

import 'camera.dart';
import 'favorite.dart';
import 'package:lanna/page/profile.dart';

import 'package:lanna/page/lean/learn.dart';
import 'package:lanna/page/translate_guest.dart';
import 'package:lanna/page/translate_user.dart';
import 'package:lanna/page/auth/login.dart';

// Visual Tab Indices (BottomNav):
// 0 = แปลภาษา
// 1 = กล้อง
// 2 = เรียนรู้
// 3 = รายการโปรด
// 4 = โปรไฟล์

class HomeShell extends StatefulWidget {
  final bool isGuest;
  const HomeShell({super.key, required this.isGuest});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedTab = 0; // Default tab is Translate (index 0 in BottomNav)



  // Map visual tab index to IndexedStack child index
  int get _stackIndex {
    switch (_selectedTab) {
      case 0: return 0; // แปลภาษา
      case 1: return 2; // กล้อง
      case 2: return 1; // เรียนรู้
      case 3: return 3; // รายการโปรด
      case 4: return 4; // โปรไฟล์
      default: return 0;
    }
  }

  void _onTabTap(int tab) {
    if (widget.isGuest && tab == 3) {
      _showLoginRequiredDialog(context);
      return;
    }
    if (widget.isGuest && tab == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }
    setState(() => _selectedTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      body: IndexedStack(
        index: _stackIndex,
        children: [
          // index 0 → แปลภาษา
          widget.isGuest
              ? const TranslateGuestPage()
              : const TranslateUserPage(),
          // index 1 → เรียนรู้
          LearnPage(isGuest: widget.isGuest),
          // index 2 → กล้อง
          CameraPage(isActive: _selectedTab == 1),
          // index 3 → รายการโปรด
          const FavoritePage(),
          // index 4 → โปรไฟล์
          ProfileContent(isGuest: widget.isGuest),
        ],
      ),

      // ── BottomNav ──
      bottomNavigationBar: isKeyboardOpen
          ? null
          : BottomNav(
              index: _selectedTab,
              isGuest: widget.isGuest,
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
