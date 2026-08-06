import 'login.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/api_config.dart';

const kPrimaryOrange = Color(0xFFE16905);
const kInputBg = Color(0xFFF5F5F5);

class ResetPasswordPage extends StatefulWidget {
  final String resetToken;
  const ResetPasswordPage({super.key, required this.resetToken});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_onPasswordChanged);
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _isLengthValid => _passwordCtrl.text.length >= 6;
  bool get _hasLetter => RegExp(r'[a-zA-Z]').hasMatch(_passwordCtrl.text);
  bool get _isValid => _isLengthValid && _hasLetter;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isValid) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.post(
        '${ApiConfig.otp}?action=resetPassword',
        {
          'newPassword': _passwordCtrl.text,
          'resetToken': widget.resetToken,
        },
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('Exception:')) {
          msg = msg.split('Exception:').last.trim();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade600,
            content: Text(msg),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'เปลี่ยนรหัสผ่านสำเร็จ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D1A00),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              const Text(
                'คุณต้องการไปที่ไหนต่อ?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7A5C3A),
                ),
              ),
              const SizedBox(height: 20),
              // Text link — หน้าการเรียนรู้
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home-guest',
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'หน้าการเรียนรู้',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Primary button — เข้าสู่ระบบ
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryOrange,
                  minimumSize: const Size.fromHeight(44),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: const Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // 🎨 Dotted grid background overlay
            Positioned.fill(
              child: CustomPaint(
                painter: DottedGridPainter(),
              ),
            ),
            
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildStepIndicator(3),
                      const SizedBox(height: 36),
                      const Text(
                        'ตั้งรหัสผ่านใหม่',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D1A00),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'กรุณากรอกรหัสผ่านใหม่ที่ต้องการใช้งาน',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7A5C3A),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      _passwordField(
                        controller: _passwordCtrl,
                        label: 'รหัสผ่านใหม่',
                        obscure: _obscurePassword,
                        toggle: () => setState(() => _obscurePassword = !_obscurePassword),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'กรุณากรอกรหัสผ่าน';
                          }
                          if (v.length < 6) {
                            return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                          }
                          if (!RegExp(r'[a-zA-Z]').hasMatch(v)) {
                            return 'ต้องมีตัวอักษรอย่างน้อย 1 ตัว';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _passwordField(
                        controller: _confirmPasswordCtrl,
                        label: 'ยืนยันรหัสผ่านใหม่',
                        obscure: _obscureConfirm,
                        toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'กรุณากรอกยืนยันรหัสผ่าน';
                          }
                          if (v != _passwordCtrl.text) {
                            return 'รหัสผ่านไม่ตรงกัน';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Column(
                        children: [
                          _buildChecklistRow(
                            'ตั้งรหัสผ่าน 6 ตัวขึ้นไป',
                            _isLengthValid,
                          ),
                          const SizedBox(height: 8),
                          _buildChecklistRow(
                            'มีตัวอักษรอย่างน้อย 1 ตัว',
                            _hasLetter,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: (_isValid && !_isLoading) ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF924E19),
                          disabledBackgroundColor: const Color(0xFF924E19).withValues(alpha: 0.5),
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
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'บันทึกรหัสผ่านใหม่',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF924E19),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'ย้อนกลับไปหน้าเข้าสู่ระบบ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildChecklistRow(String text, bool isValidCondition) {
    return Row(
      children: [
        Icon(
          isValidCondition ? Icons.check_circle : Icons.cancel,
          color: isValidCondition ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isValidCondition ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int activeStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(1, activeStep),
        _buildStepLine(1, activeStep),
        _buildStepCircle(2, activeStep),
        _buildStepLine(2, activeStep),
        _buildStepCircle(3, activeStep),
      ],
    );
  }

  Widget _buildStepCircle(int step, int activeStep) {
    bool isCompleted = step < activeStep;
    bool isActive = step == activeStep;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF22C55E)
            : (isActive ? const Color(0xFFE16905) : const Color(0xFFF3F4F6)),
        shape: BoxShape.circle,
        border: isActive
            ? Border.all(color: const Color(0xFFFFEDD5), width: 4)
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                step.toString(),
                style: TextStyle(
                  color: (isActive || isCompleted) ? Colors.white : const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildStepLine(int step, int activeStep) {
    bool isCompleted = step < activeStep;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF9CA3AF),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: kPrimaryOrange,
          ),
          onPressed: toggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
