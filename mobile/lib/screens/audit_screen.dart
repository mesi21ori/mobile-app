import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';
import '../ethiopian_date.dart';
import '../strings.dart';
import '../theme.dart';
import '../reports.dart';
import '../widgets.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});
  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  List audits = [];
  List departments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthState>().api;
    final res = await Future.wait([
      api.get('/audits'),
      api.get('/departments'),
    ]);
    setState(() {
      audits = res[0];
      departments = res[1];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (loading) return const LoadingView();
    return RefreshIndicator(
      color: AppTheme.seed,
      onRefresh: _load,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Text(
              'ኦዲት አላቂ ንብረት ላይ ነው። አንድ ክፍል የወሰዳቸው ሁሉም ንብረቶች በአንድ ኦዲት ይቆጠራሉ። 6 ወር በዓመት 2 ጊዜ፣ 3 ወር በዓመት 4 ጊዜ።',
              style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
            ),
          ),
          if (auth.isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AuditCreatePage(departments: departments)),
                ).then((_) => _load()),
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('ኦዲት ጀምር'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ReportDoc.button(_exportAudits),
          ),
          const SectionHeader(S.audit),
          if (audits.isEmpty) const EmptyBox('ኦዲት የለም · መጀመሪያ አላቂ ንብረት ለክፍል ያውጡ'),
          ...audits.asMap().entries.map((entry) {
            final a = entry.value;
            final details = (a['details'] as List?) ?? [];
            return FadeSlide(
              index: entry.key,
              child: SoftCard(
                onTap: () => _showDetails(a),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.blueSoft,
                    child: Icon(Icons.fact_check_rounded, color: AppTheme.seed),
                  ),
                  title: Text('${a['department']?['name'] ?? ''} · ${_period(a['period'])}'),
                  subtitle: Text('${_status(a['status'])} · ${EthDate.format(a['auditDate'])} · ${details.length} ንብረት'),
                  trailing: auth.isSuper && a['status'] != 'APPROVED'
                      ? FilledButton(
                          style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
                          onPressed: () async {
                            try {
                              await context.read<AuthState>().api.post('/audits/${jsonInt(a['id'])}/approve');
                              _load();
                            } catch (e) {
                              if (mounted) showMsg(context, e.toString(), error: true);
                            }
                          },
                          child: const Text(S.approve),
                        )
                      : Text(_status(a['status']), style: const TextStyle(color: AppTheme.seed, fontWeight: FontWeight.w700)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _period(v) => v == 'SIX_MONTHS' ? S.sixMonths : S.threeMonths;
  String _status(v) {
    switch (v) {
      case 'APPROVED':
        return 'ጸድቋል';
      case 'SUBMITTED':
        return 'ተልኳል';
      default:
        return 'ረቂቅ';
    }
  }

  void _showDetails(Map a) {
    final details = (a['details'] as List?) ?? [];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: 520,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${a['department']?['name'] ?? ''} · ${_period(a['period'])}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text('ምሳሌ፦ 6 ወጣ − 4 ተጠቀመ = 2 ቀረ። ቀጣዩ ከ 2 ይጀምራል። 1 − 1 = 0 ከሆነ ቀጣዩ ከ 0 ይጀምራል።'),
            const SizedBox(height: 8),
            if (details.isEmpty) const EmptyBox('መስመር የለም'),
            ...details.map((d) {
              final taken = (d['systemQuantity'] as num?)?.toInt() ?? 0;
              final have = (d['physicalQuantity'] as num?)?.toInt() ?? 0;
              final used = taken - have;
              final type = d['asset']?['type'] == 'CONSUMABLE' ? S.consumable : S.returnable;
              return SoftCard(
                child: ListTile(
                  title: Text('${d['asset']?['name'] ?? ''}'),
                  subtitle: Text(
                    '$type\n'
                    '${S.issued}: $taken · ${S.remainingNow}: $have\n'
                    '${S.usedUp}: $used',
                  ),
                  isThreeLine: true,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAudits() async {
    await ReportDoc.run(context, () async {
      final rows = <List<String>>[];
      for (final a in audits) {
        final details = (a['details'] as List?) ?? [];
        if (details.isEmpty) {
          rows.add([
            '${a['department']?['name'] ?? ''}',
            _period(a['period']),
            EthDate.format(a['auditDate']),
            _status(a['status']),
            '-',
            '-',
            '-',
          ]);
        }
        for (final d in details) {
          rows.add([
            '${a['department']?['name'] ?? ''}',
            _period(a['period']),
            EthDate.format(a['auditDate']),
            _status(a['status']),
            '${d['asset']?['name'] ?? ''}',
            '${d['systemQuantity'] ?? ''}',
            '${d['physicalQuantity'] ?? ''}',
          ]);
        }
      }
      await ReportDoc.share(
        title: 'የኦዲት ሪፖርት',
        headers: const ['ክፍል', 'ጊዜ', 'ቀን', 'ሁኔታ', 'ንብረት', 'የሚቆጠር', 'የቀረ'],
        rows: rows,
      );
    });
  }
}

class AuditCreatePage extends StatefulWidget {
  const AuditCreatePage({super.key, required this.departments});
  final List departments;
  @override
  State<AuditCreatePage> createState() => _AuditCreatePageState();
}

class _AuditCreatePageState extends State<AuditCreatePage> {
  late int? deptId;
  String period = 'SIX_MONTHS';
  List lines = [];
  bool loading = true;
  bool firstAudit = true;
  String? lastAuditDate;
  int maxAudits = 2;
  int auditsThisYear = 0;
  int remainingAudits = 2;
  final qtyCtrls = <int, TextEditingController>{};
  final remarks = <int, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    deptId = widget.departments.isEmpty ? null : jsonInt(widget.departments.first['id']);
    _loadPreview();
  }

  @override
  void dispose() {
    for (final c in qtyCtrls.values) {
      c.dispose();
    }
    for (final c in remarks.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPreview() async {
    if (deptId == null) {
      setState(() {
        lines = [];
        loading = false;
      });
      return;
    }
    setState(() => loading = true);
    try {
      final data = await context.read<AuthState>().api.get(
            '/audits/preview?departmentId=$deptId&period=$period',
          );
      final next = data is Map ? (data['lines'] as List? ?? []) : (data is List ? data : []);
      for (final row in next) {
        final assetId = jsonInt(row['assetId']);
        if (assetId == null) continue;
        final taken = (row['taken'] as num?)?.toInt() ?? (row['systemQuantity'] as num?)?.toInt() ?? 0;
        qtyCtrls.putIfAbsent(assetId, () => TextEditingController());
        qtyCtrls[assetId]!.text = '$taken';
        remarks.putIfAbsent(assetId, () => TextEditingController());
      }
      setState(() {
        lines = next;
        firstAudit = data is Map ? data['firstAudit'] != false : true;
        final last = data is Map ? data['lastAudit'] : null;
        lastAuditDate = last is Map ? last['auditDate']?.toString() : null;
        maxAudits = data is Map ? (data['maxAudits'] as num?)?.toInt() ?? 2 : 2;
        auditsThisYear = data is Map ? (data['auditsThisYear'] as num?)?.toInt() ?? 0 : 0;
        remainingAudits = data is Map ? (data['remainingAudits'] as num?)?.toInt() ?? maxAudits : maxAudits;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }

  List<DropdownMenuItem<int>> get _deptItems {
    final items = <DropdownMenuItem<int>>[];
    for (final d in widget.departments) {
      final id = jsonInt(d['id']);
      if (id == null) continue;
      items.add(DropdownMenuItem(value: id, child: Text('${d['name'] ?? ''}')));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ኦዲት ጀምር')),
      body: loading
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  period == 'THREE_MONTHS'
                      ? 'የ3 ወር ኦዲት በዓመት 4 ጊዜ። የወጡ ሁሉም ንብረቶች እዚህ ይታያሉ።'
                      : 'የ6 ወር ኦዲት በዓመት 2 ጊዜ። የወጡ ሁሉም ንብረቶች እዚህ ይታያሉ።',
                  style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (_deptItems.isEmpty)
                  const EmptyBox('መጀመሪያ ክፍል ይመዝግቡ')
                else
                  DropdownButtonFormField<int>(
                    value: deptId,
                    decoration: const InputDecoration(labelText: S.departments),
                    items: _deptItems,
                    onChanged: (v) {
                      setState(() => deptId = v);
                      _loadPreview();
                    },
                  ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: period,
                  decoration: const InputDecoration(labelText: 'የኦዲት ጊዜ'),
                  items: const [
                    DropdownMenuItem(value: 'THREE_MONTHS', child: Text(S.threeMonths)),
                    DropdownMenuItem(value: 'SIX_MONTHS', child: Text(S.sixMonths)),
                  ],
                  onChanged: (v) {
                    setState(() => period = v ?? 'SIX_MONTHS');
                    _loadPreview();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Text(
                    remainingAudits == 0
                        ? 'በዚህ ዓመት ይህ ኦዲት ተሞልቷል ($auditsThisYear/$maxAudits)። ተጨማሪ አይቻልም።'
                        : 'በዚህ ዓመት $auditsThisYear/$maxAudits ተደርጓል · የቀረ $remainingAudits ጊዜ',
                    style: TextStyle(
                      color: remainingAudits == 0 ? Colors.red.shade700 : AppTheme.seed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SectionHeader('የሚቆጠር ንብረት'),
                if (!firstAudit && lastAuditDate != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text(
                      'ከቀድሞ ኦዲት (${EthDate.format(lastAuditDate)}) የቀረ ብዛት። ያ ወረቀት እንደገና አይቆጠርም። ከዚያ በኋላ አዲስ የወጣ ብቻ ይጨመራል።',
                      style: const TextStyle(color: AppTheme.seed, fontWeight: FontWeight.w700),
                    ),
                  ),
                if (lines.isEmpty)
                  EmptyBox(
                    firstAudit
                        ? 'ለዚህ ክፍል የሚቆጠር ንብረት የለም። ያወጡ ንብረቶችን መዝግቡ።'
                        : 'ከቀድሞ ኦዲት የቀረ የለም፣ አዲስ የወጣም የለም።',
                  ),
                ...lines.map((row) {
                  final assetId = jsonInt(row['assetId']);
                  if (assetId == null) return const SizedBox.shrink();
                  final opening = (row['opening'] as num?)?.toInt() ?? 0;
                  final newly = (row['newTaken'] as num?)?.toInt() ?? 0;
                  final taken = (row['taken'] as num?)?.toInt() ?? (row['systemQuantity'] as num?)?.toInt() ?? 0;
                  final fromLast = row['fromLastAudit'] == true;
                  final type = row['type'] == 'CONSUMABLE' ? S.consumable : S.returnable;
                  return SoftCard(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${row['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(type),
                          if (row['type'] == 'CONSUMABLE')
                            Text(
                              fromLast
                                  ? 'ከቀድሞ የቀረ: $opening · አዲስ የወጣ: $newly · አሁን የሚቆጠር: $taken'
                                  : 'የተወሰደ: $taken',
                            )
                          else
                            Text('${S.issued}: $taken'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: qtyCtrls[assetId],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: '${S.remainingNow} — አሁን የቀረውን ጻፉ (ከ $taken)'),
                            onChanged: (_) => setState(() {}),
                          ),
                          TextField(
                            controller: remarks[assetId],
                            decoration: const InputDecoration(labelText: 'ማብራሪያ'),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${S.usedUp}: $taken − ${int.tryParse(qtyCtrls[assetId]?.text ?? '0') ?? 0} = ${taken - (int.tryParse(qtyCtrls[assetId]?.text ?? '0') ?? 0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.seed),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: lines.isEmpty || remainingAudits == 0 ? null : _save,
                  child: const Text(S.save),
                ),
              ],
            ),
    );
  }

  Future<void> _save() async {
    try {
      await context.read<AuthState>().api.post('/audits', {
        'departmentId': deptId,
        'period': period,
        'lines': lines
            .map((row) {
              final assetId = jsonInt(row['assetId']);
              return {
                'assetId': assetId,
                'physicalQuantity': int.tryParse(qtyCtrls[assetId]?.text ?? '0') ?? 0,
                'remarks': remarks[assetId]?.text,
              };
            })
            .where((line) => line['assetId'] != null)
            .toList(),
      });
      if (mounted) {
        showMsg(context, S.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }
}
