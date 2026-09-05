import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';

class GuestEntryPage extends StatelessWidget {
  const GuestEntryPage({
    super.key,
    required this.onGuestContinue,
    required this.onAuth,
  });
  final VoidCallback onGuestContinue;
  final VoidCallback onAuth;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 54,
                color: AppColors.brandAction,
              ),
              const SizedBox(height: 22),
              const Text(
                'Nasıl devam edelim?',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hesap açmadan listeni bu cihazda tutabilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 16),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onGuestContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandAction,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Misafir olarak devam et'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onAuth,
                  child: const Text('Giriş yap veya kayıt ol'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
