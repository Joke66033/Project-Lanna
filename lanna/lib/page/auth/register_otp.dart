import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../core/api_config.dart';
import '../../services/auth_provider.dart';
import 'login.dart';
import '../home_shell.dart';

class RegisterOtpPage extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String initialToken;

  const RegisterOtpPage({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.initialToken,
  });

  @override
  State<RegisterOtpPage> createState() => _RegisterOtpPageState();
}

class _RegisterOtpPageState extends State<RegisterOtpPage> {
  static const int _startSeconds = 179;
  int _secondsLeft = _startSeconds;
  Timer? _timer;
  late String _currentToken;
  bool _isLoading = false;

  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _currentToken = widget.initialToken;
    _startTimer();

    // โฟกัสช่อง OTP ช่องแรกอัตโนมัติ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _startSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        if (mounted) {
          setState(() => _secondsLeft--);
        }
      }
    });
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        '${ApiConfig.otp}?action=send',
        {
          'email': widget.email,
          'type': 'user',
          'purpose': 'register',
        },
      );

      _currentToken = response['token']?.toString() ?? '';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade600,
            content: Text(response['message']?.toString() ?? 'ส่งรหัส OTP อีกครั้งสำเร็จ'),
          ),
        );
        _startTimer();
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

  Future<void> _verifyAndRegister() async {
    final otp = _otpCode;
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรหัส OTP ให้ครบ 6 หลัก')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. ตรวจสอบรหัส OTP ฝั่งเซิร์ฟเวอร์
      final verifyRes = await ApiService.post(
        '${ApiConfig.otp}?action=verify',
        {
          'email': widget.email,
          'otp': otp,
          'type': 'user',
          'token': _currentToken,
        },
      );

      final registerToken = verifyRes['registerToken']?.toString() ?? '';

      // 2. ทำการสมัครสมาชิกด้วยข้อมูลที่ได้รับการยืนยันแล้ว
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      await authProvider.register(
        widget.name,
        widget.email,
        widget.password,
        registerToken: registerToken,
      );

      if (!mounted) return;

      // 3. แสดงกล่องแจ้งเตือนสมัครสมาชิกสำเร็จ
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: const Color(0xFFFFFDFB),
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEADBC8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF924E19).withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF924E19),
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'สมัครสมาชิกสำเร็จ 🎉',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1A00),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'อีเมลของคุณได้รับการยืนยันเรียบร้อยแล้ว\nคุณต้องการไปที่หน้าใดต่อ?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7A5C3A),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeShell(isGuest: false),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF924E19),
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: const Text(
                    'เข้าใช้งานแอปพลิเคชัน',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: Color(0xFFEADBC8), width: 1.2),
                    backgroundColor: const Color(0xFFFFF7F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: const Text(
                    'ไปหน้าเข้าสู่ระบบ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF924E19),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    int minutes = _secondsLeft ~/ 60;
    int seconds = _secondsLeft % 60;
    String timerText = '$minutes:${seconds.toString().padLeft(2, '0')}';
    bool isOtpComplete = _otpCode.length == 6;

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
            Positioned.fill(
              child: CustomPaint(
                painter: DottedGridPainter(),
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildStepIndicator(2),
                    const SizedBox(height: 32),
                    const Text(
                      'ยืนยันรหัส OTP สมัครสมาชิก',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D1A00),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'กรุณากรอกรหัส OTP 6 หลักที่ส่งไปยังอีเมล\n${widget.email}\nเพื่อยืนยันตัวตนก่อนเปิดใช้งานบัญชี',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7A5C3A),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'รหัสยืนยัน OTP (6 หลัก)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A5C3A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        6,
                        (index) => Padding(
                          padding: EdgeInsets.only(right: index < 5 ? 6.0 : 0.0),
                          child: SizedBox(
                            width: 38,
                            height: 50,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D1A00),
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xFFFFF7F2),
                                contentPadding: EdgeInsets.zero,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFEADBC8), width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF924E19), width: 1.5),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {});
                                if (value.length == 1) {
                                  if (index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else {
                                    _focusNodes[index].unfocus();
                                  }
                                } else if (value.isEmpty) {
                                  if (index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _secondsLeft > 0 ? 'รหัสหมดอายุใน $timerText' : 'รหัส OTP หมดอายุแล้ว',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _secondsLeft > 0 ? const Color(0xFF924E19) : Colors.red,
                      ),
                    ),
                    if (_secondsLeft == 0) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isLoading ? null : _resendOtp,
                        child: const Text(
                          'ส่งรหัสอีกครั้ง',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF924E19),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: (_isLoading || !isOtpComplete) ? null : _verifyAndRegister,
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
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'ยืนยันและสมัครสมาชิก',
                              style: TextStyle(
                                fontSize: 13,
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
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
            : (isActive ? const Color(0xFF924E19) : const Color(0xFFEADBC8)),
        shape: BoxShape.circle,
        border: isActive
            ? Border.all(color: const Color(0xFFFFF7F2), width: 4)
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                step.toString(),
                style: TextStyle(
                  color: (isActive || isCompleted) ? Colors.white : const Color(0xFF7A5C3A),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
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
      color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFFEADBC8),
    );
  }
}
