import 'package:flutter/material.dart';

class BottomNav extends StatefulWidget {
  final int index; // tab ที่ active (0=แปลภาษา, 1=กล้อง, 2=เรียนรู้, 3=พจนานุกรม, 4=auth/favorite)
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
  static const Color accentOrange = Color(0xFFB8560A);
  static const Color warmBrown = Color(0xFF7A5C3A);

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int? _hoveredSlot;
  int? _pressedSlot;

  // แปลง visual slot (0..4) เป็น tab index จริง
  // Slot 0 = เรียนรู้ (tab 2)
  // Slot 1 = กล้อง (tab 1)
  // Slot 2 = แปลภาษา (tab 0)
  // Slot 3 = พจนานุกรม (tab 3)
  // Slot 4 = เข้าสู่ระบบ / รายการโปรด (tab 4)
  static const List<int> _slotToTab = [2, 1, 0, 3, 4];

  int get _activeSlot {
    final slot = _slotToTab.indexOf(widget.index);
    return slot != -1 ? slot : 0;
  }

  @override
  Widget build(BuildContext context) {
    final IconData slot4Icon = widget.isGuest
        ? Icons.login_rounded
        : Icons.star_rounded;
    final String slot4Label = widget.isGuest ? 'เข้าสู่ระบบ' : 'รายการโปรด';

    final List<_NavItemData> items = [
      const _NavItemData(tabId: 2, icon: Icons.school_rounded, label: 'เรียนรู้'),
      const _NavItemData(tabId: 1, icon: Icons.camera_alt_rounded, label: 'กล้อง'),
      const _NavItemData(tabId: 0, icon: Icons.translate_rounded, label: 'แปลภาษา'),
      const _NavItemData(tabId: 3, icon: Icons.menu_book_rounded, label: 'พจนานุกรม'),
      _NavItemData(tabId: 4, icon: slot4Icon, label: slot4Label, isAuthSlot: true),
    ];

    final int activeSlot = _activeSlot;
    final _NavItemData activeItem = items[activeSlot];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF924E19).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, -1),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: const Color(0xFFEADBC8).withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double slotWidth = totalWidth / 5;
              const double circleSize = 50.0;
              final double circleLeft = activeSlot * slotWidth + (slotWidth - circleSize) / 2;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── วงกลม Magic Indicator ที่เลื่อนตาม Tab ที่เลือก ──
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    left: circleLeft,
                    top: -18,
                    width: circleSize,
                    height: circleSize,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFB8560A),
                            Color(0xFF924E19),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFFFFFBF7),
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF924E19).withValues(alpha: 0.38),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            activeItem.icon,
                            key: ValueKey(activeItem.tabId),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── แถวเมนูทั้ง 5 ปุ่ม ──
                  Positioned.fill(
                    child: Row(
                      children: List.generate(5, (slotIndex) {
                        final item = items[slotIndex];
                        final bool isActive = slotIndex == activeSlot;
                        final bool isHovered = _hoveredSlot == slotIndex;
                        final bool isPressed = _pressedSlot == slotIndex;

                        return Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) => setState(() => _hoveredSlot = slotIndex),
                            onExit: (_) => setState(() => _hoveredSlot = null),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (_) => setState(() => _pressedSlot = slotIndex),
                              onTapCancel: () => setState(() => _pressedSlot = null),
                              onTapUp: (_) {
                                setState(() => _pressedSlot = null);
                                if (item.isAuthSlot && widget.isGuest) {
                                  widget.onLoginTap();
                                } else {
                                  widget.onTap(item.tabId);
                                }
                              },
                              child: AnimatedScale(
                                scale: isPressed ? 0.92 : (isHovered && !isActive ? 1.06 : 1.0),
                                duration: const Duration(milliseconds: 140),
                                curve: Curves.easeOutCubic,
                                child: Container(
                                  color: Colors.transparent,
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (isActive) ...[
                                            // เมื่อ Active: เว้นระยะให้พอดีใต้วงกลม Floating
                                            const SizedBox(height: 24),
                                            Text(
                                              item.label,
                                              maxLines: 1,
                                              style: const TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: BottomNav.primaryOrange,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              width: 4,
                                              height: 4,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: BottomNav.primaryOrange,
                                              ),
                                            ),
                                          ] else ...[
                                            // เมื่อ Inactive: แสดงไอคอนปกติ + ข้อความ
                                            Icon(
                                              item.icon,
                                              size: 22,
                                              color: isHovered
                                                  ? BottomNav.accentOrange
                                                  : BottomNav.warmBrown.withValues(alpha: 0.65),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.label,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 9.0,
                                                fontWeight: FontWeight.w500,
                                                color: isHovered
                                                    ? BottomNav.accentOrange
                                                    : BottomNav.warmBrown.withValues(alpha: 0.65),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final int tabId;
  final IconData icon;
  final String label;
  final bool isAuthSlot;

  const _NavItemData({
    required this.tabId,
    required this.icon,
    required this.label,
    this.isAuthSlot = false,
  });
}
