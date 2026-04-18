import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/features/auth/models/user_model.dart';
import 'package:grocery_shopping_app/features/admin/domain/repositories/user_repository.dart';
import 'package:grocery_shopping_app/features/admin/data/repositories/api_user_repository_impl.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/user_management/user_detail_screen.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';
import 'package:intl/intl.dart';

import 'package:grocery_shopping_app/core/utils/app_localizations.dart';

class ShipperManagementScreen extends StatefulWidget {
  const ShipperManagementScreen({super.key});

  @override
  State<ShipperManagementScreen> createState() => _ShipperManagementScreenState();
}

class _ShipperManagementScreenState extends State<ShipperManagementScreen> {
  final UserRepository _userRepository = ApiUserRepositoryImpl();
  final OrderService _orderService = OrderService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l.translate('mgmt_shippers'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.indigo),
            onPressed: () => _exportShippers(context),
            tooltip: 'Export CSV',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: l.translate('search_hint'),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F2F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _userRepository.getUsers(role: UserRole.shipper),
          _orderService.getAllOrdersAdmin(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }

          final shippers = snapshot.data?[0] as List<UserModel>? ?? [];
          final allOrders = snapshot.data?[1] as List<OrderModel>? ?? [];
          
          final filteredShippers = shippers.where((s) => 
            s.fullName.toLowerCase().contains(_searchQuery) || s.phoneNumber.contains(_searchQuery)
          ).toList();

          final int onlineCount = shippers.where((s) => s.status == UserStatus.active).length;
          
          double totalSystemRevenue = 0.0;
          for (var order in allOrders) {
            if (['DELIVERED', 'COMPLETED', 'Hoàn thành'].contains(order.status)) {
              totalSystemRevenue += (order.shippingFee ?? 0.0);
            }
          }

          return Column(
            children: [
              _buildStatsHeader(shippers.length, onlineCount, totalSystemRevenue, l),
              Expanded(
                child: filteredShippers.isEmpty 
                  ? _buildEmptyState(l)
                  : RefreshIndicator(
                      onRefresh: () async => setState(() {}),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredShippers.length,
                        itemBuilder: (context, index) {
                          final shipper = filteredShippers[index];
                          final shipperOrders = allOrders.where((o) => o.shipperId.toString() == shipper.id).toList();
                          final completedCount = shipperOrders.where((o) => ['DELIVERED', 'COMPLETED', 'Hoàn thành'].contains(o.status)).length;
                          final earnings = shipperOrders.where((o) => ['DELIVERED', 'COMPLETED', 'Hoàn thành'].contains(o.status))
                              .fold(0.0, (sum, o) => sum + (o.shippingFee ?? 0.0));

                          return _buildShipperCard(shipper, completedCount, earnings, l);
                        },
                      ),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(int total, int online, double revenue, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(l.translate('nav_shippers'), total.toString(), Icons.group),
          _buildStatItem(l.translate('active'), online.toString(), Icons.online_prediction, color: Colors.green),
          _buildStatItem(l.translate('revenue'), _currencyFormat.format(revenue), Icons.account_balance_wallet, color: Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, {Color color = Colors.grey}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildShipperCard(UserModel shipper, int completedOrders, double earnings, AppLocalizations l) {
    final bool isOnline = shipper.status == UserStatus.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      child: Text(shipper.fullName.isNotEmpty ? shipper.fullName.substring(0, 1) : 'S', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).cardColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shipper.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(shipper.phoneNumber, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                _buildLockIndicator(shipper.status, l),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat('Orders', completedOrders.toString(), Icons.local_mall_outlined),
                _buildMiniStat('Earnings', _currencyFormat.format(earnings), Icons.account_balance_wallet_outlined),
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserDetailScreen(user: shipper)),
                    );
                    if (mounted) setState(() {});
                  },
                  child: Text(l.translate('detail_user').split(' ')[0], style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildLockIndicator(UserStatus status, AppLocalizations l) {
    final bool active = status == UserStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(active ? l.translate('active') : l.translate('inactive'), style: TextStyle(color: active ? Colors.green[700] : Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(AppLocalizations l) {
    return Center(child: Text(l.translate('no_data'), style: const TextStyle(color: Colors.grey)));
  }

  void _exportShippers(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    try {
      final List<UserModel> shippers = await _userRepository.getUsers(role: UserRole.shipper);
      
      final exportData = shippers.map((s) => {
        'ID': s.id,
        'Name': s.fullName,
        'Phone': s.phoneNumber,
        'Status': s.status == UserStatus.active ? l.translate('active') : l.translate('inactive'),
        'Joined Date': DateFormat('dd/MM/yyyy').format(s.createdAt),
      }).toList();

      if (mounted) {
        await ExportService.exportToCsv(
          context: context,
          data: exportData,
          fileName: 'danhsach_shipper_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất dữ liệu: ${e.toString().replaceAll('Exception: ', '')}')));
      }
    }
  }
}
