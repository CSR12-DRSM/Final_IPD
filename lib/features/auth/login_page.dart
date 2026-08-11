import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/badge_logo.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();
  bool obscure = true;
  bool loading = false;

  Future<void> _login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      _message('Enter email and password.');
      return;
    }
    setState(() => loading = true);
    try {
      await auth.login(email.text, password.text);
      widget.onLogin();
    } catch (e) {
      _message('Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const BadgeLogo(size: 72),
                  const SizedBox(height: 16),
                  const Text(
                    'SMART SAFETY\nBADGE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: TextButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        child: Text(obscure ? 'SHOW' : 'HIDE'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: loading ? null : _login,
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 17),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Or continue with'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ProviderButton(
                        icon: Icons.phone,
                        onTap: () => _message(
                          'Phone/OTP can be enabled after Firebase Phone Auth setup.',
                        ),
                      ),
                      const SizedBox(width: 18),
                      _ProviderButton(
                        icon: Icons.g_mobiledata,
                        onTap: () => _message(
                          'Google Sign-In can be enabled after provider setup.',
                        ),
                      ),
                      const SizedBox(width: 18),
                      _ProviderButton(
                        label: 'OTP',
                        onTap: () => _message(
                          'OTP flow is ready for Firebase Phone Auth setup.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      if (email.text.trim().isEmpty) {
                        _message('Enter your email first.');
                        return;
                      }
                      await auth.resetPassword(email.text);
                      _message('Password reset request sent.');
                    },
                    child: const Text('Forgot password?'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () => _message(
                          'Create the user in Firebase Authentication, or add a registration screen.',
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppTheme.blue,
                            fontWeight: FontWeight.w700,
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

class _ProviderButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback onTap;

  const _ProviderButton({
    this.icon,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border),
        ),
        child: Center(
          child: label != null
              ? Text(
                  label!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                )
              : Icon(icon, color: AppTheme.slate, size: 28),
        ),
      ),
    );
  }
}
