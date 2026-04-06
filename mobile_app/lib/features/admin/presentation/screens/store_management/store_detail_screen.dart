import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../data/repositories/api_store_repository_impl.dart';

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

  final List<Map<String, dynamic>> _mockCategories = [];

  @override
  void initState() {
    super.initState();
    _store = Map<String, dynamic>.from(widget.store);
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
              TextFormField(
                initialValue: newAddress,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
                onSaved: (val) => newAddress = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
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
            },
            child: const Text('Lưu'),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamic status = _store['isOpen'] ?? false;
    final bool isPending = status == 'pending';

    return DefaultTabController(
      length: isPending ? 1 : 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(_store['storeName'] ?? 'Chi tiết cửa hàng'),
          backgroundColor: const Color(0xFF6A1B9A),
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
              const Tab(text: 'Tổng quan'),
              if (!isPending) const Tab(text: 'Sản phẩm'),
              if (!isPending) const Tab(text: 'Đơn hàng'),
            ],
          ),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : TabBarView(
              children: [
                _buildOverviewTab(isPending),
                if (!isPending) _buildProductsTab(),
                if (!isPending) _buildOrdersTab(),
              ],
            ),
      ),
    );
  }

  Widget _buildOverviewTab(bool isPending) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreHeader(),
          const SizedBox(height: 24),
          if (!isPending) ...[
            const Text('Thống kê doanh thu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRevenueChart(),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(Icons.store, size: 40, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(_store['storeName'] ?? 'Chưa có tên', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Chủ: ${_store['ownerName'] ?? 'N/A'}', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const Divider(height: 32),
            _buildInfoRow(Icons.location_on, 'Địa chỉ', _store['address'] ?? 'Chưa có địa chỉ'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Liên hệ', _store['phone'] ?? 'Chưa cập nhật'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.star, 'Đánh giá', '${_store['rating'] ?? '5.0'} / 5.0', color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color ?? Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      elevation: 2,
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
                    Text('Tổng doanh thu tháng', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('0đ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
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
                  maxY: 10,
                  barTouchData: BarTouchData(enabled: false),
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
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 0, color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 0, color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 0, color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 0, color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(4))]),
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
    if (_mockCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Chưa có sản phẩm nào', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _mockCategories.length,
      itemBuilder: (context, catIndex) {
        final category = _mockCategories[catIndex];
        final products = category['products'] as List<Map<String, dynamic>>;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(category['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${products.length} sản phẩm'),
            children: List.generate(products.length, (prodIndex) {
              final prod = products[prodIndex];
              final bool isHidden = prod['isHidden'];

              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isHidden ? Colors.grey[200] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.image, color: isHidden ? Colors.grey : Colors.blue),
                ),
                title: Text(
                  prod['name'], 
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: isHidden ? TextDecoration.lineThrough : null,
                    color: isHidden ? Colors.grey : Colors.black,
                  )
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tồn kho: ${prod['stock']}'),
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
                      '${prod['price']}đ', 
                      style: TextStyle(
                        color: isHidden ? Colors.grey : Colors.green, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                    IconButton(
                      icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off, color: isHidden ? Colors.green : Colors.red),
                      tooltip: isHidden ? 'Bỏ ẩn' : 'Ẩn vi phạm',
                      onPressed: () {
                        setState(() {
                          prod['isHidden'] = !isHidden;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isHidden ? 'Đã bỏ ẩn sản phẩm' : 'Đã ẩn sản phẩm do vi phạm'))
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Chưa có đơn hàng nào', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // Hidden mock orders
  Widget _oldBuildOrdersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 8,
      itemBuilder: (context, index) {
        final statuses = ['Hoàn thành', 'Chờ xử lý', 'Đang giao', 'Đã hủy'];
        final colors = [Colors.green, Colors.orange, Colors.blue, Colors.red];
        final status = statuses[index % 4];
        final color = colors[index % 4];

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(Icons.receipt_long, color: color),
            ),
            title: Text('Đơn hàng #ORD-${1000 + index}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Khách hàng: Nguyễn Văn ${String.fromCharCode(65 + index)}'),
                const SizedBox(height: 2),
                Text('Trạng thái: $status', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            trailing: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('340k', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Hôm nay', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}
