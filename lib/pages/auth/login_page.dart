import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onSkip;
  const LoginPage({super.key, this.onSkip});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final err = await context.read<AuthService>().signIn(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (mounted) setState(() { _loading = false; _error = err; });
    if (err == null && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientHero),
        child: SafeArea(
          child: Column(
            children: [
              // Close / skip
              Align(
                alignment: Alignment.topRight,
                child: widget.onSkip != null
                    ? TextButton(
                        onPressed: widget.onSkip,
                        child: const Text('Skip', style: TextStyle(color: Colors.white70)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: const Icon(Icons.public_rounded, size: 44, color: Colors.white),
                        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 20),
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to track your progress',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 40),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco('Email', Icons.email_rounded),
                          validator: (v) => (v?.contains('@') ?? false) ? null : 'Enter a valid email',
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco('Password', Icons.lock_rounded).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.white54),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v?.length ?? 0) >= 6 ? null : 'Min 6 characters',
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.error.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Sign In', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 20),

                        // Sign Up link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: TextStyle(color: Colors.white.withOpacity(0.7))),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignupPage()),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 600.ms),
                      ],
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

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.orange),
      );
}
