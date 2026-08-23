import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth.dart';
import '../ethiopian_date.dart';
import '../strings.dart';
import '../theme.dart';
import '../reports.dart';
import '../widgets.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key, this.typeFilter});
  final String? typeFilter;
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List events = [];
  List rows = [];
  Map summary = {'income': 0, 'expense': 0, 'net': 0};
  int? eventId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthState>().api;
    final q = eventId == null ? '' : '?eventId=$eventId';
    final res = await Future.wait([
      api.get('/events'),
      api.get('/finance$q'),
      api.get('/finance/summary$q'),
    ]);
    setState(() {
      events = res[0];
      rows = res[1];
      summary = Map<String, dynamic>.from(res[2]);
      loading = false;
    });
  }

  void _onCreateFinance() {
    if (widget.typeFilter == 'INCOME') {
      _add('INCOME');
      return;
    }
    if (widget.typeFilter == 'EXPENSE') {
      _add('EXPENSE');
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.south_west_rounded, color: AppTheme.seed),
              title: Text(S.income),
              onTap: () {
                Navigator.pop(ctx);
                _add('INCOME');
              },
            ),
            ListTile(
              leading: const Icon(Icons.north_east_rounded, color: AppTheme.muted),
              title: Text(S.expense),
              onTap: () {
                Navigator.pop(ctx);
                _add('EXPENSE');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final superAdmin = context.watch<AuthState>().isSuper;
    if (loading) return const LoadingView();
    final opening = summary['openingBalance'] ?? 0;
    final locked = summary['openingBalanceLocked'] == true;

    String fabLabel = S.add;
    if (widget.typeFilter == 'INCOME') fabLabel = S.income;
    if (widget.typeFilter == 'EXPENSE') fabLabel = S.expense;

    final body = RefreshIndicator(
      color: AppTheme.seed,
      onRefresh: _load,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DropdownButtonFormField<int?>(
              value: eventId,
              decoration: const InputDecoration(labelText: S.events),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('አጠቃላይ')),
                ...events.map((e) => DropdownMenuItem<int?>(value: e['id'], child: Text(e['name']))),
              ],
              onChanged: (v) {
                eventId = v;
                _load();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: StatChip(label: S.income, value: '${summary['income']} ብር', color: AppTheme.seed, icon: Icons.south_west_rounded)),
                const SizedBox(width: 8),
                Expanded(child: StatChip(label: S.expense, value: '${summary['expense']} ብር', color: const Color(0xFF64748B), icon: Icons.north_east_rounded)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: StatChip(label: S.net, value: '${summary['net']} ብር', color: AppTheme.blue, icon: Icons.account_balance_wallet_outlined),
          ),
          if (eventId == null) ...[
            SoftCard(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: AppTheme.blueSoft, child: Icon(Icons.savings_outlined, color: AppTheme.seed)),
                title: const Text('የመጀመሪያ ቀሪ ሒሳብ', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(locked ? 'ተቀምጧል · $opening ብር' : 'አልተመዘገበም · ገቢ/ወጪ ከዚህ ይሰላል'),
                trailing: locked
                    ? Text('$opening ብር', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.seed))
                    : (superAdmin
                        ? TextButton(onPressed: _setOpeningBalance, child: const Text('መዝግብ'))
                        : null),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ReportDoc.button(_exportFinance),
          ),
          SectionHeader('ዝርዝር'),
          ...rows.where((r) => widget.typeFilter == null || r['type'] == widget.typeFilter).toList().asMap().entries.map((entry) {
            final r = entry.value;
            final income = r['type'] == 'INCOME';
            return FadeSlide(
              index: entry.key,
              child: SoftCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: income ? AppTheme.blueSoft : const Color(0xFFEEF2FF),
                    child: Icon(income ? Icons.south_west_rounded : Icons.north_east_rounded, color: income ? AppTheme.seed : AppTheme.muted, size: 18),
                  ),
                  title: Text(r['reason'] ?? ''),
                  subtitle: Text(EthDate.format(r['createdAt'])),
                  trailing: Text(
                    '${income ? '+' : '-'} ${r['amount']} ብር',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: income ? AppTheme.seed : AppTheme.muted,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (superAdmin) createFabScrollPad else const SizedBox(height: 24),
        ],
      ),
    );

    return CreateFabLayout(
      onCreate: superAdmin ? _onCreateFinance : null,
      label: fabLabel,
      icon: widget.typeFilter == 'EXPENSE' ? Icons.north_east_rounded : Icons.add_rounded,
      body: body,
    );
  }

  Future<void> _setOpeningBalance() async {
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('የመጀመሪያ ቀሪ ሒሳብ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('አሁን ያለው ገንዘብ (deposit) መዝግቡ። አንዴ ከተቀመጠ በኋላ መቀየር አይችልም።', style: TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 8),
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'መጠን (ብር)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<AuthState>().api.post('/finance/opening-balance', {'amount': double.parse(amount.text)});
      _load();
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }

  Future<void> _add(String type) async {
    final reason = TextEditingController();
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'INCOME' ? S.income : S.expense),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: reason, decoration: const InputDecoration(labelText: S.reason)),
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: S.amount)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
        ],
      ),
    );
    if (ok == true) {
      try {
        await context.read<AuthState>().api.post('/finance', {
          'eventId': eventId,
          'type': type,
          'reason': reason.text,
          'amount': double.parse(amount.text),
        });
        _load();
      } catch (e) {
        if (mounted) showMsg(context, e.toString(), error: true);
      }
    }
  }

  Future<void> _exportFinance() async {
    final kind = await ReportDoc.pickKind(
      context,
      title: 'የፋይናንስ ሪፖርት',
      kinds: const [
        ReportKind('all', 'ሁሉም ገቢና ወጪ'),
        ReportKind('income', 'የዚህ ወር ገቢ'),
        ReportKind('expense', 'የዚህ ወር ወጪ'),
        ReportKind('month', 'የዚህ ወር ሁሉም'),
      ],
    );
    if (kind == null) return;
    await ReportDoc.run(context, () async {
      Iterable list = rows;
      var title = 'ፋይናንስ';
      if (kind == 'income') {
        list = rows.where((r) => r['type'] == 'INCOME' && EthDate.inThisMonth(r['createdAt']));
        title = 'የዚህ ወር ገቢ (${EthDate.now().monthName} ${EthDate.now().year})';
      } else if (kind == 'expense') {
        list = rows.where((r) => r['type'] == 'EXPENSE' && EthDate.inThisMonth(r['createdAt']));
        title = 'የዚህ ወር ወጪ (${EthDate.now().monthName} ${EthDate.now().year})';
      } else if (kind == 'month') {
        list = rows.where((r) => EthDate.inThisMonth(r['createdAt']));
        title = 'የዚህ ወር ፋይናንስ (${EthDate.now().monthName} ${EthDate.now().year})';
      }
      final shown = list.toList();
      num income = 0, expense = 0;
      for (final r in shown) {
        final amt = num.tryParse('${r['amount']}') ?? 0;
        if (r['type'] == 'INCOME') {
          income += amt;
        } else {
          expense += amt;
        }
      }
      await ReportDoc.share(
        title: title,
        subtitle: 'ገቢ $income ብር · ወጪ $expense ብር · የተጣራ ${income - expense} ብር',
        headers: const ['ቀን', 'ዓይነት', 'ምክንያት', 'መጠን'],
        rows: shown
            .map((r) => [
                  EthDate.format(r['createdAt']),
                  r['type'] == 'INCOME' ? 'ገቢ' : 'ወጪ',
                  '${r['reason'] ?? ''}',
                  '${r['amount'] ?? ''} ብር',
                ])
            .toList(),
      );
    });
  }
}
