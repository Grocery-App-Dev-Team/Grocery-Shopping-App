import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:intl/intl.dart';
import 'add_edit_order_screen.dart';
import 'order_detail_screen.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final OrderService _orderService = OrderService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  String _selectedStatus = 'Tất cả';

  final List<String> _statuses = [
    'all',
    'order_pending',
    'order_delivering',
    'order_delivered',
    'order_cancelled',
  ];

  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  List<OrderModel> _orders = [];
  
  // Filtering & Sorting State
  String _sortBy = 'createdAt';
  String _sortDir = 'desc';
  int? _filterStoreId;

  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadOrders();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isSyncing &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreOrders();
    }
  }

  Future<void> _loadOrders() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
      _currentPage = 0;
      _hasMoreData = true;
      _orders = [];
    });

    try {
      String? apiStatus;
      if (_selectedStatus == 'order_pending') apiStatus = 'PENDING';
      if (_selectedStatus == 'order_delivering') apiStatus = 'DELIVERING';
      if (_selectedStatus == 'order_delivered') apiStatus = 'DELIVERED';
      if (_selectedStatus == 'order_cancelled') apiStatus = 'CANCELLED';

      final results = await _orderService.getAllOrdersAdmin(
        page: _currentPage,
        size: _pageSize,
        sortBy: _sortBy,
        sortDir: _sortDir,
        storeId: _filterStoreId,
        status: apiStatus,
        from: _dateRange?.start.toIso8601String(),
        to: _dateRange?.end.toIso8601String(),
      );

      if (mounted) {
        setState(() {
          _orders = results;
          _hasMoreData = results.length >= _pageSize;
          _isSyncing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      
      String? apiStatus;
      if (_selectedStatus == 'order_pending') apiStatus = 'PENDING';
      if (_selectedStatus == 'order_delivering') apiStatus = 'DELIVERING';
      if (_selectedStatus == 'order_delivered') apiStatus = 'DELIVERED';
      if (_selectedStatus == 'order_cancelled') apiStatus = 'CANCELLED';

      final results = await _orderService.getAllOrdersAdmin(
        page: _currentPage,
        size: _pageSize,
        sortBy: _sortBy,
        sortDir: _sortDir,
        storeId: _filterStoreId,
        status: apiStatus,
        from: _dateRange?.start.toIso8601String(),
        to: _dateRange?.end.toIso8601String(),
      );

      if (mounted) {
        setState(() {
          _orders.addAll(results);
          _hasMoreData = results.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddEdit({OrderModel? order}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditOrderScreen(order: order)),
    );
    if (result == true) {
      _loadOrders();
    }
  }

  void _navigateToDetail(OrderModel order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order)),
    );
    if (result == true) {
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l.translate('mgmt_orders'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _filterStoreId != null || _sortBy != 'createdAt' || _sortDir != 'desc',
              child: const Icon(Icons.filter_list, color: Colors.indigo),
            ),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: _isSyncing ? Colors.grey : Colors.indigo),
            onPressed: _loadOrders,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.translate('search_hint'),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sort, size: 20, color: Colors.indigo),
                        onPressed: _showFilterSheet,
                        tooltip: 'Sắp xếp & Bộ lọc',
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, size: 18, color: Colors.indigo),
                        onPressed: _selectDateRange,
                        tooltip: 'Chọn ngày',
                      ),
                    ],
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
        ),
      ),
      body: _buildOrderList(l),
    );
  }

  Widget _buildStatusDropdown(AppLocalizations l, [StateSetter? setSheetState]) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo, size: 20),
          style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12),
          onChanged: (String? newValue) {
            if (newValue != null) {
              if (setSheetState != null) {
                setSheetState(() => _selectedStatus = newValue);
              } else {
                setState(() => _selectedStatus = newValue);
                _loadOrders();
              }
            }
          },
          items: _statuses.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(l.translate(value)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderList(AppLocalizations l) {
    if (_isSyncing && _orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.indigo),
            const SizedBox(height: 16),
            Text('Đang tải danh sách...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    List<OrderModel> filteredOrders = _orders;

    // Combine Client-side Search with Server-side Filtering
    if (_searchQuery.isNotEmpty) {
      filteredOrders = filteredOrders.where((o) {
        final id = (o.id?.toString() ?? '').toLowerCase();
        final customer = (o.customerName ?? '').toLowerCase();
        final store = (o.storeName ?? '').toLowerCase();
        final shipper = (o.shipperName ?? '').toLowerCase();
        return id.contains(_searchQuery) || customer.contains(_searchQuery) || store.contains(_searchQuery) || shipper.contains(_searchQuery);
      }).toList();
    }

    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredOrders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _buildOrderCard(filteredOrders[index], l);
        },
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadOrders();
    }
  }

  void _showFilterSheet() {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.byLocale(vi: 'Bộ lọc & Sắp xếp', en: 'Filters & Sorting'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              Text(l.translate('status'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedStatus == 'Tất cả' ? 'ALL' : _selectedStatus,
                decoration: _filterDecoration(Icons.filter_list),
                items: [
                  DropdownMenuItem(value: 'ALL', child: Text(l.translate('all'))),
                  DropdownMenuItem(value: 'PENDING', child: Text(l.translate('order_pending'))),
                  DropdownMenuItem(value: 'CONFIRMED', child: Text(l.translate('order_confirmed'))),
                  DropdownMenuItem(value: 'PICKING_UP', child: Text(l.translate('order_picking'))),
                  DropdownMenuItem(value: 'DELIVERING', child: Text(l.translate('order_delivering'))),
                  DropdownMenuItem(value: 'DELIVERED', child: Text(l.translate('order_delivered'))),
                  DropdownMenuItem(value: 'CANCELLED', child: Text(l.translate('order_cancelled'))),
                ],
                onChanged: (val) => setSheetState(() => _selectedStatus = (val == 'ALL' ? 'Tất cả' : val!)),
              ),
              const SizedBox(height: 20),
              Text(l.translate('sort_by'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: _filterDecoration(Icons.sort),
                items: [
                  DropdownMenuItem(value: 'createdAt', child: Text(l.translate('newest'))),
                  DropdownMenuItem(value: 'totalAmount', child: Text(l.translate('high_to_low'))),
                ],
                onChanged: (val) => setSheetState(() => _sortBy = val!),
              ),
              const SizedBox(height: 20),
              Text(l.byLocale(vi: 'Thứ tự', en: 'Order Direction'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(l.byLocale(vi: 'Giảm dần', en: 'DESC')),
                      selected: _sortDir == 'desc',
                      onSelected: (val) => setSheetState(() => _sortDir = 'desc'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(l.byLocale(vi: 'Tăng dần', en: 'ASC')),
                      selected: _sortDir == 'asc',
                      onSelected: (val) => setSheetState(() => _sortDir = 'asc'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(l.byLocale(vi: 'ID Cửa hàng', en: 'Store ID'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Nhập ID cửa hàng...',
                  prefixIcon: const Icon(Icons.storefront),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: _filterStoreId?.toString() ?? ''),
                onChanged: (val) => _filterStoreId = int.tryParse(val),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadOrders();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l.translate('save')),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    setSheetState(() {
                      _selectedStatus = 'Tất cả';
                      _sortBy = 'createdAt';
                      _sortDir = 'desc';
                      _filterStoreId = null;
                      _dateRange = null;
                    });
                  },
                  child: Text(l.byLocale(vi: 'Đặt lại tất cả', en: 'Reset All'), style: const TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({required String label, required bool selected, required Function(bool) onSelected}) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.indigo.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: selected ? Colors.indigo : Colors.grey[600], fontWeight: selected ? FontWeight.bold : FontWeight.normal),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selected ? Colors.indigo : Colors.grey[300]!)),
    );
  }

  Widget _buildOrderCard(OrderModel order, AppLocalizations l) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l.byLocale(vi: 'Đơn hàng', en: 'Order')} #${order.id?.toString().toUpperCase().characters.takeLast(6) ?? "N/A"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(order.createdAt ?? '') ?? DateTime.now()),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status ?? 'PENDING', l),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person_outline, '${l.byLocale(vi: 'Khách', en: 'Customer')}: ${order.customerName ?? "N/A"}'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.storefront_outlined, '${l.byLocale(vi: 'Cửa hàng', en: 'Store')}: ${order.storeName ?? "N/A"}'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.local_shipping_outlined, '${l.byLocale(vi: 'Tài xế', en: 'Shipper')}: ${order.shipperName ?? l.byLocale(vi: 'Chưa nhận', en: 'Not assigned')}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${l.byLocale(vi: 'Tổng thanh toán', en: 'Grand Total')}:', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 13)),
                Text(_currencyFormat.format(order.totalAmount ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _navigateToDetail(order),
                  icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.indigo),
                  tooltip: 'Xem chi tiết',
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildInfoRow(IconData icon, String text, {bool isGrey = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(
              fontSize: 12, 
              color: isGrey ? Colors.grey : Theme.of(context).textTheme.bodyMedium?.color, 
              fontWeight: isGrey ? FontWeight.normal : FontWeight.w500
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations l) {
    Color color = Colors.grey;
    String text = status;
    if (status == 'PENDING') { color = Colors.orange; text = l.translate('order_pending'); }
    if (status == 'CONFIRMED') { color = Colors.blue; text = l.translate('order_confirmed'); }
    if (status == 'PICKING_UP') { color = Colors.indigo; text = l.translate('order_picking'); }
    if (status == 'DELIVERING') { color = Colors.purple; text = l.translate('order_delivering'); }
    if (status == 'DELIVERED') { color = Colors.green; text = l.translate('order_delivered'); }
    if (status == 'CANCELLED') { color = Colors.red; text = l.translate('order_cancelled'); }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // ignore: unused_element
  void _exportOrders() async {
    try {
      final List<OrderModel> orders = await _orderService.getAllOrdersAdmin();
      
      final exportData = orders.map((o) => {
        'Mã đơn': o.id?.toString().toUpperCase() ?? 'N/A',
        'Ngày đặt': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(o.createdAt ?? '') ?? DateTime.now()),
        'Khách hàng': o.customerName ?? 'N/A',
        'Cửa hàng': o.storeName ?? 'N/A',
        'Shipper': o.shipperName ?? 'Chưa nhận',
        'Trạng thái': _getStatusText(o.status ?? 'PENDING'),
        'Tổng tiền': _currencyFormat.format(o.totalAmount ?? 0),
      }).toList();

      if (mounted) {
        await ExportService.exportToCsv(
          context: context,
          data: exportData,
          fileName: 'danhsach_donhang_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất dữ liệu: $e')));
      }
    }
  }

  String _getStatusText(String status) {
    if (status == 'PENDING') return 'Chờ xử lý';
    if (status == 'CONFIRMED') return 'Đã xác nhận';
    if (status == 'PICKING_UP') return 'Chờ lấy';
    if (status == 'DELIVERING') return 'Đang giao';
    if (status == 'DELIVERED') return 'Hoàn thành';
    if (status == 'CANCELLED') return 'Đã hủy';
    return status;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.translate('no_data'), style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  InputDecoration _filterDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.indigo, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
