import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../state/app_state_providers.dart';
import '../legal/legal_policy_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _isOtpSent = false;
  int _timerSeconds = 30;
  Timer? _timer;

  bool _googleSignInEnabled = true;
  bool _phoneOtpEnabled = false;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAppLoginConfig();
  }

  Future<void> _fetchAppLoginConfig() async {
    try {
      final url = '${ApiConfig.instance.serverUrl}/app_config.php';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['config'] != null) {
          final cfg = data['config'];
          if (mounted) {
            setState(() {
              _googleSignInEnabled = cfg['google_sign_in_enabled'] ?? true;
              _phoneOtpEnabled = cfg['phone_otp_enabled'] ?? false;
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timerSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final updatedProfile = ref.read(userProfileProvider).copyWith(
      name: 'Tenkasi Dreams Super Admin',
      email: 'tenkasidreams@gmail.com',
      phone: '+91 98941 74944',
      city: 'Tenkasi, Tamil Nadu',
      isVerified: true,
      isLoggedIn: true,
      completionPercentage: 1.0,
    );

    ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessSnackBar('Google மூலம் வெற்றிகரமாக உள்நுழைந்தீர்கள்!');
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _sendPhoneOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('சரியான 10 இலக்க செல்போன் எண்ணை உள்ளிடவும்')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isLoading = false;
      _isOtpSent = true;
      _otpController.text = '123456'; // Default preview test OTP
    });
    _startTimer();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP எண் +91 $phone எண்ணிற்கு அனுப்பப்பட்டது! (Test OTP: 123456)'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP எண்ணை உள்ளிடவும்')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final phone = _phoneController.text.trim();
    final updatedProfile = ref.read(userProfileProvider).copyWith(
      name: 'Customer ($phone)',
      phone: '+91 $phone',
      city: 'Tenkasi, Tamil Nadu',
      isVerified: true,
      isLoggedIn: true,
    );

    ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessSnackBar('செல்போன் OTP சரிபார்க்கப்பட்டு உள்நுழைந்தீர்கள்!');
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        Navigator.pop(context, true);
      }
    }
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $msg'),
        backgroundColor: AppColors.success,
      ),
    );
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.cardShadow,
                    border: Border.all(color: AppColors.primaryLight, width: 2),
                  ),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.terrain_rounded,
                      size: 44,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // App Title
                Text(
                  ref.tr('app_title_ta'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.olxNavy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tenkasi Dreams Land Promoters',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Main Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isOtpSent ? 'OTP சரிபார்ப்பு (Verify OTP)' : 'உள்நுழைக / Sign In',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isOtpSent
                            ? '+91 ${_phoneController.text} எண்ணிற்கு வந்த 6 இலக்க OTP உள்ளிடவும்'
                            : (_googleSignInEnabled && !_phoneOtpEnabled)
                                ? 'Google (Gmail) மூலம் 1-கிளிக்கில் உடனடியாக உள்நுழையவும்'
                                : (!_googleSignInEnabled && _phoneOtpEnabled)
                                    ? 'உங்கள் செல்போன் எண் மற்றும் OTP மூலம் உள்நுழையவும்'
                                    : 'Google அல்லது செல்போன் OTP மூலம் எளிதாக உள்நுழையவும்',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (!_isOtpSent) ...[
                        if (_googleSignInEnabled) ...[
                          // 1. GOOGLE LOGIN BUTTON
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1F2937),
                              elevation: 1.5,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.2),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildGoogleGLogo(),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],

                        if (_googleSignInEnabled && _phoneOtpEnabled) ...[
                          const SizedBox(height: 18),
                          // OR Divider
                          Row(
                            children: [
                              const Expanded(child: Divider(color: AppColors.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'அல்லது (Phone OTP)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: AppColors.border)),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_phoneOtpEnabled) ...[
                          if (!_googleSignInEnabled) const SizedBox(height: 4),
                          // Phone Number Input
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: InputDecoration(
                              counterText: '',
                              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary, size: 20),
                              prefixText: '+91 ',
                              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                              hintText: '10 இலக்க செல்போன் எண்',
                              hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _sendPhoneOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'OTP பெறுக (Get OTP)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ] else ...[
                        // 2. OTP INPUT STEP
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '• • • • • •',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('உள்நுழைக (Verify & Sign In)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _isOtpSent = false),
                              child: const Text('எண் மாற்ற (Change Number)', style: TextStyle(fontSize: 11.5)),
                            ),
                            Text(
                              _timerSeconds > 0 ? 'Resend in ${_timerSeconds}s' : 'OTP Resend',
                              style: TextStyle(fontSize: 11.5, color: _timerSeconds > 0 ? AppColors.textMuted : AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Terms & Privacy Policy Notice (Play Store Compliant)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'உள்நுழைவதன் மூலம் ',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LegalPolicyScreen(initialTabIndex: 0),
                            ),
                          );
                        },
                        child: const Text(
                          'விதிமுறைகள்',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        ' & ',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LegalPolicyScreen(initialTabIndex: 1),
                            ),
                          );
                        },
                        child: const Text(
                          'தனியுரிமைக் கொள்கையை',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(
                        ' ஏற்கிறீர்கள்.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleGLogo() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintBlue = Paint()..color = const Color(0xFF4285F4);

    final rectBlue = Rect.fromCenter(
      center: Offset(center.dx + radius * 0.25, center.dy),
      width: radius * 1.1,
      height: radius * 0.45,
    );
    canvas.drawRect(rectBlue, paintBlue);

    final arcRect = Rect.fromCircle(center: center, radius: radius * 0.85);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.45;

    strokePaint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.78, 1.57, false, strokePaint);

    strokePaint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 0.79, 1.57, false, strokePaint);

    strokePaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.36, 1.57, false, strokePaint);

    strokePaint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, 3.93, 1.57, false, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
