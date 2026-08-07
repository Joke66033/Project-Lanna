import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lanna/services/auth_provider.dart';
import '../learning_navigation.dart';

import 'writing_mode.dart';
import 'writing_data.dart';
import 'writing_custom_word_page.dart';

class WritingSelectPage extends StatelessWidget {
  const WritingSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'กรุณาเข้าสู่ระบบก่อนใช้งานโหมดฝึกเขียน',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7A5C3A),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Title Header matching LearnPage AppBar style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFB8560A).withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.brush_rounded,
                      size: 18,
                      color: Color(0xFFB8560A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'เลือกหมวดที่ต้องการฝึกเขียน',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F3A60),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _cardItem(
                    context,
                    title: 'ฝึกเขียนพยัญชนะ',
                    subtitle: 'เรียนรู้วิธีการลากเส้นพยัญชนะล้านนา',
                    icon: Icons.text_fields_rounded,
                    accentColor: const Color(0xFFD35400),
                    page: const WritingCategoryLoaderPage(
                      title: 'ฝึกเขียนพยัญชนะ',
                      categoryCharIds: 'CL0001,CL0002,CL0003',
                      writingType: WritingType.consonant,
                    ),
                  ),
                  _cardItem(
                    context,
                    title: 'ฝึกเขียนสระ',
                    subtitle: 'ฝึกเขียนรูปแบบสระจมและสระลอย',
                    icon: Icons.translate_rounded,
                    accentColor: const Color(0xFFE67E22),
                    page: const WritingCategoryLoaderPage(
                      title: 'ฝึกเขียนสระ',
                      categoryCharIds: 'CL0004,CL0005',
                      writingType: WritingType.vowel,
                    ),
                  ),
                  _cardItem(
                    context,
                    title: 'ฝึกเขียนวรรณยุกต์',
                    subtitle: 'ลากเส้นรูปวรรณยุกต์ล้านนาแต่ละตั๋ว',
                    icon: Icons.graphic_eq_rounded,
                    accentColor: const Color(0xFFC87A53),
                    page: const WritingCategoryLoaderPage(
                      title: 'ฝึกเขียนวรรณยุกต์',
                      categoryCharIds: 'CL0006',
                      writingType: WritingType.tone,
                    ),
                  ),
                  _cardItem(
                    context,
                    title: 'ฝึกเขียนตัวเลข',
                    subtitle: 'การเขียนนับจำนวนเลขตั๋วเมือง',
                    icon: Icons.calculate_rounded,
                    accentColor: const Color(0xFFE29C1D),
                    page: const WritingCategoryLoaderPage(
                      title: 'ฝึกเขียนตัวเลข',
                      categoryCharIds: 'CL0007',
                      writingType: WritingType.number,
                    ),
                  ),
                  // ―― การ์ดฝึกเขียนคำที่กำหนดเอง ――
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE8C4A0),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF924E19,
                          ).withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        pushLearningPage(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WritingCustomWordPage(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Left accent bar
                            Container(
                              width: 4,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE16905),
                                    Color(0xFFB8560A),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Icon container with soft gradient background
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE16905).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 24,
                                color: Color(0xFFE16905),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Text block
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ฝึกเขียนคำที่กำหนดเอง',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C1A04),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'พิมพ์คำภาษาไทยเพื่อฝึกผสมคำล้านนา',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF7A5C3A),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Small arrow
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFF7A5C3A),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Widget page,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEADBC8).withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            pushLearningPage(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 14),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C1A04),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF7A5C3A),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF7A5C3A),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
