import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lanna/services/auth_provider.dart';

import 'writing_consonant.dart';
import 'writing_vowel.dart';
import 'writing_tone.dart';
import 'writing_number.dart';

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
                      color: const Color(0xFFB8560A).withOpacity(0.12),
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
                    page: const WritingConsonantPage(),
                  ),
                  _cardItem(
                    context,
                    title: 'ฝึกเขียนสระ',
                    subtitle: 'ฝึกเขียนรูปแบบสระจมและสระลอย',
                    icon: Icons.translate_rounded,
                    accentColor: const Color(0xFFE67E22),
                    page: const WritingVowelPage(),
                  ),
                  _cardItem(
                    context,
                    title: 'ฝึกเขียนวรรณยุกต์',
                    subtitle: 'ลากเส้นรูปวรรณยุกต์ล้านนาแต่ละตั๋ว',
                    icon: Icons.graphic_eq_rounded,
                    accentColor: const Color(0xFFC87A53),
                    page: const WritingTonePage(),
                  ),
                  _cardItem(
                    context,
                    title: 'ฝึกเขียนตัวเลข',
                    subtitle: 'การเขียนนับจำนวนเลขตั๋วเมือง',
                    icon: Icons.calculate_rounded,
                    accentColor: const Color(0xFFE29C1D),
                    page: const WritingNumberPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CARD ITEM =================
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
      width: double.infinity,
      height: 98,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C4A0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD2691E).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        child: Stack(
          children: [
            // Left accent bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentColor,
                      accentColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 14, bottom: 14, right: 14),
              child: Row(
                children: [
                  // Icon container (70x70)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor,
                          accentColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Text details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D1A00),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF7A5C3A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Chevron right
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF3E8),
                      border: Border.all(color: const Color(0xFFE8C4A0), width: 1),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFB8560A),
                      size: 18,
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
}
