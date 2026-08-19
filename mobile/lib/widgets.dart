import 'package:flutter/material.dart';
import 'theme.dart';

void showMsg(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text(text),
      backgroundColor: error ? const Color(0xFFE11D48) : AppTheme.seed,
    ),
  );
}

class FadeSlide extends StatelessWidget {
  const FadeSlide({super.key, required this.child, this.delay = Duration.zero, this.index = 0});
  final Widget child;
  final Duration delay;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (index * 55)),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

class SoftCard extends StatefulWidget {
  const SoftCard({super.key, required this.child, this.onTap, this.padding});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  State<SoftCard> createState() => _SoftCardState();
}

class _SoftCardState extends State<SoftCard> {
  bool down = false;

  @override
  Widget build(BuildContext context) {
    final body = AnimatedScale(
      scale: down ? 0.98 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        padding: widget.padding ?? const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE4EEFB)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.seed.withValues(alpha: down ? 0.03 : 0.08),
              blurRadius: down ? 8 : 18,
              offset: Offset(0, down ? 3 : 8),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
    if (widget.onTap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => down = true),
      onTapCancel: () => setState(() => down = false),
      onTapUp: (_) => setState(() => down = false),
      onTap: widget.onTap,
      child: body,
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.label, required this.value, this.color, this.icon});
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.seed;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.withValues(alpha: 0.14), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: c),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w800, fontSize: 18)),
        ],
      ),
    );
  }
}

class EmptyBox extends StatelessWidget {
  const EmptyBox(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return FadeSlide(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppTheme.blueSoft, shape: BoxShape.circle),
              child: const Icon(Icons.inbox_outlined, color: AppTheme.seed, size: 32),
            ),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 22,
            decoration: BoxDecoration(color: AppTheme.seed, borderRadius: BorderRadius.circular(8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, t, child) {
          return Transform.scale(scale: t, child: child);
        },
        onEnd: () {},
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppTheme.seed.withValues(alpha: 0.18), blurRadius: 18)],
          ),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}
