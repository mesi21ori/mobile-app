import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_logo.dart';
import '../auth.dart';
import '../ethiopian_date.dart';
import '../nav.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'audit_screen.dart';
import 'finance_screen.dart';
import 'inventory_screen.dart';
import 'more_screen.dart';
import 'vestments_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String pageId = AppNav.home.id;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const AppLogo(size: 34, elevated: false),
            const SizedBox(width: 10),
            Expanded(
              child: Text(AppNav.titleFor(pageId), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      drawer: _AppDrawer(
        pageId: pageId,
        onSelect: (id) {
          setState(() => pageId = id);
          Navigator.pop(context);
        },
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        child: KeyedSubtree(
          key: ValueKey(pageId),
          child: _page(auth),
        ),
      ),
    );
  }

  Widget _page(AuthState auth) {
    switch (pageId) {
      case 'v-classes':
        return const VestmentsScreen(section: VestmentsSection.classes);
      case 'v-events':
        return const VestmentsScreen(section: VestmentsSection.events);
      case 'v-clothes':
        return const VestmentsScreen(section: VestmentsSection.clothes);
      case 'v-dirty':
        return const VestmentsScreen(section: VestmentsSection.dirty);
      case 'i-returnable':
        return const InventoryScreen(section: InventorySection.returnable);
      case 'i-consumable':
        return const InventoryScreen(section: InventorySection.consumable);
      case 'i-issued':
        return const InventoryScreen(section: InventorySection.issued);
      case 'f-all':
        return const FinanceScreen();
      case 'f-income':
        return const FinanceScreen(typeFilter: 'INCOME');
      case 'f-expense':
        return const FinanceScreen(typeFilter: 'EXPENSE');
      case 'a-list':
        return const AuditScreen();
      case 'm-account':
        return const MoreScreen(section: MoreSection.account);
      case 'm-departments':
        return const MoreScreen(section: MoreSection.departments);
      case 'm-classes':
        return const MoreScreen(section: MoreSection.classes);
      case 'm-users':
        return const MoreScreen(section: MoreSection.users);
      default:
        return _StatsHome(onOpen: (id) => setState(() => pageId = id), admin: auth.isAdmin);
    }
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.pageId, required this.onSelect});
  final String pageId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  const AppLogo(size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.user?['fullName'] ?? S.appName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(S.roleLabel(auth.role), style: const TextStyle(color: AppTheme.seed, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _tile(AppNav.home, selected: pageId == AppNav.home.id),
                  ...AppNav.modules.where((m) => !m.adminOnly || auth.isAdmin).map((module) {
                    final kids = module.children.where((c) {
                      if (c.superOnly && !auth.isSuper) return false;
                      if (c.adminOnly && !auth.isAdmin) return false;
                      return true;
                    }).toList();
                    final open = AppNav.moduleFor(pageId) == module.id;
                    return Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: ValueKey('${module.id}-$open'),
                        initiallyExpanded: open,
                        leading: Icon(module.icon, color: open ? AppTheme.seed : AppTheme.muted),
                        title: Text(module.title, style: TextStyle(fontWeight: FontWeight.w800, color: open ? AppTheme.seed : AppTheme.ink)),
                        children: kids.map((c) => _tile(c, selected: pageId == c.id, indent: true)).toList(),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton.icon(
                onPressed: () => context.read<AuthState>().logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(S.logout),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(NavItem item, {required bool selected, bool indent = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(indent ? 12 : 8, 2, 8, 2),
      child: Material(
        color: selected ? AppTheme.blueSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          dense: true,
          leading: Icon(item.icon, color: selected ? AppTheme.seed : AppTheme.muted),
          title: Text(item.title, style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? AppTheme.seed : AppTheme.ink)),
          onTap: () => onSelect(item.id),
        ),
      ),
    );
  }
}

class _StatsHome extends StatefulWidget {
  const _StatsHome({required this.onOpen, required this.admin});
  final ValueChanged<String> onOpen;
  final bool admin;
  @override
  State<_StatsHome> createState() => _StatsHomeState();
}

class _StatsHomeState extends State<_StatsHome> {
  Map data = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<AuthState>().api.get('/dashboard');
      final raw = res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{};
      setState(() {
        data = {
          ...raw,
          'clothesOut': raw['clothesOut'] ?? raw['clothesOut'],
          'dirtyClothes': raw['dirtyClothes'] ?? raw['dirtyClothes'],
          'overdueClothes': raw['overdueClothes'] ?? raw['overdueClothes'],
          'returnableAssets': raw['returnableAssets'] ?? raw['returnableAssets'],
        };
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  int _n(String key) => (data[key] as num?)?.toInt() ?? 0;
  num _num(String key) => (data[key] as num?) ?? 0;

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    return RefreshIndicator(
      color: AppTheme.seed,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          FadeSlide(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, AppTheme.mist],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4EEFB)),
              ),
              child: Row(
                children: [
                  const AppLogo(size: 72, elevated: false),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(S.appName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        const Text(S.appSubtitle, style: TextStyle(color: AppTheme.muted)),
                        Text('ዛሬ · ${EthDate.now().label}', style: const TextStyle(color: AppTheme.seed, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader('አጠቃላይ ሪፖርት'),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              _stat('ተማሪዎች', _n('members'), Icons.people_alt_rounded, 'v-classes'),
              _stat('ምድቦች', _n('classes'), Icons.groups_rounded, 'v-classes'),
              _stat('ክፍሎች', _n('departments'), Icons.apartment_rounded, 'm-departments'),
              _stat('በዓላት', _n('events'), Icons.event_rounded, 'v-events'),
            ],
          ),
          const SectionHeader('ልብሰ ስብሐት'),
          _barCard('የወጣ ልብስ', _n('clothesOut'), _n('vestmentTotal'), AppTheme.seed, 'v-events'),
          _barCard('ቆሽሸው ያልተመለሱ', _n('dirtyClothes'), _n('clothesOut'), AppTheme.orange, 'v-dirty'),
          _barCard('ጊዜው ያለፈ', _n('overdueClothes'), _n('clothesOut'), const Color(0xFFB45309), 'v-dirty'),
          const SectionHeader('ንብረት'),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              _stat('ቋሚ ንብረት', _n('returnableAssets'), Icons.chair_alt_outlined, 'i-returnable'),
              _stat('አላቂ ንብረት', _n('consumableAssets'), Icons.inventory_2_outlined, 'i-consumable'),
              _stat('ያልተመለሰ ቋሚ', _n('openReturnableLoans'), Icons.outbox_rounded, 'i-issued'),
              _stat('ኦዲት', _n('audits'), Icons.fact_check_rounded, 'a-list'),
            ],
          ),
          if (widget.admin) ...[
            const SectionHeader('ፋይናንስ'),
            _money('ገቢ', _num('income'), AppTheme.seed, 'f-income'),
            _money('ወጪ', _num('expense'), AppTheme.orange, 'f-expense'),
            _money('የተጣራ', _num('net'), AppTheme.blue, 'f-all'),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon, String page) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => widget.onOpen(page),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE4EEFB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(backgroundColor: AppTheme.blueSoft, child: Icon(icon, color: AppTheme.seed)),
              const Spacer(),
              Text('$value', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.seed)),
              Text(label, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barCard(String label, int value, int total, Color color, String page) {
    final max = total <= 0 ? (value <= 0 ? 1 : value) : total;
    final t = (value / max).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        onTap: () => widget.onOpen(page),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
                  Text('$value', style: TextStyle(fontWeight: FontWeight.w900, color: color)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: t,
                  minHeight: 10,
                  color: color,
                  backgroundColor: AppTheme.blueSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _money(String label, num value, Color color, String page) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        onTap: () => widget.onOpen(page),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.16), child: Icon(Icons.payments_rounded, color: color)),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          trailing: Text('${value.toString()} ብር', style: TextStyle(fontWeight: FontWeight.w900, color: color)),
        ),
      ),
    );
  }
}
