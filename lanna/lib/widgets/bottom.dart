import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int index; // tab ที่ active
  final ValueChanged<int> onTap;
  final bool isGuest;
  final VoidCallback onLoginTap;
  final Animation<double>? scaleAnim;

  const BottomNav({
    super.key,
    required this.index,
    required this.onTap,
    required this.isGuest,
    required this.onLoginTap,
    this.scaleAnim,
  });

  static const Color primaryOrange = Color(0xFF924E19);

  // ───────────────────────────────────────────────────────────────────────────
  // Visual Tab Indices (BottomNav):
  //   0 = แปลภาษา (ปุ่มกลาง floating)
  //   1 = กล้อง
  //   2 = เรียนรู้
  //   3 = พจนานุกรม
  //   4 = เข้าสู่ระบบ (guest) / รายการโปรด (user)
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ไอคอน/ป้ายสำหรับ slot 4 ขึ้นอยู่กับสถานะล็อกอิน
    final IconData slot4Icon = isGuest
        ? Icons.login_rounded
        : Icons.star_rounded;
    final String slot4Label = isGuest ? 'เข้าสู่ระบบ' : 'รายการโปรด';

    return SafeArea(
      top: false,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xFFEADBC8), width: 0.8),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── แถวไอคอนซ้าย-ขวา ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildItem(context, 2, Icons.school_rounded, 'เรียนรู้'),
                _buildItem(context, 1, Icons.camera_alt_rounded, 'กล้อง'),
                // ช่องว่างกลางสำหรับปุ่ม floating
                const SizedBox(width: 48),
                _buildItem(context, 3, Icons.menu_book_rounded, 'พจนานุกรม'),
                _buildItem(context, 4, slot4Icon, slot4Label, isAuthSlot: true),
              ],
            ),

            // ── ปุ่มกลาง Floating (แปลภาษา) ──
            Positioned(
              top: -18,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => onTap(0),
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
                              color: const Color(
                                0xFF924E19,
                              ).withValues(alpha: 0.35),
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
                          fontSize: 9,
                          fontWeight: index == 0
                              ? FontWeight.bold
                              : FontWeight.w400,
                          color: index == 0
                              ? const Color(0xFF924E19)
                              : const Color(0xFF7A5C3A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    int i,
    IconData icon,
    String label, {
    bool isAuthSlot = false,
  }) {
    final bool active = index == i;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isAuthSlot && isGuest) {
            // slot 4 เมื่อ guest → ไปหน้า login
            onLoginTap();
          } else {
            onTap(i);
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: active
                    ? primaryOrange
                    : const Color(0xFF7A5C3A).withValues(alpha: 0.6),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.bold : FontWeight.w400,
                  color: active
                      ? primaryOrange
                      : const Color(0xFF7A5C3A).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? primaryOrange : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
