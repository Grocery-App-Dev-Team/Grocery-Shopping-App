import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../data/repositories/api_store_repository_impl.dart';
import 'package:grocery_shopping_app/features/products/data/product_service.dart';
import 'package:grocery_shopping_app/features/products/data/product_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:grocery_shopping_app/core/api/upload_service.dart';
import 'package:grocery_shopping_app/core/api/api_routes.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';
import '../../widgets/address_selection_2_dropdowns.dart';

class StoreDetailScreen extends StatefulWidget {
  final Map<String, dynamic> store;

  const StoreDetailScreen({super.key, required this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final StoreRepository _storeRepository = ApiStoreRepositoryImpl();
  late Map<String, dynamic> _store;
  bool _isLoading = false;

  final _productService = ProductService();
  final _orderService = OrderService();
  final _uploadService = UploadService();
  final _picker = ImagePicker();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  
  List<ProductModel> _products = <ProductModel>[];
  List<OrderModel> _storeOrders = <OrderModel>[];
  bool _isProductsLoading = false;
  bool _isOrdersLoading = false;
  bool _isScanning = false;
  double _totalMonthlyRevenue = 0;
  List<double> _weeklyRevenue = [0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _store = Map<String, dynamic>.from(widget.store);
    _products = []; // Explicit re-init
    _loadStoreData();
    _loadProducts();
    _loadStoreOrders();
  }

  Future<void> _loadStoreData() async {
    if (!mounted) return;
    try {
      final storeId = _store['id']?.toString() ?? '';
      if (storeId.isNotEmpty) {
        final detailedStore = await _storeRepository.getStoreById(storeId);
        if (mounted) {
          setState(() {
            _store = detailedStore;
          });
        }
      }
    } catch (e) {
      // Failed to load detailed store info
    }
  }

  Future<void> _loadStoreOrders({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isOrdersLoading = true;
      if (forceRefresh) _isScanning = true;
    });
    try {
      final String sId = _store['id']?.toString() ?? '';
      final allOrders = await _orderService.getAllOrdersAdmin(
        storeId: int.tryParse(sId),
      );
      final String sName = (_store['storeName'] ?? '').toString().trim().toLowerCase();
      
      final filtered = allOrders;
      
      // Calculate revenue and chart data
      double totalRev = 0;
      List<double> weeklyRev = [0, 0, 0, 0];
      final now = DateTime.now();
      
      for (var o in filtered) {
        final status = (o.status ?? '').toUpperCase();
        if (status != 'CANCELLED') {
          final amt = (o.totalAmount ?? 0).toDouble();
          totalRev += amt;
          
          final date = DateTime.tryParse(o.createdAt ?? '') ?? now;
          if (date.year == now.year && date.month == now.month) {
            int weekIdx = ((date.day - 1) / 7).floor().clamp(0, 3);
            weeklyRev[weekIdx] += amt;
          }
        }
      }

      if (mounted) {
        setState(() {
          _storeOrders = filtered;
          _totalMonthlyRevenue = totalRev;
          _weeklyRevenue = weeklyRev;
          _isOrdersLoading = false;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _isOrdersLoading = false;
        _isScanning = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isProductsLoading = true);
    try {
      final products = await _productService.getProductsByStore(_store['id'].toString());
      if (mounted) {
        setState(() {
          _products = products;
          _isProductsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _products = [];
          _isProductsLoading = false;
        });
      }
    }
  }

  Future<void> _deleteStore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa cửa hàng "${_store['storeName'] ?? 'này'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      )
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await _storeRepository.deleteStore(_store['id'].toString());
      if (mounted) {
        Navigator.pop(context); // Go back to list
      }
    }
  }

  void _editStore() {
    final l = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    String newName = _store['storeName'] ?? '';
    String newPhone = _store['phone'] ?? '';
    String newAddress = _store['address'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa cửa hàng'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: newName,
                decoration: const InputDecoration(labelText: 'Tên cửa hàng'),
                onSaved: (val) => newName = val!,
              ),
              TextFormField(
                initialValue: newPhone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                onSaved: (val) => newPhone = val!,
              ),
              Text(l.byLocale(vi: 'Địa chỉ', en: 'Address'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              AddressSelection2Dropdowns(
                initialValue: newAddress,
                onAddressChanged: (val) => newAddress = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.translate('cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                setState(() => _isLoading = true);
                Navigator.pop(context);
                final updatedData = {
                  ..._store,
                  'storeName': newName,
                  'phone': newPhone,
                  'address': newAddress,
                };
                await _storeRepository.updateStore(updatedData);
                setState(() {
                  _store = updatedData;
                  _isLoading = false;
                });
              }
            },
            child: Text(l.translate('save')),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dynamic status = _store['isOpen'] ?? false;
    final bool isPending = status == 'pending';

    return DefaultTabController(
      length: isPending ? 1 : 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(_store['storeName'] ?? l.translate('detail_store')),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.edit), onPressed: _editStore),
            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: _deleteStore),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: l.translate('nav_overview')),
              if (!isPending) Tab(text: l.translate('nav_stores')),
              if (!isPending) Tab(text: l.translate('nav_orders')),
            ],
          ),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : TabBarView(
              children: [
                _buildOverviewTab(isPending, l),
                if (!isPending) _buildProductsTab(),
                if (!isPending) _buildOrdersTab(),
              ],
            ),
      ),
    );
  }

  Widget _buildOverviewTab(bool isPending, AppLocalizations l) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreHeader(l),
          const SizedBox(height: 24),
          if (!isPending) ...[
            Text(l.translate('revenue'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRevenueChart(l),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreHeader(AppLocalizations l) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndUploadStoreImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    backgroundImage: _store['imageUrl'] != null && _store['imageUrl'].toString().isNotEmpty
                        ? NetworkImage(_store['imageUrl'])
                        : null,
                    child: _store['imageUrl'] == null || _store['imageUrl'].toString().isEmpty
                        ? const Icon(Icons.store, size: 30, color: Colors.blue)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Removed redundant store name/owner header as requested
            _buildInfoRow(Icons.person_outline, l.byLocale(vi: 'Chủ cửa hàng', en: 'Owner'), _store['ownerName'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, l.byLocale(vi: 'Địa chỉ', en: 'Address'), _store['address'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.storefront, l.byLocale(vi: 'SĐT Cửa hàng', en: 'Store Phone'), _store['storePhone'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, l.byLocale(vi: 'SĐT Chủ', en: 'Owner Phone'), _store['ownerPhone'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.star, 'Rating', '${_store['rating'] ?? '5.0'} / 5.0', color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadStoreImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      setState(() => _isLoading = true);
      
      final String endpoint = ApiRoutes.uploadStore(_store['id'].toString());
      final String newUrl = await _uploadService.uploadImage(endpoint, image);

      if (mounted) {
        setState(() {
          _store['imageUrl'] = newUrl;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh cửa hàng thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickAndUploadProductImage(ProductModel product) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      setState(() => _isProductsLoading = true);
      
      final String endpoint = ApiRoutes.uploadProductWithId(product.id.toString());
      await _uploadService.uploadImage(endpoint, image);

      if (mounted) {
        setState(() => _isProductsLoading = false);
        _loadProducts(); // Fresh reload
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh sản phẩm thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProductsLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 14)),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color ?? (isDark ? Colors.white : Colors.black87)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(AppLocalizations l) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Text(l.translate('revenue'), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(_currencyFormat.format(_totalMonthlyRevenue), 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.show_chart, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_weeklyRevenue.reduce((a, b) => a > b ? a : b) * 1.2).clamp(100.0, double.infinity),
                  barTouchData: const BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['Tuần 1', 'Tuần 2', 'Tuần 3', 'Tuần 4'];
                          if (value.toInt() >= 0 && value.toInt() < titles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(titles[value.toInt()], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _weeklyRevenue[0], color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _weeklyRevenue[1], color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: _weeklyRevenue[2], color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: _weeklyRevenue[3], color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(4))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_isProductsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final l = AppLocalizations.of(context)!;
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(l.translate('no_data'), style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final prod = _products[index];
          final l = AppLocalizations.of(context)!;
          final bool isHidden = prod.isActive == false;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isHidden ? Colors.grey[200] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: prod.imageUrl != null && prod.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          prod.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.image, color: Colors.blue),
              ),
              title: Text(
                prod.name ?? 'Không tên', 
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  decoration: isHidden ? TextDecoration.lineThrough : null,
                  color: isHidden ? Colors.grey : Colors.black,
                )
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tồn kho: ${prod.stock ?? 0}'),
                  if (isHidden)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(4)),
                      child: const Text('Đã ẩn vi phạm', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${prod.price ?? 0}đ', 
                    style: TextStyle(
                      color: isHidden ? Colors.grey : Colors.green, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.blue[400], size: 20),
                    tooltip: 'Đổi ảnh',
                    onPressed: () => _pickAndUploadProductImage(prod),
                  ),
                  IconButton(
                    icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off, color: isHidden ? Colors.green : Colors.red),
                    tooltip: isHidden ? 'Bỏ ẩn' : 'Ẩn vi phạm',
                    onPressed: () async {
                      // Note: We don't have a direct toggle service yet, but we can call update or simulate
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đang được cập nhật'))
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersTab() {
    final l = AppLocalizations.of(context)!;
    if (_isOrdersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => _loadStoreOrders(forceRefresh: true),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(l.translate('nav_orders'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (_isScanning) ...[
                      const SizedBox(width: 8),
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 4),
                      Text('Scanning...', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.sync, color: _isScanning ? Colors.grey : Colors.blue, size: 20),
                  onPressed: _isScanning ? null : () => _loadStoreOrders(forceRefresh: true),
                  tooltip: 'Sync Orders (Scans IDs 1-5000)',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _storeOrders.length,
              itemBuilder: (context, index) {
                final o = _storeOrders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: const Icon(Icons.receipt, color: Colors.blue, size: 20),
              ),
              title: Text('Đơn hàng #${o.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Ngày: ${o.createdAt?.split('T')[0] ?? 'N/A'}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_currencyFormat.format(o.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(4)),
                    child: Text(o.status ?? 'N/A', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                  )
                ],
              ),
            ),
          );
              },
            ),
          ),
        ],
      ),
    );
  }
}
