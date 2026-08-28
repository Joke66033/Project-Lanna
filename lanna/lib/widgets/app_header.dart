import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../page/profile.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack; // ✅ เพิ่ม parameter นี้

  const AppHeader({
    super.key,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
          alignment: Alignment.center,
          children: [
            // ===== ปุ่มย้อนกลับ =====
            if (onBack != null)
              Positioned(
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFD2691E)),
                  onPressed: onBack,
                ),
              ),

            // ===== ชื่อด้านบน (กึ่งกลาง) =====
            Positioned(
              left: onBack != null ? 48 : 52,
              right: 52,
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5C3A21),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ===== โลโก้ CMRU หรือ รูปโปรไฟล์ถ้าล็อกอินแล้ว =====
            Positioned(
              right: 12,
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.user;
                  final avatarUrl = user?.avatar;
                  if (user != null) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileContent(isGuest: false),
                          ),
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFE0C2),
                          border: Border.all(color: const Color(0xFFE16905), width: 1.5),
                        ),
                        child: ClipOval(
                          child: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? Image.network(
                                  resolveProfileAvatarUrl(avatarUrl).contains('?') 
                                      ? '${resolveProfileAvatarUrl(avatarUrl)}&t=${DateTime.now().millisecondsSinceEpoch}' 
                                      : '${resolveProfileAvatarUrl(avatarUrl)}?t=${DateTime.now().millisecondsSinceEpoch}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.person,
                                    color: Color(0xFFE16905),
                                    size: 24,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Color(0xFFE16905),
                                  size: 24,
                                ),
                        ),
                      ),
                    );
                  }
                  // Default logo for guests (removed as requested)
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RainbowText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  const RainbowText({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF2D1A00),
      const Color(0xFF7A5C3A),
    ];

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
