import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lanna/page/home_shell.dart';
import 'package:lanna/services/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // 1. รออย่างน้อย 2 วินาทีเพื่อให้โลโก้แสดงผลอย่างสวยงาม
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 2. ตรวจสอบให้มั่นใจว่า AuthProvider โหลดเซสชันจากแคชเสร็จสมบูรณ์
    final authProvider = context.read<AuthProvider>();
    await authProvider.loadPersistedSession();

    if (!mounted) return;

    // 3. นำทางไปยังหน้าหลักโดยอิงตามสถานะการล็อกอินล่าสุด
    final isGuest = !authProvider.isLoggedIn;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeShell(isGuest: isGuest),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ===== LOGO (CENTER SCREEN) =====
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 400,
              ),
            ),
          ),

          // ===== BOTTOM LOADING INDICATOR =====
          const Padding(
            padding: EdgeInsets.only(bottom: 80),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFE16905),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
