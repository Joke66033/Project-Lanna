import 'package:flutter/material.dart';
import 'package:lanna/page/auth/login.dart';
import 'package:lanna/page/auth/register_otp.dart';
import 'package:lanna/services/api_service.dart';
import 'package:lanna/core/api_config.dart';

const Color kPrimaryOrange = Color(0xFFE16905);
const Color kInputBg = Color(0xFFF5F5F5);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  // ================= REGISTER -> SEND OTP =================
  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      // ส่ง OTP เพื่อยืนยันอีเมลก่อนสมัครสมาชิก
      final response = await ApiService.post(
        '${ApiConfig.otp}?action=send',
        {
          'email': email,
          'type': 'user',
          'purpose': 'register',
        },
      );

      final token = response['token']?.toString() ?? '';

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade600,
          content: Text(response['message']?.toString() ?? 'ส่งรหัส OTP ไปยังอีเมลเรียบร้อยแล้ว'),
        ),
      );

      // นำทางไปหน้ายืนยัน OTP สมัครสมาชิก
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterOtpPage(
            name: name,
            email: email,
            password: password,
            initialToken: token,
          ),
        ),
      );
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Exception:')) {
        msg = msg.split('Exception:').last.trim();
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
          content: Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          onPressed: () => Navigator.pop(context),
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
                      // Logo without border, enlarged
                      Image.asset(
                        'assets/images/logo.png',
                        height: 145,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D1A00),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ===== NAME =====
                      _input(
                        label: 'ชื่อ - นามสกุล *',
                        controller: _nameCtrl,
                        focusNode: _nameFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'กรุณากรอกชื่อ-นามสกุล';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // ===== EMAIL =====
                      _input(
                        label: 'อีเมล *',
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'กรุณากรอกอีเมล';
                          }
                          if (!v.endsWith('@gmail.com')) {
                            return 'ต้องใช้อีเมล @gmail.com เท่านั้น';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // ===== PASSWORD =====
                      _input(
                        label: 'รหัสผ่าน *',
                        controller: _passwordCtrl,
                        obscure: _obscurePassword,
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmPasswordFocus),
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
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: const Color(0xFF7A5C3A),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ===== CONFIRM PASSWORD =====
                      _input(
                        label: 'ยืนยันรหัสผ่าน *',
                        controller: _confirmPasswordCtrl,
                        obscure: _obscureConfirm,
                        focusNode: _confirmPasswordFocus,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onRegister(),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'กรุณายืนยันรหัสผ่าน';
                          }
                          if (v != _passwordCtrl.text) {
                            return 'รหัสผ่านไม่ตรงกัน';
                          }
                          return null;
                        },
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: const Color(0xFF7A5C3A),
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ===== REGISTER BUTTON =====
                      ElevatedButton(
                        onPressed: _isLoading ? null : _onRegister,
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
                                    'สมัครสมาชิก',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                                ],
                              ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'บัญชีอยู่แล้วใช่ไหม? ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7A5C3A),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/login'),
                            child: const Text(
                              'เข้าสู่ระบบ',
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

  Widget _input({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffix,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
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
