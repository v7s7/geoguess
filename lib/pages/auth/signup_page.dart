import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  // Username availability state
  bool _checkingUsername = false;
  bool? _usernameAvailable; // null = not checked yet
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _usernameCtrl.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameCtrl.removeListener(_onUsernameChanged);
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    _debounce?.cancel();
    final text = _usernameCtrl.text.trim();
    if (text.length < 3) {
      setState(() { _usernameAvailable = null; _checkingUsername = false; });
      return;
    }
    setState(() { _checkingUsername = true; _usernameAvailable = null; });
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      final available = await UserService().isUsernameAvailable(text);
      if (mounted && _usernameCtrl.text.trim() == text) {
        setState(() { _checkingUsername = false; _usernameAvailable = available; });
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameAvailable == false) {
      setState(() => _error = 'This username is already taken.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final err = await context.read<AuthService>().signUp(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      username: _usernameCtrl.text,
    );

    if (mounted) setState(() { _loading = false; _error = err; });
    if (err == null && mounted) {
      Navigator.of(context)
        ..pop()
        ..pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientHero),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
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
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: const Icon(Icons.person_add_rounded, size: 42, color: Colors.white),
                        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 20),
                        const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 6),
                        Text(
                          'Join the GeoGuess community',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 36),

                        // Username
                        TextFormField(
                          controller: _usernameCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco('Username', Icons.badge_rounded).copyWith(
                            suffixIcon: _buildUsernameStatus(),
                          ),
                          validator: (v) {
                            if ((v?.trim().length ?? 0) < 3) return 'Min 3 characters';
                            if ((v?.trim().length ?? 0) > 20) return 'Max 20 characters';
                            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v?.trim() ?? '')) {
                              return 'Letters, numbers, underscores only';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                        // Username availability message
                        if (_usernameAvailable != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Row(
                              children: [
                                Icon(
                                  _usernameAvailable! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  size: 14,
                                  color: _usernameAvailable! ? Colors.greenAccent : Colors.redAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _usernameAvailable! ? 'Username available' : 'Username already taken',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _usernameAvailable! ? Colors.greenAccent : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 14),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco('Email', Icons.email_rounded),
                          validator: (v) => (v?.contains('@') ?? false) ? null : 'Enter a valid email',
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 14),

                        // Password
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco('Password (min 6 chars)', Icons.lock_rounded).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.white54),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v?.length ?? 0) >= 6 ? null : 'Min 6 characters',
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

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

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_loading || _checkingUsername) ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: (_loading || _checkingUsername)
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Text('Create Account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ),
                        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
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

  Widget? _buildUsernameStatus() {
    if (_checkingUsername) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
        ),
      );
    }
    if (_usernameAvailable == true) {
      return const Icon(Icons.check_circle_rounded, color: Colors.greenAccent);
    }
    if (_usernameAvailable == false) {
      return const Icon(Icons.cancel_rounded, color: Colors.redAccent);
    }
    return null;
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
        errorStyle: const TextStyle(color: Colors.orange),
      );
}
