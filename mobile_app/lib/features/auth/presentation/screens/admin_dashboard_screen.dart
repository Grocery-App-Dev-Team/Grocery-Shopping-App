import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_shopping_app/features/auth/bloc/auth_bloc.dart';
import 'package:grocery_shopping_app/features/auth/bloc/auth_event.dart';
import 'package:grocery_shopping_app/features/auth/bloc/auth_state.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/user_management/user_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/store_management/store_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/shipper_management/shipper_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/order_management/order_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/delivery_management/delivery_management_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/settings/settings_screen.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/settings/settings_screen.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/core/utils/logger.dart';
import 'package:grocery_shopping_app/features/auth/models/user_model.dart';

import '../../../../core/utils/app_localizations.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    
    // Move navItems here to ensure Hot Reload updates the list
    final List<Map<String, dynamic>> navItems = [
      {'title': 'nav_orders', 'icon': Icons.receipt_long_outlined, 'activeIcon': Icons.receipt_long},
      {'title': 'nav_users', 'icon': Icons.people_outline, 'activeIcon': Icons.people},
      {'title': 'nav_stores', 'icon': Icons.storefront_outlined, 'activeIcon': Icons.storefront},
      {'title': 'nav_shippers', 'icon': Icons.local_shipping_outlined, 'activeIcon': Icons.local_shipping},
      {'title': 'nav_delivery', 'icon': Icons.delivery_dining_outlined, 'activeIcon': Icons.delivery_dining},
      {'title': 'nav_settings', 'icon': Icons.settings_outlined, 'activeIcon': Icons.settings},
    ];

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isLargeScreen = constraints.maxWidth > 900;
                
                return Scaffold(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  body: Row(
                    children: [
                      if (isLargeScreen) _buildSidebar(navItems),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _currentIndex = index),
                          children: [
                            const OrderManagementScreen(),
                            const UserManagementScreen(),
                            const StoreManagementScreen(),
                            const ShipperManagementScreen(),
                            const DeliveryManagementScreen(),
                            const SettingsScreen(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: isLargeScreen ? null : _buildBottomNav(navItems),
                );
              },
            );
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }

  Widget _buildSidebar(List<Map<String, dynamic>> navItems) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.shield, color: Colors.indigo, size: 24),
                ),
                const SizedBox(width: 12),
                Text(l.translate('app_title').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = _currentIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: ListTile(
                    onTap: () => _onTabTapped(index),
                    selected: isSelected,
                    leading: Icon(isSelected ? item['activeIcon'] : item['icon'], color: isSelected ? Colors.indigo : Colors.grey[600]),
                    title: Text(l.translate(item['title']), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.indigo : (isDark ? Colors.grey[400] : Colors.grey[700]), fontSize: 13)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    selectedTileColor: Colors.indigo.withValues(alpha: 0.08),
                    dense: true,
                  ),
                );
              },
            ),
          ),
          // Sidebar Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundColor: Colors.orange, child: Icon(Icons.person, size: 16, color: isDark ? Colors.black : Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Text(l.translate('nav_settings'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: Text(l.translate('settings_logout') + '?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.translate('all'))),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.read<AuthBloc>().add(const LogoutRequested());
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: Text(l.translate('settings_logout')),
                          ),
                        ],
                      ),
                    );
                  }, 
                  icon: const Icon(Icons.logout, size: 18, color: Colors.grey)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(List<Map<String, dynamic>> navItems) {
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 72,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  final isSelected = _currentIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _onTabTapped(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.indigo.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item['activeIcon'] : item['icon'],
                              color: isSelected ? Colors.indigo : Colors.grey[500],
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.translate(item['title']),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.indigo : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
