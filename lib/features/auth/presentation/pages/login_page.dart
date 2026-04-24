import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:email_validator/email_validator.dart';

import 'package:beer_store_app/core/routes/app_router.dart';
import 'package:beer_store_app/core/widgets/auth_header.dart';
import 'package:beer_store_app/core/widgets/custom_text_field.dart';
import 'package:beer_store_app/core/widgets/custom_button.dart';
import 'package:beer_store_app/core/widgets/divider_with_text.dart';
import 'package:beer_store_app/core/widgets/google_sign_in_button.dart';
import 'package:beer_store_app/core/widgets/loading_overlay.dart';

import 'package:beer_store_app/features/auth/presentation/providers/auth_provider.dart'
    as auth;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// ================= EMAIL LOGIN =================
  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<auth.AuthProvider>();

    final ok = await authProvider.loginWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    _handleLoginResult(ok, authProvider);
  }

  /// ================= GOOGLE LOGIN =================
  Future<void> _loginGoogle() async {
    final authProvider = context.read<auth.AuthProvider>();

    final ok = await authProvider.loginWithGoogle();

    if (!mounted) return;
    _handleLoginResult(ok, authProvider);
  }

  /// ================= HANDLE RESULT =================
  void _handleLoginResult(bool ok, auth.AuthProvider authProvider) {
    if (ok) {
      Navigator.pushReplacementNamed(
        context,
        AppRouter.dashboard,
      );
    } else if (authProvider.status == auth.AuthStatus.emailNotVerified) {
      Navigator.pushReplacementNamed(
        context,
        AppRouter.verifyEmail,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ================= FORGOT PASSWORD =================
  void _showForgotPasswordDialog(BuildContext context) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: CustomTextField(
          label: 'Email',
          hint: 'Email terdaftar',
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.sendPasswordResetEmail(
                email: ctrl.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link reset password dikirim'),
                  ),
                );
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<auth.AuthProvider>().isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Masuk ke akun...',
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  const AuthHeader(
                    icon: Icons.lock_open_outlined,
                    title: 'Selamat Datang',
                    subtitle: 'Masuk ke akun Anda untuk melanjutkan',
                  ),

                  const SizedBox(height: 32),

                  /// EMAIL
                  CustomTextField(
                    label: 'Email',
                    hint: 'contoh@email.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (v) {
                      if (v?.isEmpty ?? true) {
                        return 'Email wajib diisi';
                      }
                      if (!EmailValidator.validate(v!)) {
                        return 'Format email salah';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  /// PASSWORD
                  CustomTextField(
                    label: 'Password',
                    hint: 'Masukkan password',
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPass
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _showPass = !_showPass),
                    ),
                    validator: (v) =>
                        (v?.isEmpty ?? true)
                            ? 'Password wajib diisi'
                            : null,
                  ),

                  const SizedBox(height: 8),

                  /// FORGOT PASSWORD
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          _showForgotPasswordDialog(context),
                      child: const Text('Lupa Password?'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// LOGIN BUTTON
                  CustomButton(
                    label: 'Masuk',
                    onPressed: _loginEmail,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 20),

                  const DividerWithText(text: 'atau masuk dengan'),

                  const SizedBox(height: 20),

                  /// GOOGLE BUTTON
                  GoogleSignInButton(
                    onPressed: _loginGoogle,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 24),

                  /// REGISTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun? '),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(
                          context,
                          AppRouter.register,
                        ),
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}