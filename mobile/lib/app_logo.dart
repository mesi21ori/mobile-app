import 'package:flutter/material.dart';
import 'theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.elevated = true});
  final double size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: elevated
            ? [BoxShadow(color: AppTheme.seed.withValues(alpha: 0.2), blurRadius: size * 0.28, offset: Offset(0, size * 0.08))]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * 0.06),
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.church_rounded, color: AppTheme.seed, size: size * 0.48),
        ),
      ),
    );
  }
}
