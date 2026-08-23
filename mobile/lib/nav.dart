import 'package:flutter/material.dart';
import 'strings.dart';

class NavItem {
  const NavItem({
    required this.id,
    required this.title,
    required this.icon,
    this.adminOnly = false,
    this.superOnly = false,
    this.classLeaderOk = false,
  });
  final String id;
  final String title;
  final IconData icon;
  final bool adminOnly;
  final bool superOnly;
  final bool classLeaderOk;
}

class NavModule {
  const NavModule({
    required this.id,
    required this.title,
    required this.icon,
    required this.children,
    this.adminOnly = false,
    this.classLeaderOk = false,
  });
  final String id;
  final String title;
  final IconData icon;
  final List<NavItem> children;
  final bool adminOnly;
  final bool classLeaderOk;
}

class AppNav {
  static const home = NavItem(id: 'home', title: 'ሪፖርት', icon: Icons.bar_chart_rounded, classLeaderOk: true);

  static const modules = [
    NavModule(
      id: 'vestments',
      title: S.vestments,
      icon: Icons.checkroom_rounded,
      classLeaderOk: true,
      children: [
        NavItem(id: 'v-classes', title: S.classes, icon: Icons.groups_rounded, classLeaderOk: true),
        NavItem(id: 'v-events', title: S.events, icon: Icons.event_rounded, classLeaderOk: true),
        NavItem(id: 'v-clothes', title: S.vestments, icon: Icons.checkroom_outlined),
        NavItem(id: 'v-dirty', title: S.dirtyList, icon: Icons.local_laundry_service_outlined),
      ],
    ),
    NavModule(
      id: 'inventory',
      title: S.inventory,
      icon: Icons.inventory_2_rounded,
      children: [
        NavItem(id: 'i-returnable', title: S.returnable, icon: Icons.chair_alt_outlined),
        NavItem(id: 'i-consumable', title: S.consumable, icon: Icons.inventory_2_outlined),
        NavItem(id: 'i-issued', title: S.issuedItems, icon: Icons.outbox_rounded),
      ],
    ),
    NavModule(
      id: 'finance',
      title: S.finance,
      icon: Icons.payments_rounded,
      adminOnly: true,
      children: [
        NavItem(id: 'f-all', title: 'ማጠቃለያ', icon: Icons.account_balance_wallet_outlined, adminOnly: true),
        NavItem(id: 'f-income', title: S.income, icon: Icons.south_west_rounded, adminOnly: true),
        NavItem(id: 'f-expense', title: S.expense, icon: Icons.north_east_rounded, adminOnly: true),
      ],
    ),
    NavModule(
      id: 'audit',
      title: S.audit,
      icon: Icons.fact_check_rounded,
      children: [
        NavItem(id: 'a-list', title: 'የኦዲት ዝርዝር', icon: Icons.list_alt_rounded),
      ],
    ),
    NavModule(
      id: 'more',
      title: S.more,
      icon: Icons.settings_rounded,
      classLeaderOk: true,
      children: [
        NavItem(id: 'm-account', title: 'መገለጫ', icon: Icons.person_rounded, classLeaderOk: true),
        NavItem(id: 'm-departments', title: S.departments, icon: Icons.apartment_rounded),
        NavItem(id: 'm-classes', title: S.classes, icon: Icons.groups_rounded),
        NavItem(id: 'm-users', title: S.users, icon: Icons.manage_accounts_rounded, superOnly: true),
      ],
    ),
  ];

  static String titleFor(String id) {
    if (id == home.id) return home.title;
    for (final m in modules) {
      for (final c in m.children) {
        if (c.id == id) return c.title;
      }
    }
    return S.appName;
  }

  static String? moduleFor(String id) {
    for (final m in modules) {
      if (m.children.any((c) => c.id == id)) return m.id;
    }
    return null;
  }
}
