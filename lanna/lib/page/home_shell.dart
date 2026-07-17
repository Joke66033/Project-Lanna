import 'package:flutter/material.dart';

import 'camera.dart';
import 'favorite.dart';
import 'package:lanna/page/profile.dart';

import 'package:lanna/page/lean/learn.dart';
import 'package:lanna/page/translate_guest.dart';
import 'package:lanna/page/translate_user.dart';
import 'package:lanna/page/auth/login.dart';

// Visual Tab Indices (Bottom Menu):
// 0 = เรียนรู้
// 1 = กล้อง
// 2 = แปลภาษา (FAB center)
// 3 = รายการโปรด
// 4 = โปรไฟล์

class HomeShell extends StatefulWidget {
  final bool isGuest;
  const HomeShell({super.key, required this.isGuest});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedTab = 2; // Default tab is Translate (FAB center)

  static const Color _orange = Color(0xFF924E19);
  static const Color _grey   = Color(0xFF7A5C3A);

  // Map visual tab index to IndexedStack child index
  int get _stackIndex {
    switch (_selectedTab) {
      case 0: return 1; // เรียนรู้
      case 1: return 2; // กล้อง
      case 2: return 0; // แปลภาษา
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

      // ── FAB center (แปลภาษา) ──
      floatingActionButton: isKeyboardOpen ? null : _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── BottomAppBar ──
      bottomNavigationBar: isKeyboardOpen ? null : _buildBottomBar(),
    );
  }

  // ─── FAB ───
  Widget _buildFab() {
    final active = _selectedTab == 2;
    return GestureDetector(
      onTap: () => _onTabTap(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF924E19),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF924E19).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.translate_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'แปลภาษา',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: active ? _orange : _grey,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BottomAppBar ───
  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFEADBC8), width: 0.8),
        ),
      ),
      child: BottomAppBar(
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: Colors.white,
        elevation: 0,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.school_rounded, 'เรียนรู้'),
              _navItem(1, Icons.camera_alt_rounded, 'กล้อง'),
              const SizedBox(width: 48), // space for FAB
              _navItem(3, Icons.star_rounded, 'รายการโปรด'),
              _navItem(
                4,
                widget.isGuest
                    ? Icons.lock_outline_rounded
                    : Icons.person_rounded,
                widget.isGuest ? 'เข้าสู่ระบบ' : 'โปรไฟล์',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int tab, IconData icon, String label) {
    final active = _selectedTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTap(tab),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: active ? _orange : _grey.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: active ? FontWeight.bold : FontWeight.w400,
                color: active ? _orange : _grey.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? _orange : Colors.transparent,
              ),
            ),
          ],
        ),
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
