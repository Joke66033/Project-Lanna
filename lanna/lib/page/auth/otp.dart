import 'login.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/api_config.dart';
import 'reset_password.dart';

const kPrimaryOrange = Color(0xFFE16905);

class OtpPage extends StatefulWidget {
  final String email;
  final String token;
  const OtpPage({super.key, required this.email, required this.token});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
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
    _currentToken = widget.token;
    _startTimer();

    // ให้โฟกัสช่อง OTP ช่องแรกทันที
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _startSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
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
        },
      );

      _currentToken = response['token']?.toString() ?? '';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade600,
            content: Text(response['message']?.toString() ?? 'ส่ง OTP อีกครั้งสำเร็จ'),
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

  Future<void> _verifyOtp() async {
    final otp = _otpCode;
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก OTP ให้ครบ 6 หลัก')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        '${ApiConfig.otp}?action=verify',
        {
          'email': widget.email,
          'otp': otp,
          'type': 'user',
          'token': _currentToken,
        },
      );

      final resetToken = response['resetToken']?.toString() ?? '';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade600,
            content: Text(response['message']?.toString() ?? 'ยืนยันรหัสสำเร็จ'),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(
              resetToken: resetToken,
            ),
          ),
        );
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
            // 🎨 Dotted grid background overlay
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
                    const SizedBox(height: 24),
                    _buildStepIndicator(2),
                    const SizedBox(height: 36),
                    const Text(
                      'ยืนยันรหัส OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D1A00),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'กรอกรหัส OTP 6 หลักที่ส่งไปยัง\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7A5C3A),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'รหัสยืนยัน OTP (6 หลัก)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
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
                                fontSize: 15,
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
                                setState(() {}); // Update button disabled state dynamically
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _secondsLeft > 0 ? const Color(0xFF924E19) : Colors.red,
                      ),
                    ),
                    if (_secondsLeft == 0) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _resendOtp,
                        child: const Text(
                          'ส่งรหัสอีกครั้ง',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF924E19),
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: (_isLoading || !isOtpComplete) ? null : _verifyOtp,
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
                              ),
                            )
                          : const Text(
                              'ยืนยัน OTP',
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
