import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'vestments_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key, this.section = MoreSection.account});
  final MoreSection section;
  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

enum MoreSection { account, departments, classes, users }

class _MoreScreenState extends State<MoreScreen> {
  List departments = [];
  List classes = [];
  List users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthState>();
    if (auth.isClassLeader) {
      setState(() {
        departments = [];
        classes = [];
        users = [];
        loading = false;
      });
      return;
    }
    final api = auth.api;
    final calls = [
      api.get('/departments'),
      api.get('/groups'),
    ];
    if (auth.isSuper) calls.add(api.get('/users'));
    final res = await Future.wait(calls);
    setState(() {
      departments = res[0];
      classes = res[1];
      users = res.length > 2 ? res[2] : [];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (loading) return const LoadingView();
    final section = widget.section;

    VoidCallback? onCreate;
    String createLabel = S.add;
    IconData createIcon = Icons.add_rounded;
    if (section == MoreSection.departments && auth.isAdmin) {
      onCreate = _addDept;
    } else if (section == MoreSection.classes && auth.isAdmin) {
      onCreate = _addClass;
      createLabel = S.addClass;
    } else if (section == MoreSection.users && auth.isSuper) {
      onCreate = _addUser;
      createIcon = Icons.person_add_alt;
    }

    final body = ListView(
      children: [
        if (section == MoreSection.account) ...[
          FadeSlide(
            child: SoftCard(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.blueSoft,
                  child: Icon(Icons.person_rounded, color: AppTheme.seed),
                ),
                title: Text(auth.user?['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${auth.user?['username']} · ${S.roleLabel(auth.role)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppTheme.seed),
                  onPressed: _editProfile,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => context.read<AuthState>().logout(),
              icon: const Icon(Icons.logout),
              label: const Text(S.logout),
            ),
          ),
        ],
        if (section == MoreSection.departments) ...[
          const SectionHeader(S.departments),
          if (departments.isEmpty) const EmptyBox('ክፍል የለም'),
          ...departments.map((d) => SoftCard(
                child: ListTile(
                  title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(d['head'] ?? ''),
                  trailing: auth.isAdmin
                      ? PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') _editDept(d as Map);
                            if (v == 'delete') _deleteDept(d as Map);
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
        if (section == MoreSection.classes) ...[
          const SectionHeader(S.classes),
          if (classes.isEmpty) const EmptyBox('አዲስ ምድብ ይፍጠሩ፤ ከዚያ ተማሪዎችን ያክሉ'),
          ...classes.map((g) {
            final count = ((g['members'] as List?) ?? []).length;
            return SoftCard(
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (auth.isAdmin)
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _editClass(g as Map);
                              if (v == 'delete') _deleteClass(g as Map);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text(S.edit)),
                              PopupMenuItem(value: 'delete', child: Text(S.remove)),
                            ],
                          ),
                        const Icon(Icons.chevron_right_rounded, color: AppTheme.seed),
                      ],
                    ),
              ),
            );
          }),
        ],
        if (section == MoreSection.users && auth.isSuper) ...[
          const SectionHeader(S.users),
          ...users.map((u) => SoftCard(
                child: ListTile(
                  title: Text(u['fullName']),
                  subtitle: Text('${u['username']} · ${S.roleLabel(u['role'])}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _editUser(u as Map);
                      if (v == 'toggle') _toggleUser(u as Map);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text(S.edit)),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(u['isActive'] == true ? 'Disable' : 'Enable'),
                      ),
                    ],
                  ),
                ),
              )),
        ],
        if (onCreate != null) createFabScrollPad else const SizedBox(height: 24),
      ],
    );

    return CreateFabLayout(
      onCreate: onCreate,
      label: createLabel,
      icon: createIcon,
      body: body,
    );
  }

  Future<void> _editProfile() async {
    final auth = context.read<AuthState>();
    final name = TextEditingController(text: auth.user?['fullName']?.toString() ?? '');
    final pass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('መገለጫ አስተካክል'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'ሙሉ ስም')),
            const SizedBox(height: 8),
            TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'አዲስ የይለፍ ቃል (ከተፈለገ)')),
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
      final body = <String, dynamic>{};
      if (name.text.trim().isNotEmpty) body['fullName'] = name.text.trim();
      if (pass.text.isNotEmpty) body['password'] = pass.text;
      await auth.api.patch('/auth/profile', body);
      await auth.refreshUser();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }

  Future<void> _editUser(Map u) async {
    final name = TextEditingController(text: u['fullName']?.toString() ?? '');
    final username = TextEditingController(text: u['username']?.toString() ?? '');
    final password = TextEditingController();
    bool showPassword = false;
    String role = '${u['role'] ?? 'USER'}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text(S.edit),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'ሙሉ ስም')),
                const SizedBox(height: 8),
                TextField(
                  controller: username,
                  decoration: const InputDecoration(labelText: 'የተጠቃሚ ስም'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: password,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: 'አዲስ የይለፍ ቃል (ከተፈለገ)',
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setS(() => showPassword = !showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'SUPER_ADMIN', child: Text(S.superAdmin)),
                    DropdownMenuItem(value: 'ADMIN', child: Text(S.admin)),
                    DropdownMenuItem(value: 'CLASS_LEADER', child: Text(S.classLeader)),
                    DropdownMenuItem(value: 'USER', child: Text(S.user)),
                  ],
                  onChanged: (v) => setS(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (username.text.trim().isEmpty) {
      showMsg(context, 'የተጠቃሚ ስም ያስፈልጋል', error: true);
      return;
    }
    if (password.text.isNotEmpty && password.text.length < 6) {
      showMsg(context, 'የይለፍ ቃል ቢያንስ 6 ቁምፊ', error: true);
      return;
    }
    try {
      final body = <String, dynamic>{
        'fullName': name.text.trim(),
        'username': username.text.trim(),
        'role': role,
      };
      if (password.text.isNotEmpty) body['password'] = password.text;
      await context.read<AuthState>().api.patch('/users/${jsonInt(u['id'])}', body);
      _load();
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
    }
  }

  Future<void> _toggleUser(Map u) async {
    try {
      await context.read<AuthState>().api.patch('/users/${jsonInt(u['id'])}', {
        'isActive': u['isActive'] != true,
      });
      _load();
    } catch (e) {
      if (mounted) showMsg(context, e.toString(), error: true);
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
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClassDetailPage(group: created)),
      );
      _load();
    }
  }

  Future<void> _addDept() async {
    final name = TextEditingController();
    final head = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ክፍል ፍጠር'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'የክፍል ስም')),
            TextField(controller: head, decoration: const InputDecoration(labelText: 'ኃላፊ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.save)),
        ],
      ),
    );
    if (ok == true) {
      await context.read<AuthState>().api.post('/departments', {'name': name.text, 'head': head.text});
      _load();
    }
  }

  Future<void> _editDept(Map d) async {
    final name = TextEditingController(text: d['name']?.toString() ?? '');
    final head = TextEditingController(text: d['head']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'የክፍል ስም')),
            TextField(controller: head, decoration: const InputDecoration(labelText: 'ኃላፊ')),
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
        await context.read<AuthState>().api.patch('/departments/${jsonInt(d['id'])}', {
          'name': name.text.trim(),
          'head': head.text.trim(),
        });
        _load();
      } catch (e) {
        if (mounted) showMsg(context, e.toString(), error: true);
      }
    }
  }

  Future<void> _deleteDept(Map d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.remove),
        content: Text('${d['name'] ?? ''} ይወገድ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.remove)),
        ],
      ),
    );
    if (ok == true) {
      try {
        await context.read<AuthState>().api.delete('/departments/${jsonInt(d['id'])}');
        _load();
      } catch (e) {
        if (mounted) showMsg(context, e.toString(), error: true);
      }
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.remove),
        content: Text('${g['name'] ?? ''} ይወገድ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.remove)),
        ],
      ),
    );
    if (ok == true) {
      try {
        await context.read<AuthState>().api.delete('/groups/${jsonInt(g['id'])}');
        _load();
      } catch (e) {
        if (mounted) showMsg(context, e.toString(), error: true);
      }
    }
  }

  Future<void> _addUser() async {
    final name = TextEditingController();
    final username = TextEditingController();
    final password = TextEditingController();
    String role = 'ADMIN';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('ተጠቃሚ ፍጠር'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'ሙሉ ስም')),
              TextField(controller: username, decoration: const InputDecoration(labelText: S.username)),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: S.password)),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'SUPER_ADMIN', child: Text(S.superAdmin)),
                  DropdownMenuItem(value: 'ADMIN', child: Text(S.admin)),
                  DropdownMenuItem(value: 'CLASS_LEADER', child: Text(S.classLeader)),
                  DropdownMenuItem(value: 'USER', child: Text(S.user)),
                ],
                onChanged: (v) => setS(() => role = v!),
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
      try {
        await context.read<AuthState>().api.post('/users', {
          'fullName': name.text,
          'username': username.text,
          'password': password.text,
          'role': role,
        });
        _load();
      } catch (e) {
        if (mounted) showMsg(context, e.toString(), error: true);
      }
    }
  }
}
