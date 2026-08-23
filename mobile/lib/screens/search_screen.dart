import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth.dart';
import '../ethiopian_date.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ctrl = TextEditingController();
  Map data = {};
  bool loading = false;
  String last = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _run(String q) async {
    final term = q.trim();
    if (term.length < 2) {
      setState(() {
        data = {};
        last = term;
        loading = false;
      });
      return;
    }
    setState(() => loading = true);
    try {
      final res = await context.read<AuthState>().api.get('/search?q=${Uri.encodeComponent(term)}');
      if (!mounted) return;
      setState(() {
        data = res is Map ? Map<String, dynamic>.from(res) : {};
        last = term;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showMsg(context, e.toString(), error: true);
    }
  }

  void _onChanged(String v) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _run(v));
  }

  @override
  Widget build(BuildContext context) {
    final members = (data['members'] as List?) ?? [];
    final assets = (data['assets'] as List?) ?? [];
    final loans = (data['vestmentLoans'] as List?) ?? [];
    final groups = (data['groups'] as List?) ?? [];
    final events = (data['events'] as List?) ?? [];
    final empty = last.length >= 2 &&
        members.isEmpty &&
        assets.isEmpty &&
        loans.isEmpty &&
        groups.isEmpty &&
        events.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text(S.search)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'ተማሪ፣ በዓል፣ ንብረት…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: ctrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          ctrl.clear();
                          _debounce?.cancel();
                          setState(() {
                            data = {};
                            last = '';
                          });
                        },
                      ),
              ),
              onSubmitted: _run,
              onChanged: _onChanged,
            ),
          ),
          if (loading) const Expanded(child: LoadingView()),
          if (!loading)
            Expanded(
              child: ListView(
                children: [
                  if (last.length < 2)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'አንድ ቃል ወይም ስም መፈለግ ይเรጀም',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ),
                  if (empty) const EmptyBox('ውጤት አልተገኘም'),
                  if (events.isNotEmpty) ...[
                    SectionHeader(S.events),
                    ...events.map((e) => SoftCard(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.blueSoft,
                              child: Icon(Icons.event_rounded, color: AppTheme.seed),
                            ),
                            title: Text('${e['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('መውጫ: ${EthDate.format(e['issueDate'])}'),
                          ),
                        )),
                  ],
                  if (members.isNotEmpty) ...[
                    const SectionHeader('ተማሪዎች'),
                    ...members.map((m) {
                      final groupNames = ((m['groupMembers'] as List?) ?? [])
                          .map((gm) => gm['group']?['name'])
                          .whereType<String>()
                          .join(' · ');
                      return SoftCard(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.blueSoft,
                            child: Icon(Icons.person_rounded, color: AppTheme.seed),
                          ),
                          title: Text('${m['fullName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text([groupNames, m['phoneNumber'] ?? ''].where((s) => '$s'.isNotEmpty).join(' · ')),
                        ),
                      );
                    }),
                  ],
                  if (assets.isNotEmpty) ...[
                    const SectionHeader('ንብረት'),
                    ...assets.map((a) => SoftCard(
                          child: ListTile(
                            title: Text('${a['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('${S.available}: ${a['availableQuantity']} · ${a['type'] == 'CONSUMABLE' ? 'አላቂ' : 'ቋሚ'}'),
                          ),
                        )),
                  ],
                  if (loans.isNotEmpty) ...[
                    const SectionHeader('ልብሰባት'),
                    ...loans.map((l) => SoftCard(
                          child: ListTile(
                            title: Text('${l['member']?['fullName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(
                              '${l['vestment']?['name'] ?? ''} · ${l['event']?['name'] ?? ''} · ${EthDate.format(l['issueDate'])}',
                            ),
                            trailing: Text(
                              l['isReturned'] == true ? 'ተመልሷል' : 'ያልተመለሰ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: l['isReturned'] == true ? AppTheme.seed : AppTheme.muted,
                              ),
                            ),
                          ),
                        )),
                  ],
                  if (groups.isNotEmpty) ...[
                    SectionHeader(S.classes),
                    ...groups.map((g) => SoftCard(
                          child: ListTile(
                            title: Text('${g['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        )),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
