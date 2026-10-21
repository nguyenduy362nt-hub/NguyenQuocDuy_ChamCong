import 'package:flutter/material.dart';

import '../../widgets.dart';

/// Khung nền chung cho Đăng nhập / Đăng ký / OTP.
class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool showBack;
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon = Icons.fingerprint,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 42),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [kPrimaryDark, kPrimary, Color(0xFF14B8A6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Column(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: showBack
                    ? IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white))
                    : const SizedBox(height: 48),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                child: Icon(icon, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          Transform.translate(
            offset: const Offset(0, -22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(padding: const EdgeInsets.all(20), child: child),
            ),
          ),
        ]),
      ),
    );
  }
}

class ErrorBox extends StatelessWidget {
  final String message;
  const ErrorBox(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: kDanger),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: kDanger))),
        ]),
      );
}
