import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';
import '../ethiopian_date.dart';
import '../strings.dart';
import '../theme.dart';
import '../reports.dart';
import '../widgets.dart';

Future<List<int>?> pickClothes(
  BuildContext context,
  List vestments, {
  String title = S.issue,
}) async {
  final selected = <int>{};
  final search = TextEditingController();
  int? idOf(dynamic v) => jsonInt(v is Map ? v['id'] : v);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final q = search.text.trim().toLowerCase();
        final filtered = vestments.where((v) {
          if (q.isEmpty) return true;
          return '${v['name'] ?? ''}'.toLowerCase().contains(q);
        }).toList();
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 360,
            height: 420,
            child: Column(
              children: [
                TextField(
                  controller: search,
                  decoration: const InputDecoration(labelText: S.search, prefixIcon: Icon(Icons.search_rounded)),
                  onChanged: (_) => setS(() {}),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      ...filtered.map((v) {
                        final id = idOf(v);
                        if (id == null) return const SizedBox.shrink();
                        final available = (v['availableQuantity'] as num?)?.toInt() ?? 0;
                        return CheckboxListTile(
                          value: selected.contains(id),
                          title: Text('${v['name'] ?? ''}'),
                          subtitle: Text('${S.available}: $available'),
                          onChanged: available < 1
                              ? null
                              : (val) => setS(() {
                                    if (val == true) {
                                      selected.add(id);
                                    } else {
                                      selected.remove(id);
                                    }
                                  }),
                        );
                      }),
                    ],
                  ),
                ),
                Text(
                  'ተመርጧል: ${selected.length} የተለያዩ ልብሶች',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.seed),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
            FilledButton(
              onPressed: selected.isEmpty ? null : () => Navigator.pop(ctx, true),
              child: const Text(S.save),
            ),
          ],
        );
      },
    ),
  );
  if (ok != true || selected.isEmpty) return null;
  return selected.toList();
}

class VestmentsScreen extends StatefulWidget {
  const VestmentsScreen({super.key, this.section = VestmentsSection.classes});
  final VestmentsSection section;
  @override
  State<VestmentsScreen> createState() => _VestmentsScreenState();
}

enum VestmentsSection { classes, events, clothes, dirty }

class _VestmentsScreenState extends State<VestmentsScreen> {
  List vestments = [];
  List classes = [];
  List events = [];
  List unreturned = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _studentCountFrom(dynamic g) => ((g['members'] as List?) ?? []).length;

  Future<void> _load() async {
    final auth = context.read<AuthState>();
    final api = auth.api;
    try {
      if (auth.isClassLeader) {
        final results = await Future.wait([
          api.get('/groups'),
          api.get('/events'),
        ]);
        setState(() {
          classes = results[0];
          events = results[1];
          vestments = [];
          unreturned = [];
          loading = false;
        });
        return;
      }
      final results = await Future.wait([
        api.get('/vestments'),
        api.get('/groups'),
        api.get('/events'),
        api.get('/vestment-loans?unreturned=true'),
      ]);
      setState(() {
        vestments = results[0];
        classes = results[1];
        events = results[2];
        unreturned = results[3];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final admin = auth.isAdmin;
    final canManageClass = auth.canManageClass;
    final canAddClass = admin || (auth.isClassLeader && auth.groupId == null);
    if (loading) return const LoadingView();
    final section = widget.section;
    if (section == VestmentsSection.dirty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: ReportDoc.button(_exportClothes),
          ),
          Expanded(
            child: UnreturnedClothesPanel(loans: unreturned, admin: admin, onChanged: _load),
          ),
        ],
      );
    }
    final body = RefreshIndicator(
      color: AppTheme.seed,
      onRefresh: _load,
      child: ListView(
        children: [
          if (!auth.isClassLeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ReportDoc.button(_exportClothes),
            ),
          if (section == VestmentsSection.classes) ...[
            if (canAddClass)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: FilledButton.icon(
                  onPressed: _addClass,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(auth.isClassLeader ? 'መደብ ፍጠር' : S.addClass),
                ),
              ),
            const SectionHeader(S.classes),
            if (classes.isEmpty)
              EmptyBox(auth.isClassLeader ? 'መጀመሪያ መደብዎን ይፍጠሩ' : 'መጀመሪያ ምድብ ይፍጠሩ፤ ከዚያ አባላትን ያክሉ'),
            if (auth.isClassLeader && classes.length == 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${classes.first['name'] ?? ''} · ${_studentCountFrom(classes.first)} ተማሪ',
                  style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
                ),
              ),
            ...classes.asMap().entries.map((entry) {
              final g = entry.value;
              final count = ((g['members'] as List?) ?? []).length;
              return FadeSlide(
                index: entry.key,
                child: SoftCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ClassDetailPage(group: g)),
                  ).then((_) => _load()),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.blueSoft,
                      child: Icon(Icons.groups_rounded, color: AppTheme.seed),
                    ),
                    title: Text(g['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('$count አባላት'),
                    trailing: canManageClass
                        ? PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _editClass(g);
                              if (v == 'delete') _deleteClass(g);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text(S.edit)),
                              PopupMenuItem(value: 'delete', child: Text(S.remove)),
                            ],
                          )
                        : const Icon(Icons.chevron_right_rounded, color: AppTheme.seed),
                  ),
                ),
              );
            }),
          ],
          if (section == VestmentsSection.events) ...[
            if (auth.canCreateEvent)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: FilledButton.icon(
                  onPressed: _addEvent,
                  icon: const Icon(Icons.event_rounded),
                  label: const Text('በዓል ፍጠር'),
                ),
              ),
            SectionHeader(S.events),
            if (events.isEmpty)
              EmptyBox(
                auth.isClassLeader
                    ? 'በዓል ፍጠር · ከዚያ ተማሪዎችን ለበዓሉ ይመድቡ'
                    : 'በዓል ፍጠር · መደብ አስተዳዳሪዎች ተሳታፊዎችን ይመድቡ',
              ),
            ...events.map((e) => SoftCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EventIssuePage(event: e)),
                  ).then((_) => _load()),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.blueSoft,
                      child: Icon(Icons.event_rounded, color: AppTheme.seed),
                    ),
                    title: Text(e['name'], style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      auth.isClassLeader
                          ? 'መውጫ: ${EthDate.format(e['issueDate'])} · ${S.registerParticipants}'
                          : 'መውጫ: ${EthDate.format(e['issueDate'])}\nመመለሻ: ${EthDate.format(e['dueDate'])} · ልብስ አድል',
                    ),
                    isThreeLine: !auth.isClassLeader,
                    trailing: admin
                        ? PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _editEvent(e);
                              if (v == 'delete') _deleteItem('/events/${jsonInt(e['id'])}', e['name']);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text(S.edit)),
                              PopupMenuItem(value: 'delete', child: Text(S.remove)),
                            ],
                          )
                        : const Icon(Icons.chevron_right_rounded, color: AppTheme.seed),
                  ),
                )),
          ],
          if (section == VestmentsSection.clothes) ...[
            SectionHeader(
              S.vestments,
              action: admin ? TextButton.icon(onPressed: _addVestment, icon: const Icon(Icons.add_rounded), label: const Text(S.add)) : null,
            ),
            if (vestments.isEmpty) const EmptyBox('ልብስ ይመዝግቡ'),
            ...vestments.map((v) => SoftCard(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.blueSoft,
                      child: Icon(Icons.checkroom_rounded, color: AppTheme.seed),
                    ),
                    title: Text('${v['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${S.available}: ${v['availableQuantity']} · ${S.issued}: ${v['issuedQuantity']}'),
                    trailing: admin
                        ? PopupMenuButton<String>(
                            onSelected: (sel) {
                              if (sel == 'edit') _editVestment(v);
                              if (sel == 'delete') _deleteItem('/vestments/${jsonInt(v['id'])}', v['name']);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text(S.edit)),
                              PopupMenuItem(value: 'delete', child: Text(S.remove)),
                            ],
                          )
                        : null,
                  ),
                )),
          ],
          const SizedBox(height: 88),
        ],
      ),
    );
    if (section == VestmentsSection.classes && auth.isClassLeader && classes.isNotEmpty) {
      return Stack(
        children: [
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _addStudentToGroup(classes.first),
              icon: const Icon(Icons.person_add_alt),
              label: const Text(S.addStudent),
            ),
          ),
        ],
      );
    }
    return body;
  }

  Future<void> _addStudentToGroup(Map group) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.addStudent),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'ሙሉ ስም')),
            const SizedBox(height: 8),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'ስልክ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await context.read<AuthState>().api.post('/members', {
        'fullName': name.text.trim(),
        'phoneNumber': phone.text.trim(),
        'groupId': group['id'],
      });
      _load();
    }
  }

  Future<void> _addClass() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.addClass),
        content: TextField(controller: name, decoration: const InputDecoration(labelText: 'የምድብ ስም')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      final created = await context.read<AuthState>().api.post('/groups', {'name': name.text.trim()});
      await context.read<AuthState>().refreshUser();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClassDetailPage(group: created)),
      );
      _load();
    }
  }

  Future<void> _addVestment() async {
    final name = TextEditingController();
    final qty = TextEditingController(text: '10');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ልብስ መዝግብ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'የልብስ ስም')),
            const SizedBox(height: 8),
            TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ብዛት')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
        ],
      ),
    );
    if (ok == true) {
      await context.read<AuthState>().api.post('/vestments', {
        'name': name.text,
        'totalQuantity': int.parse(qty.text),
      });
      _load();
    }
  }

  Future<void> _addEvent() async {
    final auth = context.read<AuthState>();
    if (auth.isClassLeader && auth.groupId == null) {
      showMsg(context, 'መጀመሪያ መደብዎን ይፍጠሩ', error: true);
      return;
    }
    final name = TextEditingController();
    DateTime issue = DateTime.now();
    DateTime due = DateTime.now().add(const Duration(days: 7));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('በዓል ፍጠር'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'የበዓል ስም')),
              ListTile(
                leading: const Icon(Icons.calendar_month_rounded, color: AppTheme.seed),
                title: Text('መውጫ: ${EthDate.fromGregorian(issue).label}'),
                onTap: () async {
                  final d = await pickEthiopianDate(ctx, initial: issue);
                  if (d != null) setS(() => issue = d);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_available_rounded, color: AppTheme.seed),
                title: Text('መመለሻ: ${EthDate.fromGregorian(due).label}'),
                onTap: () async {
                  final d = await pickEthiopianDate(ctx, initial: due);
                  if (d != null) setS(() => due = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
          ],
        ),
      ),
    );
    if (ok == true) {
      await context.read<AuthState>().api.post('/events', {
        'name': name.text,
        'issueDate': issue.toIso8601String(),
        'dueDate': due.toIso8601String(),
      });
      _load();
    }
  }

  Future<void> _editClass(Map g) async {
    final name = TextEditingController(text: g['name']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.edit),
        content: TextField(controller: name, decoration: const InputDecoration(labelText: 'የምድብ ስም')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      try {
        await context.read<AuthState>().api.patch('/groups/${jsonInt(g['id'])}', {'name': name.text.trim()});
        _load();
      } catch (e) {
        if (mounted) showMsg(context, e.toString(), error: true);
      }
    }
  }

  Future<void> _deleteClass(Map g) async {
    await _deleteItem('/groups/${jsonInt(g['id'])}', g['name']);
  }

  Future<void> _editVestment(Map v) async {
    final name = TextEditingController(text: v['name']?.toString() ?? '');
    final qty = TextEditingController(text: '${v['totalQuantity'] ?? v['availableQuantity'] ?? 0}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'የልብስ ስም')),
            const SizedBox(height: 8),
            TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ብዛት')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      try {
        await context.read<AuthState>().api.patch('/vestments/${jsonInt(v['id'])}', {
          'name': name.text.trim(),
          'totalQuantity': int.tryParse(qty.text) ?? 0,
        });
        _load();
      } catch (e) {
        if (mounted) showMsg(context, e.toString(), error: true);
      }
    }
  }

  Future<void> _editEvent(Map e) async {
    final name = TextEditingController(text: e['name']?.toString() ?? '');
    DateTime issue = DateTime.tryParse('${e['issueDate']}') ?? DateTime.now();
    DateTime due = DateTime.tryParse('${e['dueDate']}') ?? DateTime.now().add(const Duration(days: 7));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text(S.edit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'የበዓል ስም')),
              ListTile(
                leading: const Icon(Icons.calendar_month_rounded, color: AppTheme.seed),
                title: Text('መውጫ: ${EthDate.fromGregorian(issue).label}'),
                onTap: () async {
                  final d = await pickEthiopianDate(ctx, initial: issue);
                  if (d != null) setS(() => issue = d);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_available_rounded, color: AppTheme.seed),
                title: Text('መመለሻ: ${EthDate.fromGregorian(due).label}'),
                onTap: () async {
                  final d = await pickEthiopianDate(ctx, initial: due);
                  if (d != null) setS(() => due = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
          ],
        ),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      try {
        await context.read<AuthState>().api.patch('/events/${jsonInt(e['id'])}', {
          'name': name.text.trim(),
          'issueDate': issue.toIso8601String(),
          'dueDate': due.toIso8601String(),
        });
        _load();
      } catch (err) {
        if (mounted) showMsg(context, err.toString(), error: true);
      }
    }
  }

  Future<void> _deleteItem(String path, dynamic label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.remove),
        content: Text('${label ?? ''} ይወገድ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.remove)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<AuthState>().api.delete(path);
      _load();
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }

  Future<void> _exportClothes() async {
    final kind = await ReportDoc.pickKind(
      context,
      title: 'የልብስ ሪፖርት',
      kinds: const [
        ReportKind('stock', 'በመደብር ያለ ልብስ'),
        ReportKind('by-class', 'በምድብ የተወሰደ ልብስ'),
        ReportKind('by-cloth', 'በልብስ ዓይነት የተወሰደ'),
        ReportKind('unreturned', 'ያልመለሱ ተማሪዎች'),
        ReportKind('dirty', 'ቆሽሏል ያልተመለሰ'),
        ReportKind('month', 'በዚህ ወር የተወሰደ'),
      ],
    );
    if (kind == null) return;
    await ReportDoc.run(context, () async {
      if (kind == 'stock') {
        await ReportDoc.share(
          title: 'በመደብር ያለ ልብስ',
          headers: const ['ልብስ', 'ያለው', 'የወጣ'],
          rows: vestments
              .map((v) => ['${v['name'] ?? ''}', '${v['availableQuantity'] ?? ''}', '${v['issuedQuantity'] ?? ''}'])
              .toList(),
        );
        return;
      }
      final loans = await context.read<AuthState>().api.get('/vestment-loans') as List;
      Iterable list = loans;
      var title = 'የተወሰደ ልብስ';
      if (kind == 'unreturned') {
        list = loans.where((l) => l['isReturned'] != true);
        title = 'ያልመለሱ ተማሪዎች';
      } else if (kind == 'dirty') {
        list = loans.where((l) => l['isDirty'] == true && l['isReturned'] != true);
        title = 'ቆሽሏል ያልተመለሰ ልብስ';
      } else if (kind == 'month') {
        list = loans.where((l) => EthDate.inThisMonth(l['issueDate'] ?? l['issuedDate']));
        title = 'በዚህ ወር የተወሰደ ልብስ (${EthDate.now().monthName} ${EthDate.now().year})';
      } else if (kind == 'by-class') {
        final sums = <String, Map<String, int>>{};
        for (final l in loans) {
          final cls = '${l['group']?['name'] ?? 'ምድብ የለም'}';
          final cloth = '${l['vestment']?['name'] ?? ''}';
          sums.putIfAbsent(cls, () => {});
          sums[cls]![cloth] = (sums[cls]![cloth] ?? 0) + 1;
        }
        final rows = <List<String>>[];
        for (final cls in sums.keys.toList()..sort()) {
          for (final e in sums[cls]!.entries) {
            rows.add([cls, e.key, '${e.value}']);
          }
        }
        await ReportDoc.share(title: 'በምድብ የተወሰደ ልብስ', headers: const ['ምድብ', 'ልብስ', 'ብዛት'], rows: rows);
        return;
      } else if (kind == 'by-cloth') {
        final sums = <String, int>{};
        for (final l in loans) {
          final cloth = '${l['vestment']?['name'] ?? ''}';
          sums[cloth] = (sums[cloth] ?? 0) + 1;
        }
        await ReportDoc.share(
          title: 'በልብስ ዓይነት የተወሰደ',
          headers: const ['ልብስ', 'ብዛት'],
          rows: (sums.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
              .map((e) => [e.key, '${e.value}'])
              .toList(),
        );
        return;
      }
      await ReportDoc.share(
        title: title,
        headers: const ['ተማሪ', 'ምድብ', 'ልብስ', 'በዓል', 'ሁኔታ'],
        rows: list
            .map((l) => [
                  '${l['member']?['fullName'] ?? ''}',
                  '${l['group']?['name'] ?? ''}',
                  '${l['vestment']?['name'] ?? ''}',
                  '${l['event']?['name'] ?? ''}',
                  l['isReturned'] == true ? 'ተመልሷል' : (l['isDirty'] == true ? 'ቆሽሏል' : 'ያልተመለሰ'),
                ])
            .toList(),
      );
    });
  }
}

class ClassDetailPage extends StatefulWidget {
  const ClassDetailPage({super.key, required this.group});
  final Map group;
  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  Map? group;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    group = widget.group;
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<AuthState>().api.get('/groups') as List;
    setState(() {
      group = list.firstWhere((g) => g['id'] == widget.group['id'], orElse: () => widget.group);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final canManageClass = auth.canManageClass;
    final members = ((group?['members'] as List?) ?? [])
        .map((gm) => gm is Map ? (gm['member'] ?? gm) : null)
        .whereType<Map>()
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(group?['name'] ?? S.classes)),
      floatingActionButton: canManageClass
          ? FloatingActionButton.extended(
              onPressed: _addMember,
              icon: const Icon(Icons.person_add_alt),
              label: const Text(S.add),
            )
          : null,
      body: loading
          ? const LoadingView()
          : members.isEmpty
              ? EmptyBox('ተማሪ የለም · ${S.addStudent} ይጫኑ')
              : ListView.builder(
                          itemCount: members.length,
                          itemBuilder: (_, i) {
                            final m = members[i];
                            return FadeSlide(
                              index: i,
                              child: SoftCard(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppTheme.blueSoft,
                                    child: Icon(Icons.person_rounded, color: AppTheme.seed),
                                  ),
                                  title: Text(m['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  subtitle: Text(m['phoneNumber'] ?? ''),
                                  trailing: canManageClass
                                      ? PopupMenuButton<String>(
                                          onSelected: (v) {
                                            if (v == 'edit') _editMember(m);
                                            if (v == 'delete') _deleteMember(m);
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(value: 'edit', child: Text(S.edit)),
                                            PopupMenuItem(value: 'delete', child: Text(S.remove)),
                                          ],
                                        )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
    );
  }

  Future<void> _addMember() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.addStudent),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'ሙሉ ስም')),
            const SizedBox(height: 8),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'ስልክ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await context.read<AuthState>().api.post('/members', {
        'fullName': name.text.trim(),
        'phoneNumber': phone.text.trim(),
        'groupId': widget.group['id'],
      });
      _load();
    }
  }

  Future<void> _editMember(Map m) async {
    final name = TextEditingController(text: m['fullName']?.toString() ?? '');
    final phone = TextEditingController(text: m['phoneNumber']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'ሙሉ ስም')),
            const SizedBox(height: 8),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'ስልክ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      try {
        await context.read<AuthState>().api.patch('/members/${jsonInt(m['id'])}', {
          'fullName': name.text.trim(),
          'phoneNumber': phone.text.trim(),
        });
        _load();
      } catch (e) {
        if (mounted) showMsg(context, e.toString(), error: true);
      }
    }
  }

  Future<void> _deleteMember(Map m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.remove),
        content: Text('${m['fullName'] ?? ''} ይወገድ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.remove)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<AuthState>().api.delete('/members/${jsonInt(m['id'])}');
      _load();
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }
}

class EventIssuePage extends StatefulWidget {
  const EventIssuePage({super.key, required this.event});
  final Map event;
  @override
  State<EventIssuePage> createState() => _EventIssuePageState();
}

class _EventIssuePageState extends State<EventIssuePage> {
  List participantGroups = [];
  List vestments = [];
  List classMembers = [];
  Map? myGroup;
  final selected = <int>{};
  bool loading = true;
  bool saving = false;
  final studentSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    studentSearch.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthState>();
    final api = auth.api;
    final eventId = jsonInt(widget.event['id']);
    if (auth.isClassLeader) {
      final res = await Future.wait([
        api.get('/groups'),
        api.get('/events/$eventId/participants'),
      ]);
      final groups = (res[0] as List?) ?? [];
      final parts = (res[1] as List?) ?? [];
      final group = groups.isNotEmpty ? Map<String, dynamic>.from(groups.first as Map) : null;
      final members = group == null
          ? <Map>[]
          : ((group['members'] as List?) ?? [])
              .map((gm) => gm is Map ? Map<String, dynamic>.from((gm['member'] ?? gm) as Map) : null)
              .whereType<Map>()
              .toList();
      final registered = parts.isNotEmpty
          ? ((parts.first as Map)['members'] as List?)?.map((m) => jsonInt(m['id'])).whereType<int>().toSet() ?? {}
          : <int>{};
      setState(() {
        myGroup = group;
        classMembers = members;
        participantGroups = parts;
        selected
          ..clear()
          ..addAll(registered);
        loading = false;
      });
      return;
    }
    final res = await Future.wait([
      api.get('/events/$eventId/participants'),
      api.get('/vestments'),
    ]);
    setState(() {
      participantGroups = (res[0] as List?) ?? [];
      vestments = (res[1] as List?) ?? [];
      loading = false;
    });
  }

  Future<void> _saveParticipants() async {
    final auth = context.read<AuthState>();
    if (auth.groupId == null) {
      showMsg(context, 'መጀመሪያ መደብ ይፍጠሩ', error: true);
      return;
    }
    setState(() => saving = true);
    try {
      await auth.api.put('/events/${jsonInt(widget.event['id'])}/participants', {
        'memberIds': selected.toList(),
      });
      if (mounted) {
        showMsg(context, S.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (loading) {
      return Scaffold(appBar: AppBar(title: Text(widget.event['name'] ?? '')), body: const LoadingView());
    }
    if (auth.isClassLeader) return _classLeaderBody(auth);
    return _adminBody();
  }

  Widget _classLeaderBody(AuthState auth) {
    if (auth.groupId == null || myGroup == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.event['name'] ?? '')),
        body: const EmptyBox('መጀመሪያ መደብ ይፍጠሩ · ከዚያ ተማሪዎችን ያክሉ'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.event['name'] ?? '')),
      floatingActionButton: classMembers.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: saving ? null : _saveParticipants,
              icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.how_to_reg_rounded),
              label: const Text(S.registerParticipants),
            ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '${myGroup?['name'] ?? ''} · ለበዓሉ የሚሳተፉ ተማሪዎችን ይምረጡ',
              style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
            ),
          ),
          if (classMembers.isEmpty) const EmptyBox('ተማሪ የለም · በመደብ ገጽ ተማሪ ያክሉ'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: studentSearch,
              decoration: const InputDecoration(labelText: S.search, prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (_) => setState(() {}),
            ),
          ),
          ...classMembers.where((m) {
            final q = studentSearch.text.trim().toLowerCase();
            if (q.isEmpty) return true;
            return '${m['fullName'] ?? ''}'.toLowerCase().contains(q);
          }).map((m) {
            final id = jsonInt(m['id']);
            if (id == null) return const SizedBox.shrink();
            final on = selected.contains(id);
            return SoftCard(
              child: CheckboxListTile(
                value: on,
                title: Text(m['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(m['phoneNumber']?.toString() ?? ''),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    selected.add(id);
                  } else {
                    selected.remove(id);
                  }
                }),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _adminBody() {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event['name'] ?? '')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'በመደብ የተመዘገቡ ተሳታፊዎች · ልብስ ይስጡ',
              style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
            ),
          ),
          if (participantGroups.isEmpty) const EmptyBox('እስካሁን ምንም መደብ ተሳታፊ አልመዘገበም · መደብ አስተዳዳሪዎች ይመድቡ'),
          ...participantGroups.map((g) {
            final group = Map<String, dynamic>.from(g['group'] as Map? ?? {});
            final members = ((g['members'] as List?) ?? []).map((m) => Map<String, dynamic>.from(m as Map)).toList();
            return SoftCard(
              onTap: members.isEmpty
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassIssuePage(
                            event: widget.event,
                            group: group,
                            vestments: vestments,
                            participants: members,
                          ),
                        ),
                      ).then((_) => _load()),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.blueSoft,
                  child: Icon(Icons.groups_rounded, color: AppTheme.seed),
                ),
                title: Text(group['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${members.length} ተሳታፊ ተማሪዎች'),
                trailing: members.isEmpty
                    ? null
                    : const Icon(Icons.chevron_right_rounded, color: AppTheme.seed),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class ClassIssuePage extends StatelessWidget {
  const ClassIssuePage({
    super.key,
    required this.event,
    required this.group,
    required this.vestments,
    required this.participants,
  });
  final Map event;
  final Map group;
  final List vestments;
  final List<Map<String, dynamic>> participants;

  @override
  Widget build(BuildContext context) {
    final canManageVestments = context.watch<AuthState>().canManageVestments;
    return Scaffold(
      appBar: AppBar(title: Text(group['name'] ?? '')),
      floatingActionButton: canManageVestments && participants.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _issue(context, bulk: true),
              icon: const Icon(Icons.groups_3_rounded),
              label: const Text(S.bulkIssue),
            )
          : null,
      body: participants.isEmpty
          ? const EmptyBox('ለዚህ በዓል ተሳታፊ ተማሪ የለም')
          : ListView(
              children: [
                const SectionHeader('ተሳታፊ ተማሪዎች · ልብስ ይስጡ'),
                ...participants.map((m) => SoftCard(
                      onTap: canManageVestments
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MemberLoansPage(
                                    event: event,
                                    group: group,
                                    member: m,
                                    vestments: vestments,
                                  ),
                                ),
                              )
                          : null,
                      child: ListTile(
                        title: Text(m['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text(S.issueClothes),
                        trailing: canManageVestments
                            ? const Icon(Icons.chevron_right_rounded, color: AppTheme.seed)
                            : null,
                      ),
                    )),
              ],
            ),
    );
  }

  Future<void> _issue(BuildContext context, {required bool bulk}) async {
    final ids = await pickClothes(context, vestments, title: S.bulkIssue);
    if (ids == null || ids.isEmpty) return;
    try {
      await context.read<AuthState>().api.post('/vestment-loans/issue-bulk', {
        'eventId': jsonInt(event['id']),
        'groupId': jsonInt(group['id']),
        'vestmentIds': ids,
      });
      if (context.mounted) showMsg(context, S.success);
    } catch (e) {
      if (context.mounted) showMsg(context, e.toString(), error: true);
    }
  }
}

class MemberLoansPage extends StatefulWidget {
  const MemberLoansPage({
    super.key,
    required this.event,
    required this.group,
    required this.member,
    required this.vestments,
  });
  final Map event, group, member;
  final List vestments;
  @override
  State<MemberLoansPage> createState() => _MemberLoansPageState();
}

class _MemberLoansPageState extends State<MemberLoansPage> {
  List loans = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await context.read<AuthState>().api.get(
          '/vestment-loans?eventId=${jsonInt(widget.event['id'])}&groupId=${jsonInt(widget.group['id'])}&memberId=${jsonInt(widget.member['id'])}',
        );
    setState(() {
      loans = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canManageVestments = context.watch<AuthState>().canManageVestments;
    return Scaffold(
      appBar: AppBar(title: Text(widget.member['fullName'] ?? '')),
      floatingActionButton: canManageVestments
          ? FloatingActionButton.extended(
              onPressed: _issueOne,
              label: const Text(S.issue),
              icon: const Icon(Icons.checkroom),
            )
          : null,
      body: loading
          ? const LoadingView()
          : loans.isEmpty
              ? const EmptyBox('የተወሰደ ልብስ የለም · ከታች ልብስ አድል ይጫኑ')
              : ListView.builder(
                  itemCount: loans.length,
                  itemBuilder: (_, i) {
                    final l = loans[i];
                    final returned = l['isReturned'] == true;
                    final dirty = l['isDirty'] == true;
                    return FadeSlide(
                      index: i,
                      child: SoftCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l['vestment']?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              Text('መመለሻ: ${EthDate.format(l['dueDate'])}'),
                              if (dirty) const Text('ቆሽሏል · እስኪታጠብ ድረስ አይመለስም', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w700)),
                              if ((l['penaltyAmount'] ?? 0).toString() != '0' && (l['penaltyAmount'] ?? '0') != '0.00')
                                Text('${S.penalty}: ${l['penaltyAmount']} ብር', style: const TextStyle(color: Colors.red)),
                              if (canManageVestments && !returned) ...[
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: const Text(S.returned),
                                  value: returned,
                                  onChanged: dirty
                                      ? null
                                      : (v) => _update(l, returned: v == true, dirty: false),
                                ),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: const Text(S.dirty),
                                  subtitle: dirty ? const Text(S.cannotReturnDirty) : null,
                                  value: dirty,
                                  onChanged: (v) => _update(l, returned: false, dirty: v == true),
                                ),
                              ],
                              if (returned) const Text('ተመልሷል (ንፁህ)', style: TextStyle(color: AppTheme.seed, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _issueOne() async {
    final ids = await pickClothes(context, widget.vestments);
    if (ids == null || ids.isEmpty) return;
    try {
      await context.read<AuthState>().api.post('/vestment-loans/issue', {
        'eventId': jsonInt(widget.event['id']),
        'groupId': jsonInt(widget.group['id']),
        'memberId': jsonInt(widget.member['id']),
        'vestmentIds': ids,
      });
      _load();
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }

  Future<void> _update(Map loan, {required bool returned, required bool dirty}) async {
    try {
      await context.read<AuthState>().api.post('/vestment-loans/return', {
        'loanId': jsonInt(loan['id']),
        'isReturned': returned,
        'isDirty': dirty,
      });
      _load();
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }
}

class UnreturnedClothesPanel extends StatelessWidget {
  const UnreturnedClothesPanel({
    super.key,
    required this.loans,
    required this.admin,
    required this.onChanged,
  });
  final List loans;
  final bool admin;
  final Future<void> Function() onChanged;

  List get _dirty => loans.where((l) => l['isDirty'] == true && l['isWashed'] != true).toList();
  List get _overdue => loans.where((l) => EthDate.daysUntil(l['dueDate']) < 0).toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: const TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppTheme.seed,
                unselectedLabelColor: AppTheme.muted,
                tabs: [
                  Tab(text: 'ቆሽሸው ያልተመለሱ'),
                  Tab(text: 'ጊዜው ያለፈ ያልተመለሱ'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _EventGroupsList(loans: _dirty, dirtyTab: true, admin: admin, onChanged: onChanged),
                _EventGroupsList(loans: _overdue, dirtyTab: false, admin: admin, onChanged: onChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventGroupsList extends StatelessWidget {
  const _EventGroupsList({
    required this.loans,
    required this.dirtyTab,
    required this.admin,
    required this.onChanged,
  });
  final List loans;
  final bool dirtyTab;
  final bool admin;
  final Future<void> Function() onChanged;

  Map<String, List> _byEvent() {
    final map = <String, List>{};
    for (final l in loans) {
      final key = '${l['event']?['name'] ?? 'በዓል የለም'}';
      map.putIfAbsent(key, () => []).add(l);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _byEvent();
    final names = grouped.keys.toList()..sort();
    return RefreshIndicator(
      color: AppTheme.seed,
      onRefresh: onChanged,
      child: names.isEmpty
          ? ListView(
              children: [
                EmptyBox(dirtyTab ? 'ቆሽሸው ያልተመለሰ ልብስ የለም' : 'ጊዜው ያለፈ ያልተመለሰ ልብስ የለም'),
              ],
            )
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    dirtyTab
                        ? 'በበዓል ይመደባል። በዓሉን ይጫኑ የቆሸሹ ተማሪዎችን ለማየት።'
                        : 'በበዓል ይመደባል። በዓሉን ይጫኑ ጊዜው ያለፈባቸውን ተማሪዎች ለማየት።',
                    style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
                  ),
                ),
                ...names.map((eventName) {
                  final items = grouped[eventName]!;
                  return SoftCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnreturnedStudentsPage(
                          eventName: eventName,
                          loans: items,
                          dirtyTab: dirtyTab,
                          admin: admin,
                        ),
                      ),
                    ).then((_) => onChanged()),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.blueSoft,
                        child: Icon(
                          dirtyTab ? Icons.local_laundry_service_outlined : Icons.event_busy_rounded,
                          color: AppTheme.seed,
                        ),
                      ),
                      title: Text(eventName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${items.length} ተማሪ / ልብስ'),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.seed),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class UnreturnedStudentsPage extends StatelessWidget {
  const UnreturnedStudentsPage({
    super.key,
    required this.eventName,
    required this.loans,
    required this.dirtyTab,
    required this.admin,
  });
  final String eventName;
  final List loans;
  final bool dirtyTab;
  final bool admin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(eventName)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text(
              dirtyTab ? 'ቆሽሸው ያልተመለሱ ተማሪዎች' : 'ጊዜው ያለፈ · ያልተመለሱ ተማሪዎች',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          ...loans.map((l) {
            final days = EthDate.daysUntil(l['dueDate']);
            final late = days < 0;
            return SoftCard(
              child: ListTile(
                title: Text(l['member']?['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  '${l['vestment']?['name'] ?? ''} · ${l['group']?['name'] ?? ''}\n'
                  'መመለሻ: ${EthDate.format(l['dueDate'])}\n'
                  '${EthDate.remainingLabel(l['dueDate'])}',
                ),
                isThreeLine: true,
                trailing: dirtyTab && admin
                    ? FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
                        onPressed: () async {
                          try {
                            await context.read<AuthState>().api.post('/vestment-loans/${l['id']}/wash');
                            if (context.mounted) {
                              showMsg(context, 'ታጥቧል። አሁን ከተማሪው ገጽ መመለስ ይችላሉ');
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) showMsg(context, e.toString(), error: true);
                          }
                        },
                        child: const Text(S.washed),
                      )
                    : Text(
                        late ? 'አልፏል' : (days == 0 ? 'ዛሬ' : 'ቀርቷል'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: late ? const Color(0xFFB45309) : AppTheme.seed,
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
