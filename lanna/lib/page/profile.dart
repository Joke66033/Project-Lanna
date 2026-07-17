import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:lanna/services/api_service.dart';
import 'package:lanna/services/user_service.dart';
import 'package:lanna/services/profile_service.dart';
import 'package:lanna/services/auth_provider.dart';
import 'package:lanna/models/user_model.dart';
import 'package:lanna/core/api_config.dart';
import 'package:lanna/widgets/app_header.dart';

const Color kPrimaryOrange = Color(0xFFE16905);
const Color kInputBg = Color(0xFFF5F5F5);

class ProfileContent extends StatefulWidget {
  final bool isGuest;

  const ProfileContent({super.key, required this.isGuest});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent>
    with TickerProviderStateMixin {
  bool isEditing = false;
  bool _isProfileLoading = true;

  // === Controllers ===
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // === Password field states ===
  bool obscurePassword = true;
  bool obscureConfirm = true;
  String? passwordValidationError;

  // === Backup values ===
  late String oldName;
  late String oldEmail;

  // === Avatar state ===
  File? avatarFile;
  Uint8List? avatarWebImage;
  XFile? _pendingAvatarXFile; // Deferred upload: chosen but not uploaded yet

  File? oldAvatarFile;
  Uint8List? oldAvatarWebImage;

  final ImagePicker _picker = ImagePicker();

  UserModel? _user;

  final _userService = UserService();
  final _profileService = ProfileService();

  String _avatarCacheBuster = '';

  void _updateCacheBuster() {
    _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void initState() {
    super.initState();
    _updateCacheBuster();
    if (!widget.isGuest) {
      _loadProfileData();
    } else {
      setState(() => _isProfileLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _isProfileLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUserId;
      if (userId.isEmpty) {
        throw Exception('ไม่พบรหัสผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      }
      // ห้ามเปลี่ยนไปเรียก admin_user_api.php เด็ดขาด — ดึงจาก users เท่านั้น
      _user = await _userService.getUserById(userId);
      debugPrint('Loaded user profile: ${_user?.toJson()}');
      if (_user != null) {
        await ApiService.saveUserSession(_user!);
        if (!mounted) return;
        context.read<AuthProvider>().updateSession(_user);
        nameController.text = _user!.name;
        emailController.text = _user!.email;
        setState(() {
          avatarFile = null;
          avatarWebImage = null;
          _pendingAvatarXFile = null;
          _updateCacheBuster();
        });
      }
      _backupData();
    } catch (e) {
      _alert('เกิดข้อผิดพลาดในการโหลดโปรไฟล์: $e');
    } finally {
      if (mounted) {
        setState(() => _isProfileLoading = false);
      }
    }
  }

  void _backupData() {
    oldName = nameController.text;
    oldEmail = emailController.text;
    oldAvatarFile = avatarFile != null ? File(avatarFile!.path) : null;
    oldAvatarWebImage = avatarWebImage != null
        ? Uint8List.fromList(avatarWebImage!)
        : null;
  }

  void _restoreData() {
    nameController.text = oldName;
    emailController.text = oldEmail;
    passwordController.clear();
    confirmPasswordController.clear();
    obscurePassword = true;
    obscureConfirm = true;
    passwordValidationError = null;
    _pendingAvatarXFile = null;
    avatarFile = oldAvatarFile != null ? File(oldAvatarFile!.path) : null;
    avatarWebImage = oldAvatarWebImage != null
        ? Uint8List.fromList(oldAvatarWebImage!)
        : null;
  }

  void _alert(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  /// Pick image — deferred upload (only set state, don't upload yet)
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    _pendingAvatarXFile = image;

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        avatarWebImage = bytes;
        avatarFile = null;
      });
    } else {
      setState(() {
        avatarFile = File(image.path);
        avatarWebImage = null;
      });
    }
  }

  void _onAvatarTap() {
    if (!isEditing) {
      setState(() {
        isEditing = true;
      });
    }
    _pickImage();
  }

  // ===== Confirm & Save flow =====

  /// Returns list of changed fields comparing backup vs current form values
  List<Map<String, String>> _getChangedFields() {
    final changes = <Map<String, String>>[];
    final newName = nameController.text.trim();
    final newEmail = emailController.text.trim();
    final newPass = passwordController.text;

    if (newName != oldName) {
      changes.add({'label': 'ชื่อ-นามสกุล', 'old': oldName, 'new': newName});
    }
    if (newEmail != oldEmail) {
      changes.add({'label': 'อีเมล', 'old': oldEmail, 'new': newEmail});
    }
    if (newPass.isNotEmpty) {
      changes.add({'label': 'รหัสผ่าน', 'old': '(เดิม)', 'new': '(ใหม่)'});
    }
    if (_pendingAvatarXFile != null) {
      changes.add({'label': 'รูปโปรไฟล์', 'old': '(เดิม)', 'new': '(ใหม่)'});
    }
    return changes;
  }

  /// Called when user taps "บันทึก" — validates then shows confirm dialog
  Future<void> _confirmAndSave() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final pass = passwordController.text;
    final confirmPass = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty) {
      _alert('กรุณากรอกชื่อและอีเมลให้ครบ');
      return;
    }

    String? valError;
    if (pass.isNotEmpty || confirmPass.isNotEmpty) {
      if (pass.isEmpty || confirmPass.isEmpty) {
        valError = 'ต้องกรอกทั้งรหัสผ่านใหม่และยืนยันรหัสผ่าน';
      } else if (pass != confirmPass) {
        valError = 'รหัสผ่านใหม่กับยืนยันรหัสผ่านไม่ตรงกัน';
      } else if (pass.length < 6) {
        valError = 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      }
    }
    if (valError != null) {
      setState(() => passwordValidationError = valError);
      _alert(valError);
      return;
    } else {
      setState(() => passwordValidationError = null);
    }

    final changes = _getChangedFields();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => _ConfirmEditDialog(
        changes: changes,
        hasChanges: changes.isNotEmpty,
        autoCloseDuration: const Duration(seconds: 8),
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    await _saveProfileAndShowSuccess();
  }

  /// Performs the actual API call after user confirmed, then shows success dialog
  Future<void> _saveProfileAndShowSuccess() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final pass = passwordController.text;

    if (_user == null) return;
    setState(() => _isProfileLoading = true);

    try {
      String? newAvatarUrl;
      final userId = _user!.userId;

      if (_pendingAvatarXFile != null) {
        if (kIsWeb) {
          final bytes = await _pendingAvatarXFile!.readAsBytes();
          newAvatarUrl = await _profileService.uploadProfileImageBytes(
            userId,
            bytes,
            _pendingAvatarXFile!.name,
          );
        } else {
          newAvatarUrl = await _profileService.uploadProfileImage(
            userId,
            File(_pendingAvatarXFile!.path),
          );
        }
        debugPrint('Uploaded avatar successfully. New URL: $newAvatarUrl');
      }

      final Map<String, dynamic> fields = {'username': name, 'email': email};
      if (newAvatarUrl != null && newAvatarUrl.isNotEmpty) {
        fields['avatar'] = newAvatarUrl;
      }
      if (pass.isNotEmpty) {
        fields['password'] = pass;
      }

      final updatedUser = await _userService.updateUser(userId, fields);

      await ApiService.saveUserSession(updatedUser);
      if (!mounted) return;
      context.read<AuthProvider>().updateSession(updatedUser);

      setState(() {
        _user = updatedUser;
        isEditing = false;
        _pendingAvatarXFile = null;
        avatarFile = null;
        avatarWebImage = null;
        passwordController.clear();
        confirmPasswordController.clear();
        obscurePassword = true;
        obscureConfirm = true;
        passwordValidationError = null;
        _updateCacheBuster();
      });
      _backupData();

      if (!mounted) return;
      await _showSuccessDialog();
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Exception:')) msg = msg.split('Exception:').last.trim();
      _alert('บันทึกข้อมูลล้มเหลว: $msg');
    } finally {
      if (mounted) setState(() => _isProfileLoading = false);
    }
  }

  /// Shows success dialog after data is saved
  Future<void> _showSuccessDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade600,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'แก้ไขข้อมูลสำเร็จ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _loadProfileData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ตกลง',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Delete user account
  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบบัญชี ⚠️'),
        content: const Text(
          'การดำเนินการนี้ไม่สามารถย้อนกลับได้\nคุณต้องการลบบัญชีของคุณอย่างถาวรใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบบัญชี', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isProfileLoading = true);
    try {
      if (_user != null) {
        await _userService.deleteUser(_user!.userId);
      }

      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();

      _alert('ลบบัญชีเรียบร้อยแล้ว', success: true);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      _alert('ไม่สามารถลบบัญชีได้: $e');
    } finally {
      if (mounted) {
        setState(() => _isProfileLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGuest) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFBF7),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppHeader(title: 'เข้าสู่ระบบ'),
              Expanded(
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isProfileLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryOrange),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7), // Light warm Lanna background color
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(title: 'โปรไฟล์'),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover Banner Section
                    SizedBox(
                      height: 220,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 160,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFE16905),
                                  Color(0xFF8D6E63),
                                ],
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(32),
                                bottomRight: Radius.circular(32),
                              ),
                            ),
                          ),
                          // Overlapping Avatar Card
                          Positioned(
                            top: 100,
                            child: GestureDetector(
                              onTap: _onAvatarTap,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 56,
                                  backgroundColor: const Color(0xFFFFE0C2),
                                  child: _buildAvatarWidget(),
                                ),
                              ),
                            ),
                          ),
                          // Camera Icon overlay (Edit mode)
                          if (isEditing)
                            Positioned(
                              top: 174,
                              right: MediaQuery.of(context).size.width / 2 - 58,
                              child: GestureDetector(
                                onTap: _onAvatarTap,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: kPrimaryOrange,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10), // Gap to accommodate overlapping avatar

            // Name and Email under Avatar
            Center(
              child: Column(
                children: [
                  Text(
                    nameController.text.isNotEmpty ? nameController.text : (_user?.name ?? 'ไม่ระบุชื่อ'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D1A00),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? '',
                    style: TextStyle(
                      fontSize: 8,
                      color: const Color(0xFF7A5C3A).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CARD 1: PERSONAL INFORMATION
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Color(0xFFF0E5D8), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.badge_outlined,
                                    color: kPrimaryOrange,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'ข้อมูลส่วนตัว',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D1A00),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: Color(0xFFF0E5D8)),

                            // Fields
                            _inputField(
                              'ชื่อ-นามสกุล',
                              nameController,
                              prefixIcon: Icons.person_outline,
                            ),
                            const SizedBox(height: 20),

                            _inputField(
                              'อีเมล',
                              emailController,
                              prefixIcon: Icons.mail_outline,
                            ),

                            // Password Fields (only in edit mode)
                            if (isEditing) ...[
                              const SizedBox(height: 20),
                              const Divider(height: 16, color: Color(0xFFF0E5D8)),
                              const SizedBox(height: 8),
                              _inputField(
                                'รหัสผ่านใหม่',
                                passwordController,
                                prefixIcon: Icons.lock_outline,
                                obscure: obscurePassword,
                                hintText: 'เว้นว่างไว้หากไม่ต้องการเปลี่ยน',
                                suffix: IconButton(
                                  icon: Icon(
                                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              _inputField(
                                'ยืนยันรหัสผ่านใหม่',
                                confirmPasswordController,
                                prefixIcon: Icons.lock_clock_outlined,
                                obscure: obscureConfirm,
                                hintText: 'เว้นว่างไว้หากไม่ต้องการเปลี่ยน',
                                suffix: IconButton(
                                  icon: Icon(
                                    obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscureConfirm = !obscureConfirm;
                                    });
                                  },
                                ),
                              ),
                              if (passwordValidationError != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  passwordValidationError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CARD 2: ACTION BUTTONS (Save / Edit)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: !isEditing
                        ? ElevatedButton(
                            onPressed: () {
                              _backupData();
                              setState(() => isEditing = true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
                              shadowColor: kPrimaryOrange.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'แก้ไขข้อมูลส่วนตัว',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    _restoreData();
                                    setState(() => isEditing = false);
                                    _alert('ยกเลิกการแก้ไข');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: const BorderSide(color: Color(0xFFD2691E), width: 1.5),
                                    foregroundColor: const Color(0xFFD2691E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'ยกเลิก',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _confirmAndSave,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 2,
                                    shadowColor: kPrimaryOrange.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'บันทึก',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 24),

                  // CARD 3: ACCOUNT CONTROLS (Logout / Delete)
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Color(0xFFF0E5D8), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.manage_accounts_outlined,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'การจัดการบัญชี',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D1A00),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Color(0xFFF0E5D8)),

                          // Logout list tile/button
                          InkWell(
                            onTap: () async {
                              final auth = context.read<AuthProvider>();
                              await auth.logout();
                              if (!context.mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.logout, color: Colors.redAccent, size: 22),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Text(
                                      'ออกจากระบบ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2D1A00),
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Delete Account list tile/button
                          InkWell(
                            onTap: _deleteAccount,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 22),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Text(
                                      'ลบบัญชีผู้ใช้',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80), // extra padding for bottom navigation
                ],
              ),
            ),
            const SizedBox(height: 80), // extra padding for bottom navigation
          ],
        ),
      ),
    ),
  ],
),
),
);
}

  // ===== Avatar helpers =====

  Widget _buildAvatarWidget() {
    if (kIsWeb && avatarWebImage != null) {
      return ClipOval(
        child: Image.memory(
          avatarWebImage!,
          width: 112,
          height: 112,
          fit: BoxFit.cover,
        ),
      );
    }
    if (!kIsWeb && avatarFile != null) {
      return ClipOval(
        child: Image.file(
          avatarFile!,
          width: 112,
          height: 112,
          fit: BoxFit.cover,
        ),
      );
    }

    final avatarUrl = _user?.avatar;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // 1. Check if the path is a local file path and exists on disk
      if (!kIsWeb && !avatarUrl.startsWith('http://') && !avatarUrl.startsWith('https://')) {
        final localFile = File(avatarUrl);
        if (localFile.existsSync()) {
          return ClipOval(
            child: Image.file(
              localFile,
              width: 112,
              height: 112,
              fit: BoxFit.cover,
            ),
          );
        }

        // 2. If it does not exist locally, treat it as a relative server path
        // router expects format: /LANNA/lanna/assets/images/profile/filename
        String relativePath = avatarUrl;
        if (relativePath.contains('\\') || relativePath.contains('/')) {
          final filename = relativePath.split(RegExp(r'[/\\]')).last;
          relativePath = '/LANNA/lanna/assets/images/profile/$filename';
        } else {
          relativePath = '/LANNA/lanna/assets/images/profile/$relativePath';
        }

        final resolvedUrl = '${ApiConfig.baseUrl}$relativePath';
        return _buildNetworkAvatar(resolvedUrl);
      } else {
        // 3. Absolute URL from server, normalize host/port
        String resolvedUrl = avatarUrl;
        if (!kIsWeb) {
          try {
            final uri = Uri.parse(resolvedUrl);
            final baseUri = Uri.parse(ApiConfig.baseUrl);
            resolvedUrl = uri.replace(
              scheme: baseUri.scheme,
              host: baseUri.host,
              port: baseUri.port,
            ).toString();
          } catch (e) {
            debugPrint('Error parsing avatarUrl URI: $e');
          }
        }
        return _buildNetworkAvatar(resolvedUrl);
      }
    }

    // Fallback: show first letter of username on orange background
    final initial = (_user != null && _user!.name.trim().isNotEmpty)
        ? _user!.name.trim()[0].toUpperCase()
        : '?';
    return Container(
      width: 112,
      height: 112,
      decoration: const BoxDecoration(
        color: kPrimaryOrange,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 33,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkAvatar(String resolvedUrl) {
    // Add cache buster query parameter to prevent caching issues
    final cacheBuster = _avatarCacheBuster.isNotEmpty ? 't=$_avatarCacheBuster' : 't=${DateTime.now().millisecondsSinceEpoch}';
    final finalUrl = resolvedUrl.contains('?') ? '$resolvedUrl&$cacheBuster' : '$resolvedUrl?$cacheBuster';

    return ClipOval(
      child: Image.network(
        finalUrl,
        width: 112,
        height: 112,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading avatar network image from URL: $finalUrl');
          debugPrint('Exception details: $error');
          if (stackTrace != null) {
            debugPrint('Stack trace: $stackTrace');
          }
          return const Icon(Icons.person, size: 60, color: Colors.grey);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kPrimaryOrange,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    required IconData prefixIcon,
    bool obscure = false,
    Widget? suffix,
    String? readOnlyValue,
    String? hintText,
  }) {
    // If a readOnlyValue is provided and we're in read-only mode, show that value
    final showStaticValue = !isEditing && readOnlyValue != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7A5C3A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isEditing ? Colors.white : const Color(0xFFF9F6F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEditing ? kPrimaryOrange : const Color(0xFFEDD5B3),
              width: isEditing ? 1.5 : 1.0,
            ),
            boxShadow: isEditing
                ? [
                    BoxShadow(
                      color: kPrimaryOrange.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                prefixIcon,
                color: isEditing ? kPrimaryOrange : const Color(0xFF7A5C3A).withOpacity(0.7),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: showStaticValue
                    ? Text(
                        readOnlyValue,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2D1A00),
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : TextField(
                        controller: controller,
                        readOnly: !isEditing,
                        obscureText: obscure,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2D1A00),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: hintText,
                          hintStyle: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.shade400,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
              ),
              if (suffix != null) suffix,
            ],
          ),
        ),
      ],
    );
  }
}

/// ============================================================
/// Confirmation dialog with auto-close progress bar
/// ============================================================
class _ConfirmEditDialog extends StatefulWidget {
  final List<Map<String, String>> changes;
  final bool hasChanges;
  final Duration autoCloseDuration;

  const _ConfirmEditDialog({
    required this.changes,
    required this.hasChanges,
    required this.autoCloseDuration,
  });

  @override
  State<_ConfirmEditDialog> createState() => _ConfirmEditDialogState();
}

class _ConfirmEditDialogState extends State<_ConfirmEditDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.autoCloseDuration,
    );
    _controller.addListener(() {
      if (!mounted) return;
      setState(() {}); // rebuild to update progress bar
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // Auto-close with "cancel" result (false)
        Navigator.of(context).pop(false);
      }
    });
    // Start immediately — progress bar goes from full → empty
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss(bool result) {
    _controller.stop();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final double progress = 1.0 - _controller.value; // full → empty

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Question mark icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF42A5F5),
                        width: 2.5,
                      ),
                      color: const Color(0xFFE3F2FD),
                    ),
                    child: const Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'ยืนยันการแก้ไขข้อมูล?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // Changes list
                  if (!widget.hasChanges) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'ไม่มีการเปลี่ยนแปลงข้อมูล',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 8),
                      ),
                    ),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'รายการที่เปลี่ยนแปลง:',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.changes.map((change) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  change['label'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 8),
                                    children: [
                                      TextSpan(
                                        text: change['old'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationColor: Colors.red,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: '  →  ',
                                        style: TextStyle(color: Colors.black45),
                                      ),
                                      TextSpan(
                                        text: change['new'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Buttons
                  if (widget.hasChanges)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _dismiss(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                            child: const Text(
                              'ยกเลิก',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _dismiss(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryOrange,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'ตกลง',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _dismiss(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: const Text(
                          'ปิด',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Auto-close countdown progress bar (orange, shrinks from full → empty)
            Container(
              height: 5,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: const BoxDecoration(
                    color: kPrimaryOrange,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
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
