import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/purchase_service.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  PurchaseService? _ps;

  @override
  void initState() {
    super.initState();
    // Listen for purchase success to auto-close
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ps = context.read<PurchaseService>();
      _ps!.addListener(_onPurchaseUpdate);
    });
  }

  void _onPurchaseUpdate() {
    final ps = _ps;
    if (ps == null) return;
    if (ps.purchaseSuccess && mounted) {
      ps.clearPurchaseSuccess();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber),
              SizedBox(width: 8),
              Text('Welcome to Premium! All flags unlocked! 🌍'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    if (ps.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ps.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      ps.clearError();
    }
  }

  @override
  void dispose() {
    _ps?.removeListener(_onPurchaseUpdate);
    super.dispose();
  }

  static const _benefits = [
    (Icons.public, 'All 250+ World Flags', 'Every country on Earth — unlocked'),
    (Icons.all_inclusive, 'Unlimited Questions', 'Play full 254-flag marathons'),
    (Icons.bolt, 'World Master Mode', 'Exclusive challenge for true experts'),
    (Icons.star, 'Support the Dev', 'Help keep the app ad-free & growing'),
  ];

  @override
  Widget build(BuildContext context) {
    final ps = context.watch<PurchaseService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Crown Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            Colors.amber.shade300,
                            Colors.orange.shade700,
                          ]),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.workspace_premium, size: 56, color: Colors.white),
                      )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.elasticOut)
                          .fadeIn(duration: 400.ms),

                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'GeoGuess',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontSize: 42,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 8),
                      Text(
                        'Master every flag in the world',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 36),

                      // Benefits list
                      ...List.generate(_benefits.length, (i) {
                        final b = _benefits[i];
                        return _BenefitRow(icon: b.$1, title: b.$2, subtitle: b.$3)
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 500 + i * 100))
                            .slideX(begin: -0.2, end: 0);
                      }),

                      const SizedBox(height: 32),

                      // Price badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.amber.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.diamond, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'One-Time Purchase — ${ps.priceString}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 900.ms),

                      const SizedBox(height: 8),
                      Text(
                        'No subscription. Pay once, own forever.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ).animate().fadeIn(delay: 1000.ms),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bottom CTA
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Buy button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: ps.isLoading ? null : () => ps.buyPremium(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: Colors.amber.withOpacity(0.5),
                        ),
                        child: ps.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.workspace_premium, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Unlock All Flags — ${ps.priceString}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 12),

                    // Restore button
                    TextButton(
                      onPressed: ps.isLoading ? null : () => ps.restorePurchases(),
                      child: Text(
                        'Restore Purchase',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Icon(icon, color: Colors.amber, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 22),
        ],
      ),
    );
  }
}
