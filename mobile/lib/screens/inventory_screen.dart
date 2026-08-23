import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';
import '../ethiopian_date.dart';
import '../strings.dart';
import '../theme.dart';
import '../reports.dart';
import '../widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, this.section = InventorySection.returnable});
  final InventorySection section;
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

enum InventorySection { returnable, consumable, issued }

class _InventoryScreenState extends State<InventoryScreen> {
  List assets = [];
  List loans = [];
  List departments = [];
  List members = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthState>().api;
    final res = await Future.wait([
      api.get('/assets'),
      api.get('/asset-loans'),
      api.get('/departments'),
      api.get('/members'),
    ]);
    setState(() {
      assets = res[0];
      loans = res[1];
      departments = res[2];
      members = res[3];
      loading = false;
    });
  }

  bool get _admin => context.watch<AuthState>().isAdmin;

  List get _returnable => assets.where((a) => a['type'] == 'RETURNABLE').toList();
  List get _consumable => assets.where((a) => a['type'] == 'CONSUMABLE').toList();

  List<DropdownMenuItem<int>> get _deptItems {
    final items = <DropdownMenuItem<int>>[];
    for (final d in departments) {
      final id = jsonInt(d['id']);
      if (id == null) continue;
      items.add(DropdownMenuItem(value: id, child: Text('${d['name'] ?? ''}')));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    if (widget.section == InventorySection.issued) {
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: const TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppTheme.seed,
                  unselectedLabelColor: AppTheme.muted,
                  tabs: [
                    Tab(text: S.returnable),
                    Tab(text: S.consumable),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _issuedTab(returnable: true),
                  _issuedTab(returnable: false),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final returnable = widget.section == InventorySection.returnable;
    return returnable
        ? _tabBody(
            hint: 'ቋሚ ንብረት እዚህ ወደ መደብር ይመዝግቡ። ክፍል የሚመረጠው ያወጡ ንብረቶች ላይ ብቻ ነው።',
            children: [
              if (_admin) _registerAssetButton(true),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: ReportDoc.button(_exportInventory),
              ),
              const SectionHeader(S.returnable),
              if (_returnable.isEmpty) const EmptyBox('ቋሚ ንብረት የለም · አዲስ ንብረት መዝግብ ይጫኑ'),
              ..._returnable.asMap().entries.map((e) => _assetCard(e.value as Map, e.key, returnable: true)),
            ],
          )
        : _tabBody(
            hint: 'አላቂ ንብረት እዚህ ወደ መደብር ይመዝግቡ። ለክፍል ሲወጣ ከጎን ሜኑ → ያወጡ ንብረቶች።',
            children: [
              if (_admin) _registerAssetButton(false),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: ReportDoc.button(_exportInventory),
              ),
              const SectionHeader(S.consumable),
              if (_consumable.isEmpty) const EmptyBox('አላቂ ንብረት የለም · አዲስ ንብረት መዝግብ ይጫኑ'),
              ..._consumable.asMap().entries.map((e) => _assetCard(e.value as Map, e.key, returnable: false)),
            ],
          );
  }

  Widget _issuedTab({required bool returnable}) {
    if (!returnable) return _issuedConsumableByDept();
    final items = loans.where((l) => l['asset']?['type'] != 'CONSUMABLE').toList();
    return _tabBody(
      hint: 'ቋሚ ንብረት ሲመለስ ታሪኩ ይቀመጣል (ሪፖርት)። የተበላሸ / የጎደለ ብዛት ይመዝገባል።',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              if (_admin)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _registerIssued(returnable: true),
                    icon: const Icon(Icons.outbox_rounded),
                    label: const Text(S.registerIssued),
                  ),
                ),
              if (_admin) const SizedBox(width: 8),
              Expanded(child: ReportDoc.button(_exportInventory)),
            ],
          ),
        ),
        const SectionHeader(S.issuedItems),
        if (items.isEmpty) const EmptyBox('ያወጡ ንብረት የለም'),
        ...items.map((l) => _issuedCard(l as Map, returnable: true)),
      ],
    );
  }

  Widget _issuedConsumableByDept() {
    final items = loans.where((l) => l['asset']?['type'] == 'CONSUMABLE').toList();
    final byDept = <String, List<Map>>{};
    for (final l in items) {
      final key = '${l['department']?['name'] ?? 'ክፍል የለም'}';
      byDept.putIfAbsent(key, () => []).add(Map<String, dynamic>.from(l as Map));
    }
    final names = byDept.keys.toList()..sort();
    return _tabBody(
      hint: 'አላቂ ንብረት በክፍል ይታያል። አንድ ክፍል ብዙ ንብረት መውሰድ ይችላል።',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              if (_admin)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _registerIssued(returnable: false),
                    icon: const Icon(Icons.outbox_rounded),
                    label: const Text(S.registerIssued),
                  ),
                ),
              if (_admin) const SizedBox(width: 8),
              Expanded(child: ReportDoc.button(_exportInventory)),
            ],
          ),
        ),
        const SectionHeader('ያወጡ አላቂ በክፍል'),
        if (names.isEmpty) const EmptyBox('ያወጡ አላቂ ንብረት የለም'),
        ...names.map((dept) {
          final list = byDept[dept]!;
          final sums = <String, int>{};
          for (final l in list) {
            final n = '${l['asset']?['name'] ?? 'ንብረት'}';
            sums[n] = (sums[n] ?? 0) + ((l['quantity'] as num?)?.toInt() ?? 0);
          }
          final total = sums.values.fold<int>(0, (a, b) => a + b);
          return SoftCard(
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(dept, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('$total ብዛት · ${sums.length} ዓይነት ንብረት'),
              children: [
                ...sums.entries.map(
                  (e) => ListTile(
                    dense: true,
                    title: Text(e.key),
                    trailing: Text('× ${e.value}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.seed)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _tabBody({required String hint, required List<Widget> children}) {
    return RefreshIndicator(
      color: AppTheme.seed,
      onRefresh: _load,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text(hint, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600)),
          ),
          ...children,
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _registerAssetButton(bool returnable) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: FilledButton.icon(
        onPressed: () => _addAsset(returnable ? 'RETURNABLE' : 'CONSUMABLE'),
        icon: const Icon(Icons.add_rounded),
        label: const Text(S.registerAsset),
      ),
    );
  }

  Widget _assetCard(Map a, int index, {required bool returnable}) {
    final takenLines = _takenByDepartment(jsonInt(a['id']));
    return FadeSlide(
      index: index,
      child: SoftCard(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.blueSoft,
            child: Icon(
              returnable ? Icons.chair_alt_outlined : Icons.inventory_2_outlined,
              color: AppTheme.seed,
            ),
          ),
          title: Text('${a['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
            returnable
                ? '${S.available}: ${a['availableQuantity']} · ${S.issued}: ${a['issuedQuantity']}\n'
                    '${S.damaged}: ${a['damagedQuantity']} · ${S.lost}: ${a['lostQuantity']}'
                : '${S.available}: ${a['availableQuantity']} · ${S.issued}: ${a['issuedQuantity']}'
                    '${takenLines.isEmpty ? '' : '\n$takenLines'}',
          ),
          isThreeLine: true,
          trailing: _admin
              ? PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _editAsset(a);
                    if (v == 'delete') _removeAsset(a);
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
  }

  String _takenByDepartment(int? assetId) {
    if (assetId == null) return '';
    final sums = <String, int>{};
    for (final l in loans) {
      if (jsonInt(l['asset']?['id'] ?? l['assetId']) != assetId) continue;
      if (l['asset']?['type'] == 'RETURNABLE') continue;
      final name = l['department']?['name'] ?? 'ክፍል';
      sums[name] = (sums[name] ?? 0) + ((l['quantity'] as num?)?.toInt() ?? 0);
    }
    if (sums.isEmpty) return '';
    return sums.entries.map((e) => '${e.key}: ${e.value} ተወስዷል').join(' · ');
  }

  Widget _issuedCard(Map l, {required bool returnable}) {
    final returned = l['isReturned'] == true;
    final intact = l['returnedIntact'];
    final damaged = l['returnedDamaged'];
    final lost = l['returnedLost'];
    final canCheckin = _admin && returnable && !returned;
    String status;
    if (!returnable) {
      status = 'ለክፍል የወጣ · አይመለስም';
    } else if (returned) {
      status = 'ተመልሷል · ${S.intact}: $intact · ${S.damaged}: $damaged · ${S.lost}: $lost';
    } else {
      status = 'ያልተመለሰ · መመለስ አለበት';
    }
    return SoftCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l['asset']?['name'] ?? ''} × ${l['quantity']}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              l['department']?['name'] ?? l['member']?['fullName'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'የወጣበት: ${EthDate.format(l['issuedDate'])}'
              '${returned && l['returnedDate'] != null ? ' · ተመለሰ: ${EthDate.format(l['returnedDate'])}' : ''}',
              style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(status, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600)),
            if (canCheckin) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _checkin(l),
                  child: const Text(S.checkin),
                ),
              ),
            ] else if (!canCheckin) ...[
              const SizedBox(height: 8),
              Text(
                returned ? 'ታሪክ' : (returnable ? 'ያልተመለሰ' : 'የወጣ'),
                style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addAsset(String type) async {
    await _assetForm(type: type);
  }

  Future<void> _editAsset(Map a) async {
    await _assetForm(type: '${a['type'] ?? 'CONSUMABLE'}', existing: a);
  }

  Future<void> _assetForm({required String type, Map? existing}) async {
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    final qty = TextEditingController(text: '${existing?['totalQuantity'] ?? 1}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null
              ? (type == 'RETURNABLE' ? 'አዲስ ቋሚ ንብረት መዝግብ' : 'አዲስ አላቂ ንብረት መዝግብ')
              : S.edit,
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ንብረት ወደ መደብር ይገባል። ክፍል የሚመረጠው ያወጡ ንብረቶች ላይ ብቻ ነው።',
                style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'የንብረት ስም')),
              TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ብዛት')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      try {
        final body = {
          'name': name.text.trim(),
          'totalQuantity': int.tryParse(qty.text) ?? 0,
        };
        if (existing == null) {
          await context.read<AuthState>().api.post('/assets', {...body, 'type': type});
        } else {
          await context.read<AuthState>().api.patch('/assets/${jsonInt(existing['id'])}', body);
        }
        if (mounted) showMsg(context, S.success);
        _load();
      } catch (e) {
        if (mounted) showMsg(context, e.toString(), error: true);
      }
    }
  }

  Future<void> _registerIssued({required bool returnable}) async {
    final list = returnable ? _returnable : _consumable;
    if (list.isEmpty) {
      showMsg(context, 'መጀመሪያ አዲስ ንብረት ይመዝግቡ', error: true);
      return;
    }
    if (departments.isEmpty) {
      showMsg(context, 'መጀመሪያ ክፍል ይመዝግቡ', error: true);
      return;
    }
    int? deptId = _deptItems.first.value;
    int? memberId;
    final selected = <int>{};
    final qtyCtrls = <int, TextEditingController>{};
    for (final a in list) {
      final id = jsonInt(a['id']);
      if (id == null) continue;
      qtyCtrls[id] = TextEditingController(text: '1');
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text(S.registerIssued),
          content: SizedBox(
            width: 360,
            height: 460,
            child: ListView(
              children: [
                Text(
                  returnable
                      ? 'አንድ ክፍል ከአንድ በላይ ቋሚ ንብረት መውሰድ ይችላል'
                      : 'አንድ ክፍል ከአንድ በላይ አላቂ ንብረት መውሰድ ይችላል',
                  style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: deptId,
                  decoration: const InputDecoration(labelText: S.departments),
                  items: _deptItems,
                  onChanged: (v) => setS(() => deptId = v),
                ),
                if (returnable)
                  DropdownButtonFormField<int?>(
                    value: memberId,
                    decoration: const InputDecoration(labelText: 'የወሰደው አባል (ከተፈለገ)'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('—')),
                      ...members
                          .map((m) {
                            final id = jsonInt(m['id']);
                            if (id == null) return null;
                            return DropdownMenuItem<int?>(value: id, child: Text('${m['fullName'] ?? ''}'));
                          })
                          .whereType<DropdownMenuItem<int?>>(),
                    ],
                    onChanged: (v) => setS(() => memberId = v),
                  ),
                const SizedBox(height: 8),
                const Text('ንብረቶች ይምረጡ', style: TextStyle(fontWeight: FontWeight.w800)),
                ...list.map((a) {
                  final id = jsonInt(a['id']);
                  if (id == null) return const SizedBox.shrink();
                  final available = (a['availableQuantity'] as num?)?.toInt() ?? 0;
                  final on = selected.contains(id);
                  return Column(
                    children: [
                      CheckboxListTile(
                        value: on,
                        title: Text('${a['name'] ?? ''}'),
                        subtitle: Text('${S.available}: $available'),
                        onChanged: available < 1
                            ? null
                            : (v) => setS(() {
                                  if (v == true) {
                                    selected.add(id);
                                  } else {
                                    selected.remove(id);
                                  }
                                }),
                      ),
                      if (on)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                          child: TextField(
                            controller: qtyCtrls[id],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'ብዛት'),
                          ),
                        ),
                    ],
                  );
                }),
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
        ),
      ),
    );
    if (ok == true) {
      try {
        await context.read<AuthState>().api.post('/asset-loans/checkout-many', {
          'departmentId': deptId,
          if (returnable) 'memberId': memberId,
          'lines': selected
              .map((id) => {
                    'assetId': id,
                    'quantity': int.tryParse(qtyCtrls[id]?.text ?? '1') ?? 1,
                  })
              .toList(),
        });
        if (mounted) showMsg(context, S.success);
        _load();
      } catch (e) {
        if (mounted) showMsg(context, e.toString(), error: true);
      }
    }
    for (final c in qtyCtrls.values) {
      c.dispose();
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.remove)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _removeAsset(Map a) async {
    if (!await _confirm(S.remove, '${a['name'] ?? ''} ይወገድ?')) return;
    try {
      await context.read<AuthState>().api.delete('/assets/${jsonInt(a['id'])}');
      _load();
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }

  Future<void> _checkin(Map loan) async {
    final total = (loan['quantity'] as num?)?.toInt() ?? 1;
    final damagedCtrl = TextEditingController(text: '0');
    final lostCtrl = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final damaged = int.tryParse(damagedCtrl.text) ?? 0;
          final lost = int.tryParse(lostCtrl.text) ?? 0;
          final intact = total - damaged - lost;
          final invalid = damaged < 0 || lost < 0 || intact < 0;
          return AlertDialog(
            title: Text('${S.checkin}: ${loan['asset']?['name'] ?? ''}'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('የወጣው ብዛት: $total', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('የተበላሸ እና የጎደለ ብዛት ይጻፉ። የቀረው ደህና ተመልሷል ይሆናል።'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: damagedCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'የተበላሸ ብዛት'),
                    onChanged: (_) => setS(() {}),
                  ),
                  TextField(
                    controller: lostCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'የጎደለ ብዛት'),
                    onChanged: (_) => setS(() {}),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    invalid ? 'የተበላሸ + የጎደለ ከ $total መብለጥ አይችልም' : '${S.intact}: $intact',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: invalid ? const Color(0xFFE11D48) : AppTheme.seed,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
              FilledButton(
                onPressed: invalid ? null : () => Navigator.pop(ctx, true),
                child: const Text(S.save),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    try {
      await context.read<AuthState>().api.post('/asset-loans/checkin', {
        'loanId': jsonInt(loan['id']),
        'damagedQuantity': int.tryParse(damagedCtrl.text) ?? 0,
        'lostQuantity': int.tryParse(lostCtrl.text) ?? 0,
      });
      _load();
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }

  Future<void> _exportInventory() async {
    final kind = await ReportDoc.pickKind(
      context,
      title: 'የንብረት ሪፖርት',
      kinds: const [
        ReportKind('stock', 'በመደብር ያለ ንብረት', hint: 'ቋሚ እና አላቂ'),
        ReportKind('issued-returnable', 'ያወጡ ቋሚ ንብረቶች'),
        ReportKind('issued-consumable', 'ያወጡ አላቂ በክፍል'),
        ReportKind('unreturned', 'ያልተመለሱ ቋሚ ንብረቶች'),
        ReportKind('month', 'በዚህ ወር የወጡ ንብረቶች'),
      ],
    );
    if (kind == null) return;
    await ReportDoc.run(context, () async {
      if (kind == 'stock') {
        await ReportDoc.share(
          title: 'በመደብር ያለ ንብረት',
          headers: const ['ስም', 'ዓይነት', 'ጠቅላላ', 'ያለው', 'የወጣ'],
          rows: assets
              .map((a) => [
                    '${a['name'] ?? ''}',
                    a['type'] == 'CONSUMABLE' ? 'አላቂ' : 'ቋሚ',
                    '${a['totalQuantity'] ?? ''}',
                    '${a['availableQuantity'] ?? ''}',
                    '${a['issuedQuantity'] ?? ''}',
                  ])
              .toList(),
        );
        return;
      }
      if (kind == 'issued-consumable') {
        final items = loans.where((l) => l['asset']?['type'] == 'CONSUMABLE').toList();
        final sums = <String, Map<String, int>>{};
        for (final l in items) {
          final dept = '${l['department']?['name'] ?? 'ክፍል የለም'}';
          final name = '${l['asset']?['name'] ?? ''}';
          sums.putIfAbsent(dept, () => {});
          sums[dept]![name] = (sums[dept]![name] ?? 0) + ((l['quantity'] as num?)?.toInt() ?? 0);
        }
        final rows = <List<String>>[];
        for (final dept in sums.keys.toList()..sort()) {
          for (final e in sums[dept]!.entries) {
            rows.add([dept, e.key, '${e.value}']);
          }
        }
        await ReportDoc.share(
          title: 'ያወጡ አላቂ ንብረት በክፍል',
          headers: const ['ክፍል', 'ንብረት', 'ብዛት'],
          rows: rows,
        );
        return;
      }
      Iterable list = loans;
      var title = 'ያወጡ ንብረቶች';
      if (kind == 'issued-returnable') {
        list = loans.where((l) => l['asset']?['type'] != 'CONSUMABLE');
        title = 'ያወጡ ቋሚ ንብረቶች';
      } else if (kind == 'unreturned') {
        list = loans.where((l) => l['asset']?['type'] != 'CONSUMABLE' && l['isReturned'] != true);
        title = 'ያልተመለሱ ቋሚ ንብረቶች';
      } else if (kind == 'month') {
        list = loans.where((l) => EthDate.inThisMonth(l['issuedDate']));
        title = 'በዚህ ወር የወጡ ንብረቶች (${EthDate.now().monthName} ${EthDate.now().year})';
      }
      await ReportDoc.share(
        title: title,
        headers: const ['ንብረት', 'ክፍል', 'ብዛት', 'ቀን', 'ሁኔታ'],
        rows: list
            .map((l) => [
                  '${l['asset']?['name'] ?? ''}',
                  '${l['department']?['name'] ?? l['member']?['fullName'] ?? ''}',
                  '${l['quantity'] ?? ''}',
                  EthDate.format(l['issuedDate']),
                  l['asset']?['type'] == 'CONSUMABLE'
                      ? 'አላቂ'
                      : (l['isReturned'] == true ? 'ተመልሷል' : 'ያልተመለሰ'),
                ])
            .toList(),
      );
    });
  }
}
