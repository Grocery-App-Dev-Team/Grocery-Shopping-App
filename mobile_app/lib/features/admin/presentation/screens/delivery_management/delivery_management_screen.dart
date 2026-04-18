import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:intl/intl.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';

class DeliveryManagementScreen extends StatefulWidget {
  const DeliveryManagementScreen({super.key});

  @override
  State<DeliveryManagementScreen> createState() => _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState extends State<DeliveryManagementScreen> {
  final OrderService _orderService = OrderService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l.translate('nav_delivery'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          if (_searchQuery.isNotEmpty || _statusFilter != 'all')
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined, color: Colors.red),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _statusFilter = 'all';
                  _searchController.clear();
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.indigo),
            onPressed: _exportDeliveries,
            tooltip: 'Xuất Excel',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.byLocale(vi: 'Tìm theo Shipper, Mã đơn...', en: 'Search by Shipper, ID...'),
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _orderService.getAllOrdersAdmin(), // Switch to Admin API for full visibility
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }

          final allOrders = snapshot.data ?? [];
          var activeDeliveries = allOrders.where((o) {
            final st = (o.status ?? '').toUpperCase();
            return ['PICKING_UP', 'DELIVERING', 'DELIVERED', 'COMPLETED', 'DONE', 'SHIPPED'].contains(st);
          }).toList();

          // Apply Status Filter
          if (_statusFilter != 'all') {
            String apiStatus = '';
            if (_statusFilter == 'order_picking') apiStatus = 'PICKING_UP';
            if (_statusFilter == 'order_delivering') apiStatus = 'DELIVERING';
            if (_statusFilter == 'order_delivered') apiStatus = 'DELIVERED';
            activeDeliveries = activeDeliveries.where((o) => o.status == apiStatus).toList();
          }

          // Apply Search Filter
          if (_searchQuery.isNotEmpty) {
            activeDeliveries = activeDeliveries.where((o) {
              final idStr = (o.id?.toString() ?? '').toLowerCase();
              final shipper = (o.shipperName ?? 'Chưa chỉ định').toLowerCase();
              return idStr.contains(_searchQuery) || shipper.contains(_searchQuery);
            }).toList();
          }

          if (activeDeliveries.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildDeliveryStats(allOrders.where((o) {
                final st = (o.status ?? '').toUpperCase();
                return ['PICKING_UP', 'DELIVERING', 'DELIVERED', 'COMPLETED', 'DONE', 'SHIPPED'].contains(st);
              }).toList()),
              _buildFilterChips(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeDeliveries.length,
                  itemBuilder: (context, index) => _buildDeliveryCard(activeDeliveries[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeliveryStats(List<OrderModel> deliveries) {
    final l = AppLocalizations.of(context)!;
    final delivering = deliveries.where((o) => (o.status ?? '').toUpperCase() == 'DELIVERING').length;
    final picking = deliveries.where((o) => (o.status ?? '').toUpperCase() == 'PICKING_UP').length;
    final completed = deliveries.where((o) {
      final st = (o.status ?? '').toUpperCase();
      return ['DELIVERED', 'COMPLETED', 'DONE'].contains(st);
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(l.translate('order_picking'), picking.toString(), Icons.move_to_inbox, Colors.orange, 'order_picking'),
          _buildStatItem(l.translate('order_delivering'), delivering.toString(), Icons.delivery_dining, Colors.blue, 'order_delivering'),
          _buildStatItem(l.translate('order_delivered'), completed.toString(), Icons.check_circle_outline, Colors.green, 'order_delivered'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color, String filterKey) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = _statusFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = isSelected ? 'all' : filterKey),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? color : color.withValues(alpha: 0.4), size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey)),
          Text(title, style: TextStyle(fontSize: 11, color: isSelected ? color : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          'Tất cả', 'Chờ lấy', 'Đang giao', 'Hoàn tất'
        ].map((filter) {
          bool isSelected = _statusFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              onSelected: (val) => setState(() => _statusFilter = filter),
              selectedColor: Colors.indigo,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.indigo : Colors.grey[300]!)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeliveryCard(OrderModel order) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildDeliveryStatusIcon(order.status ?? 'PENDING'),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final String idStr = order.id?.toString() ?? '';
                          final String displayId = idStr.length > 6 ? idStr.substring(idStr.length - 6) : idStr.padLeft(6, '0');
                          return Text('${l.byLocale(vi: 'Đơn', en: 'Order')} #${displayId.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15));
                        },
                      ),
                      Text('${l.byLocale(vi: 'Khách hàng', en: 'Customer')}: ${order.customerName ?? l.byLocale(vi: "Khách lẻ", en: "Guest")}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                _buildSmallStatusBadge(order.status ?? 'PENDING'),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.indigo),
                const SizedBox(width: 12),
                Expanded(child: Text(order.address ?? l.byLocale(vi: "Không có địa chỉ", en: "No address"), style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.black87), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_pin_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 12),
                Text('${l.byLocale(vi: 'Tài xế', en: 'Shipper')}: ${order.shipperName ?? l.byLocale(vi: "Chưa chỉ định", en: "Unassigned")}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                Text('${l.byLocale(vi: 'Dự kiến', en: 'ETA')}: 15${l.byLocale(vi: 'p', en: 'm')}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                double progress = 0.0;
                if (order.status == 'PICKING_UP') progress = 0.3;
                if (order.status == 'DELIVERING') progress = 0.7;
                if (order.status == 'DELIVERED') progress = 1.0;
                return LinearProgressIndicator(
                  value: progress, 
                  backgroundColor: const Color(0xFFF0F2F5), 
                  valueColor: AlwaysStoppedAnimation<Color>(progress == 1.0 ? Colors.green : Colors.indigo),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (order.status != 'DELIVERED')
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: Text(l.byLocale(vi: 'Liên hệ', en: 'Contact'), style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.teal),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  child: Text(l.byLocale(vi: 'Xem lộ trình', en: 'Track Path'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStatusIcon(String status) {
     IconData icon = Icons.local_shipping;
     Color color = Colors.indigo;
     final st = status.toUpperCase();
     if (st == 'PICKING_UP') { icon = Icons.warehouse_outlined; color = Colors.orange; }
     if (['DELIVERED', 'COMPLETED', 'DONE'].contains(st)) { icon = Icons.verified_user_outlined; color = Colors.green; }
     
     return Container(
       padding: const EdgeInsets.all(10),
       decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
       child: Icon(icon, color: color, size: 22),
     );
  }

  Widget _buildSmallStatusBadge(String status) {
    final l = AppLocalizations.of(context)!;
    Color color = Colors.grey;
    String text = status;
    final st = status.toUpperCase();
    if (st == 'PICKING_UP') { color = Colors.orange; text = l.translate('order_picking'); }
    if (st == 'DELIVERING') { color = Colors.blue; text = l.translate('order_delivering'); }
    if (['DELIVERED', 'COMPLETED', 'DONE'].contains(st)) { color = Colors.green; text = l.translate('order_delivered'); }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _exportDeliveries() async {
    try {
      final List<OrderModel> allOrders = await _orderService.getStoreOrders();
      final activeDeliveries = allOrders.where((o) => 
        ['PICKING_UP', 'DELIVERING', 'DELIVERED'].contains(o.status)
      ).toList();
      
      final exportData = activeDeliveries.map((o) => {
        'Mã đơn': (o.id?.toString() ?? '').toUpperCase(),
        'Shipper': o.shipperName ?? 'Chưa chỉ định',
        'Khách hàng': o.customerName ?? 'N/A',
        'Địa chỉ': o.address ?? 'N/A',
        'Trạng thái': _getStatusText(o.status ?? ''),
        'Cập nhật': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), // Mocking last update
      }).toList();

      if (mounted) {
        await ExportService.exportToCsv(
          context: context,
          data: exportData,
          fileName: 'danhsach_vanchuyen_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất dữ liệu: $e')));
      }
    }
  }

  String _getStatusText(String status) {
    if (status == 'PICKING_UP') return 'Chờ lấy';
    if (status == 'DELIVERING') return 'Đang giao';
    if (status == 'DELIVERED') return 'Hoàn tất';
    return status;
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Không có hoạt động vận chuyển nào', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
