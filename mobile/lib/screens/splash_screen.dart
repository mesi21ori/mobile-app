import 'package:flutter/material.dart';
import '../app_logo.dart';
import '../strings.dart';
import '../theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF4F8FF), Color(0xFFD6E8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 128),
              const SizedBox(height: 22),
              Text(
                S.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(S.appSubtitle, style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 36),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 12),
              const Text('እየጫነ ነው…', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
