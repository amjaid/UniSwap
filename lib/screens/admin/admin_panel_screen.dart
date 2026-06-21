import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/screens/admin/admin_listings_tab.dart';
import 'package:uniswap/screens/admin/admin_users_tab.dart';
import 'package:uniswap/screens/admin/dashboard_tab.dart';

/// Admin panel screen with three tabs: Dashboard, Users, Listings.
///
/// Only accessible by users with `is_staff=True`. The router redirect
/// in routes.dart enforces this. This screen provides platform moderation
/// tools: view platform stats, manage users (soft-delete), manage listings
/// (soft-delete).
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.inventory_2), text: 'Listings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardTab(),
          AdminUsersTab(),
          AdminListingsTab(),
        ],
      ),
    );
  }
}
