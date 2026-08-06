import 'package:flutter/material.dart';
import 'learning_navigation.dart';

import '../../widgets/app_header.dart';
import 'leaning/consonant.dart';
import 'leaning/vowel.dart';
import 'leaning/tone.dart';
import 'leaning/number.dart';
import 'leaning/spelling.dart';
import 'leaning/generic_lesson_page.dart';
import 'train/writing_select_page.dart';

import 'package:lanna/services/learning_category_service.dart';
import 'package:lanna/models/category_model.dart';


/// ================= Theme =================

// Text
const Color kTextDark = Color(0xFF243A5E);
const Color kTextMain = Color(0xFF4A5D73);

// Background
const Color kBgColor = Colors.white;

/// ================= Header Gradient =================
const LinearGradient kHeaderGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    Color(0xFFFF5722), // ส้ม
    Color.fromARGB(255, 255, 200, 0), // เหลือง
    Color(0xFFE91E63), // ชมพู
  ],
);

/// ✅ Gradient หัวข้อบนสุดตามการ์ด (index 0..5)
const List<LinearGradient> kLessonHeaderGradients = [
  // 0 พยัญชนะ
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF9800), Color(0xFFFF5722), Color(0xFFE91E63)],
  ),
  // 1 สระ
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF06292), Color(0xFFFF8DA1), Color(0xFFE91E63)],
  ),
  // 2 วรรณยุกต์
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color.fromARGB(255, 21, 213, 88), Color.fromARGB(255, 126, 228, 148), Color.fromARGB(255, 64, 200, 224),],
  ),
  // 3 ตัวเลข
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
      colors: [
    Color.fromARGB(255, 0, 132, 255),
    Color.fromARGB(255, 0, 208, 255),
    Color.fromARGB(255, 0, 132, 255),
  ],
  ),
  // 4 ตัวสะกด
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFE0702F), Color.fromARGB(255, 255, 195, 104), Color.fromARGB(255, 255, 86, 14)],
  ),
  // 5 ฝึกเขียน
  LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFBA4A00), Color(0xFFFFA726), Color(0xFFBA4A00)],
  ),
];

/// ================= Card Gradients (Orange/Gold Theme Accent) =================
const List<LinearGradient> kCardGradients = [
  // 0 พยัญชนะ: Bright Orange-Gold
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB74D), Color(0xFFFF5722)],
  ),
  // 1 สระ: Sunset Amber-Orange
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFA726), Color(0xFFE65100)],
  ),
  // 2 วรรณยุกต์: Honey Gold
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
  ),
  // 3 ตัวเลข: Deep Gold
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC107), Color(0xFFF57C00)],
  ),
  // 4 ตัวสะกด: Warm Coral Orange
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A65), Color(0xFFD84315)],
  ),
  // 5 ฝึกเขียน: Premium Copper-Gold
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB300), Color(0xFFE64A19)],
  ),
];

/// Premium Cohesive Brand Accents (Warm Orange-Brown Tones)
const List<Color> kCardAccents = [
  Color(0xFFE16905), // 0 พยัญชนะ: Brand Orange
  Color(0xFF8D6E63), // 1 สระ: Warm Brown
  Color(0xFFD2691E), // 2 วรรณยุกต์: Chocolate Orange
  Color(0xFF7A5C3A), // 3 ตัวเลข: Light Brown
  Color(0xFFBF360C), // 4 ตัวสะกด: Rust Orange
  Color(0xFF5D4037), // 5 ฝึกเขียน: Dark Brown
];

/// Muted shadow color for clean card presentation
const Color kCardShadowColor = Color(0xFF8C5C3D);

/// ================= Learn Page =================
class LearnPage extends StatefulWidget {
  final bool isGuest;
  const LearnPage({super.key, required this.isGuest});

  @override
  State<LearnPage> createState() => LearnPageState();
}

class LearnPageState extends State<LearnPage> {
  int? _pressedIndex;
  int? _hoveredIndex;
  int _currentPage = -1;

  void resetToMenu() {
    if (learningNavigatorKey.currentState?.canPop() ?? false) {
      learningNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    if (_currentPage != -1) {
      setState(() {
        _currentPage = -1;
      });
    }
    _loadData();
  }
  // API Integration states
  final LearningCategoryService _categoryService = LearningCategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadApiData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final cats = await _categoryService.getActiveCategories();
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadApiData() => _loadData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_currentPage == -1) const AppHeader(title: 'เรียนรู้ภาษาล้านนา'),
            Expanded(child: _currentPage == -1 ? _menu() : _lessonContent()),
          ],
        ),
      ),
    );
  }

  /// ================= MENU =================
  Widget _menu() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFD2691E)),
            SizedBox(height: 16),
            Text(
              'กำลังโหลดข้อมูล...',
              style: TextStyle(fontSize: 12, color: Color(0xFF7A5C3A), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 70, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'ไม่สามารถดึงข้อมูลบทเรียนได้\n$_errorMsg',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadApiData,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่อีกครั้ง'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA0522D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFD2691E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== Header =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome, // ✅ เป็น icon ไม่ใช่ emoji
                  size: 20,
                  color: const Color(0xFFB8560A),
                ),
                const SizedBox(width: 8),
                const Text(
                  'หมวดหมู่การเรียนรู้',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C3A21),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'เลือกหมวดหมู่ที่ต้องการเรียนรู้',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: Color(0xFF7A5C3A),
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// ===== List of Cards =====
          /// ===== Grid of Cards (Modern 2-Column Design) =====
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.0, // perfect square
            ),
            itemCount: _categories.length + 1,
            itemBuilder: (context, index) {
              if (index < _categories.length) {
                final category = _categories[index];
                
                int pageIndex = 0;
                IconData icon = Icons.text_fields;
                if (category.categoryCode == 'LC001') {
                  pageIndex = 0;
                  icon = Icons.text_fields;
                } else if (category.categoryCode == 'LC002') {
                  pageIndex = 1;
                  icon = Icons.translate;
                } else if (category.categoryCode == 'LC003') {
                  pageIndex = 2;
                  icon = Icons.multitrack_audio;
                } else if (category.categoryCode == 'LC004') {
                  pageIndex = 3;
                  icon = Icons.calculate;
                } else if (category.categoryCode == 'LC005') {
                  pageIndex = 4;
                  icon = Icons.spellcheck;
                } else {
                  pageIndex = -99;
                  icon = Icons.help_outline;
                }

                return _gridItem(
                  index: index,
                  pageIndex: pageIndex,
                  title: category.title,
                  subtitle: category.description,
                  icon: icon,
                  badgeText: '${category.totalItems} ตัว',
                  disabled: false,
                  category: category,
                );
              } else {
                return _gridItem(
                  index: _categories.length,
                  pageIndex: 5,
                  title: 'ฝึกเขียนล้านนา',
                  subtitle: 'ฝึกเขียนด้วยนิ้วมือ',
                  icon: Icons.gesture,
                  badgeText: 'ฝึกฝน',
                  disabled: widget.isGuest,
                );
              }
            },
          ),
        ],
      ),
    ),
  );
  }


  /// ================= CONTENT =================
  Widget _lessonContent() {
    return Column(
      children: [
        if (_currentPage == 5)
          AppBar(
            backgroundColor: const Color(0xFFFFFBF7),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _currentPage = -1),
            ),
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gesture,
                  size: 26,
                  color: Color(0xFFB8560A),
                ),
                SizedBox(width: 8),
                Text(
                  'ฝึกเขียนล้านนา',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D1A00),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: IndexedStack(
            index: _currentPage,
            children: [
              ConsonantPage(isGuest: widget.isGuest, onBack: () => setState(() => _currentPage = -1)),
              VowelPage(isGuest: widget.isGuest, onBack: () => setState(() => _currentPage = -1)),
              TonePage(isGuest: widget.isGuest, onBack: () => setState(() => _currentPage = -1)),
              NumberPage(isGuest: widget.isGuest, onBack: () => setState(() => _currentPage = -1)),
              SpellingPage(isGuest: widget.isGuest, onBack: () => setState(() => _currentPage = -1)),
              const WritingSelectPage(),
            ],
          ),
        ),
      ],
    );
  }

  /// ================= GRID ITEM =================
  Widget _gridItem({
    required int index,
    required int pageIndex,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    bool disabled = false,
    CategoryModel? category,
  }) {
    final bool isHovered = _hoveredIndex == index;
    final bool isPressed = _pressedIndex == index;
    final bool active = !disabled && (isHovered || isPressed);

    final accentColor = pageIndex >= 0 && pageIndex < kCardAccents.length ? kCardAccents[pageIndex] : const Color(0xFFD2691E);

    return MouseRegion(
      onEnter: (disabled && pageIndex != 5) ? null : (_) => setState(() => _hoveredIndex = index),
      onExit: (disabled && pageIndex != 5) ? null : (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTapDown: (disabled && pageIndex != 5) ? null : (_) => setState(() => _pressedIndex = index),
        onTapCancel: () => setState(() => _pressedIndex = null),
        onTapUp: (_) {
          setState(() => _pressedIndex = null);
          if (disabled) {
            if (pageIndex == 5 && widget.isGuest) {
              _showLoginRequiredAlert(context);
            }
            return;
          }
          
          if (pageIndex == -99 && category != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GenericLessonPage(category: category),
              ),
            );
            return;
          }
          
          setState(() => _currentPage = pageIndex);
        },
        child: AnimatedScale(
          scale: disabled ? 1.0 : (active ? 0.96 : 1.0),
          duration: const Duration(milliseconds: 120),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: disabled
                  ? LinearGradient(colors: [Colors.grey.shade50, Colors.grey.shade100])
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Color(0xFFFDF6ED),
                      ],
                    ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: disabled ? Colors.grey.shade200 : const Color(0xFFEADBC8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: disabled
                      ? Colors.black.withValues(alpha: 0.01)
                      : accentColor.withValues(alpha: active ? 0.16 : 0.08),
                  blurRadius: active ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main Content centered inside the square card
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Square/Circle icon container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: disabled
                              ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    accentColor,
                                    accentColor.withValues(alpha: 0.85),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      
                      // Title
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: disabled ? Colors.grey.shade600 : accentColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Badge / Lock
                      if (disabled)
                        Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.grey.shade400,
                          size: 18,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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

      void _showLoginRequiredAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBF7),
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
                'คุณต้องเข้าสู่ระบบหรือสมัครสมาชิกก่อน\nจึงจะสามารถใช้งานเมนูฝึกเขียนได้',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
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
                Navigator.pushNamed(context, '/login');
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

/*
================================================================================
สรุปรายการไฟล์ที่ถูกย้อนกลับและรายละเอียดการเปลี่ยนแปลงที่ถูกยกเลิก (Rollback Summary)
================================================================================

1. ไฟล์ที่ได้รับผลกระทบและการย้อนกลับ:
   - lib/page/lean/learn.dart: ย้อนกลับโค้ด 2 ขั้นตอนล่าสุด (Edit 3 และ Edit 4) 
     เพื่อกลับสู่ดีไซน์หลังการแก้ไขขั้นที่ 2 (Ivory White / Cream cards with warm orange-brown accents)

2. รายละเอียดการเปลี่ยนแปลงที่ถูกยกเลิก:
   - ยกเลิก แบนเนอร์ Gradient ด้านบนเพจ (Burnt Orange Gradient Header) และคืนค่าเป็น AppHeader แบบปกติ
   - ยกเลิก การตกแต่งการ์ดแบบขอบส้มหนา 4px พร้อม Stack (Burnt Orange Left Border Cards)
   - ยกเลิก เงาสลัวโทนส้มอ่อน kShadowColor (Color(0x15C85A1E))
   - ยกเลิก การปรับอัตราส่วน GridView (childAspectRatio: 0.95) และคืนค่ากลับมาเป็น childAspectRatio: 1.12
   - คืนค่า พื้นหลังการ์ดไล่เฉดขาว-ครีมอ่อน kCardGradients จาก Colors.white และ Color(0xFFFCF8F5) เป็นต้น
   - คืนค่า สีขอบของการ์ดแต่ละใบเป็น Border.all(color: Color(0xFFF4ECE4), width: 1.5)
   - คืนค่า เงาสะท้อนของการ์ดเป็น kCardShadowColor (Color(0xFF8C5C3D))
   - คืนค่า สีสันของไอคอน, แท็ก และแถบความคืบหน้าให้มีคู่สีเฉพาะตัว (kCardAccents) ตามหมวดหมู่
   - คืนค่า ขนาดฟอนต์ในการ์ดให้อยู่ในสเกลที่พอดี (ชื่อบทเรียน 15px, คำอธิบาย 11px)
================================================================================
*/

