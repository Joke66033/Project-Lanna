import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lanna/page/home_shell.dart';
import 'package:lanna/services/auth_provider.dart';

const kPrimaryOrange = Color(0xFF924E19);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;

  // ================= LOGIN =================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      _showError('กรุณากรอกข้อมูลให้ถูกต้อง');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      final authProvider = context.read<AuthProvider>();
      await authProvider.loginAsUser(email, password);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell(isGuest: false)),
          (route) => false,
        );
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Exception:')) {
        msg = msg.split('Exception:').last.trim();
      }
      _showError(msg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ================= ALERT =================
  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: Colors.red.shade600,
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF924E19)),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeShell(isGuest: true)),
              (_) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 🎨 Dotted grid background overlay
            Positioned.fill(
              child: CustomPaint(
                painter: DottedGridPainter(),
              ),
            ),
            
            // Content Form
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Shadowed Logo Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDFB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEADBC8), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 100,
                        ),
                      ),

                      const SizedBox(height: 36),

                      const Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D1A00),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ===== EMAIL =====
                      _input(
                        controller: _emailCtrl,
                        label: 'อีเมล',
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'กรุณากรอกอีเมล';
                          }
                          if (!v.endsWith('@gmail.com')) {
                            return 'ต้องใช้อีเมล @gmail.com เท่านั้น';
                          }
                          return null;
                        },
                        suffix: const Icon(
                          Icons.mail_outline_rounded,
                          color: Color(0xFF7A5C3A),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ===== PASSWORD =====
                      _input(
                        controller: _passwordCtrl,
                        label: 'รหัสผ่าน',
                        obscure: _obscure,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'กรุณากรอกรหัสผ่าน';
                          }
                          if (v.length < 6) {
                            return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัว';
                          }
                          return null;
                        },
                        suffix: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: const Color(0xFF7A5C3A),
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/forgot-password'),
                          child: const Text(
                            'ลืมรหัสผ่าน?',
                            style: TextStyle(
                              color: Color(0xFF924E19),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ===== LOGIN BUTTON =====
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF924E19),
                          minimumSize: const Size.fromHeight(54),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'เข้าสู่ระบบ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                ],
                              ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ยังไม่มีบัญชีใช่ไหม? ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7A5C3A),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/register'),
                            child: const Text(
                              'ลงทะเบียน',
                              style: TextStyle(
                                color: Color(0xFF924E19),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 48),
                      // Bottom Decor Divider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 40, height: 1, color: const Color(0xFFEADBC8)),
                          const SizedBox(width: 12),
                          const Icon(Icons.menu_book_rounded, color: Color(0xFFEADBC8), size: 20),
                          const SizedBox(width: 12),
                          Container(width: 40, height: 1, color: const Color(0xFFEADBC8)),
                        ],
                      ),
                      const SizedBox(height: 24),
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

  // ================= INPUT =================
  Widget _input({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2D1A00),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF7A5C3A),
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF924E19),
        ),
        filled: true,
        fillColor: const Color(0xFFFFF7F2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: Color(0xFFEADBC8), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: Color(0xFF924E19), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        suffixIcon: suffix,
      ),
    );
  }
}

class DottedGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintDot = Paint()..color = const Color(0xFFDCC8B8).withValues(alpha: 0.3);
    const double spacing = 16.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paintDot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedGridPainter oldDelegate) => false;
}
