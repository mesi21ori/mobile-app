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

  @override
  void dispose() {
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
      setState(() {
        data = res is Map ? Map<String, dynamic>.from(res) : {};
        last = term;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = (data['members'] as List?) ?? [];
    final assets = (data['assets'] as List?) ?? [];
    final loans = (data['vestmentLoans'] as List?) ?? [];
    final groups = (data['groups'] as List?) ?? [];
    final empty = last.length >= 2 && members.isEmpty && assets.isEmpty && loans.isEmpty && groups.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text(S.search)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'ተማሪ፣ ንብረት፣ ልብስ…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: ctrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          ctrl.clear();
                          setState(() {
                            data = {};
                            last = '';
                          });
                        },
                      ),
              ),
              onSubmitted: _run,
              onChanged: (_) => setState(() {}),
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
                    const SectionHeader(S.classes),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _run(ctrl.text),
        child: const Icon(Icons.search_rounded),
      ),
    );
  }
}
