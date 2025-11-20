import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import 'login_page.dart';

const _backgroundColor = Color(0xFF21545F);
const _haloColor = Color(0xFFF8F9FD);
const _supplierGradient = [Color(0xFFA7E1D5), Color(0xFF83D0C2)];

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRoleTap(BuildContext context, String roleLabel) {
    final auth = context.read<AuthProvider>();
    auth.chooseRole(roleLabel);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          const _HeroHalo(
            alignment: Alignment.topLeft,
            offset: Offset(-120, -80),
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(240),
              bottomLeft: Radius.circular(240),
            ),
          ),
          const _HeroHalo(
            alignment: Alignment.bottomRight,
            offset: Offset(100, 120),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(240)),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome to SCP',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please select your role',
                      style: TextStyle(color: Color(0xFFEAF2F2), fontSize: 16),
                    ),
                    const SizedBox(height: 48),
                    _RoleButton(
                      label: 'I am a Consumer',
                      backgroundColor: Colors.white,
                      foregroundColor: _backgroundColor,
                      onTap: () => _handleRoleTap(context, 'consumer'),
                    ),
                    const SizedBox(height: 20),
                    _RoleButton(
                      label: 'I am a Supplier',
                      gradient: _supplierGradient,
                      foregroundColor: _backgroundColor,
                      onTap: () => _handleRoleTap(context, 'supplier'),
                    ),
                    const SizedBox(height: 24),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        if (auth.selectedRole == null) return const SizedBox();
                        final roleLabel = auth.selectedRole == 'supplier'
                            ? 'Supplier'
                            : 'Consumer';
                        return Text(
                          'Continue as $roleLabel',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.foregroundColor,
    required this.onTap,
    this.backgroundColor,
    this.gradient,
  }) : assert(
         backgroundColor != null || gradient != null,
         'Either backgroundColor or gradient must be provided',
       );

  final String label;
  final Color foregroundColor;
  final Color? backgroundColor;
  final List<Color>? gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 80),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );

    if (gradient == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: button,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: button,
    );
  }
}

class _HeroHalo extends StatelessWidget {
  const _HeroHalo({
    required this.alignment,
    required this.offset,
    required this.borderRadius,
  });

  final Alignment alignment;
  final Offset offset;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            color: _haloColor,
            borderRadius: borderRadius,
          ),
        ),
      ),
    );
  }
}
