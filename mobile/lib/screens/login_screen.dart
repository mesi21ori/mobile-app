import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_logo.dart';
import '../auth.dart';
import '../config.dart';
import '../ethiopian_date.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final userCtrl = TextEditingController(text: 'admin');
  final passCtrl = TextEditingController();
  final urlCtrl = TextEditingController(text: AppConfig.defaultBaseUrl());
  bool busy = false;
  bool showUrl = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = _pulse.value;
          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF4F8FF), Color(0xFFD6E8FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                top: -80 + (t * 24),
                right: -40,
                child: _blob(220, AppTheme.blue.withValues(alpha: 0.22)),
              ),
              Positioned(
                bottom: -60 - (t * 18),
                left: -50,
                child: _blob(180, AppTheme.seed.withValues(alpha: 0.16)),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                          FadeSlide(
                            child: const AppLogo(size: 104),
                          ),
                          const SizedBox(height: 18),
                          FadeSlide(
                            index: 1,
                            child: Text(
                              S.appName,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FadeSlide(
                            index: 2,
                            child: Text(S.appSubtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 15)),
                          ),
                          const SizedBox(height: 8),
                          FadeSlide(
                            index: 2,
                            child: Text(
                              'ዛሬ · ${EthDate.now().label}',
                              style: const TextStyle(color: AppTheme.seed, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeSlide(
                            index: 3,
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(color: AppTheme.seed.withValues(alpha: 0.08), blurRadius: 28, offset: const Offset(0, 12)),
                                ],
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: userCtrl,
                                    decoration: const InputDecoration(
                                      labelText: S.username,
                                      prefixIcon: Icon(Icons.person_outline_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: passCtrl,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: S.password,
                                      prefixIcon: Icon(Icons.lock_outline_rounded),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() => showUrl = !showUrl),
                                    child: const Text(S.apiUrl),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOutCubic,
                                    child: showUrl
                                        ? Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: TextField(
                                              controller: urlCtrl,
                                              decoration: const InputDecoration(labelText: S.apiUrl),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  FilledButton(
                                    onPressed: busy ? null : _submit,
                                    child: busy
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text(S.login),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Future<void> _submit() async {
    setState(() => busy = true);
    try {
      await context.read<AuthState>().login(userCtrl.text, passCtrl.text, apiUrl: urlCtrl.text);
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
