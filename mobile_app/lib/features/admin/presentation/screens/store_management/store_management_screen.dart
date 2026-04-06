import 'package:flutter/material.dart';
import 'store_detail_screen.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../data/repositories/api_store_repository_impl.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StoreRepository _storeRepository = ApiStoreRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddStoreDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String ownerName = '';
    String phone = '';
    String password = '';
    String address = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm cửa hàng mới'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Tên cửa hàng'),
                    validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                    onSaved: (v) => name = v!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Họ tên chủ cửa hàng'),
                    validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                    onSaved: (v) => ownerName = v!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Số điện thoại đăng nhập'),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Không được để trống';
                      if (!RegExp(r'^0\d{9}$').hasMatch(v)) {
                        return 'SĐT phải có 10 chữ số và bắt đầu bằng 0';
                      }
                      return null;
                    },
                    onSaved: (v) => phone = v!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Mật khẩu đăng nhập'),
                    obscureText: true,
                    validator: (v) => v!.isEmpty || v.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                    onSaved: (v) => password = v!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Địa chỉ cửa hàng'),
                    validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                    onSaved: (v) => address = v!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  try {
                    await _storeRepository.createStore({
                      'name': name,
                      'ownerName': ownerName,
                      'phone': phone,
                      'password': password,
                      'address': address,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm cửa hàng thành công')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  }
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quản lý Cửa hàng'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Đang hoạt động'),
            Tab(text: 'Chờ duyệt'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStoreDialog,
        icon: const Icon(Icons.add_business),
        label: const Text('Thêm'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStoreList(pendingApproval: false),
          _buildStoreList(pendingApproval: true),
        ],
      ),
    );
  }

  Widget _buildStoreList({required bool pendingApproval}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _storeRepository.getStores(pendingApproval: pendingApproval),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
           return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  pendingApproval ? 'Không có cửa hàng nào chờ duyệt' : 'Chưa có cửa hàng nào',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        final stores = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              return _buildStoreCard(stores[index], pendingApproval);
            },
          ),
        );
      },
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store, bool isPending) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StoreDetailScreen(store: store)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  radius: 24,
                  child: const Icon(Icons.store, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store['storeName'] ?? 'Chưa có tên',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chủ CH: ${store['ownerName'] ?? 'N/A'}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(store['isOpen']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(store['isOpen']),
                    style: TextStyle(
                      color: _getStatusColor(store['isOpen']),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    store['address'] ?? 'Chưa có địa chỉ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (isPending) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      await _storeRepository.rejectStore(store['id']);
                      setState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Từ chối'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      await _storeRepository.approveStore(store['id']);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Duyệt'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }

  Color _getStatusColor(dynamic status) {
    if (status == true || status == 'active') return Colors.green;
    if (status == 'pending') return Colors.orange;
    if (status == false) return Colors.grey; 
    return Colors.red;
  }

  String _getStatusText(dynamic status) {
    if (status == true || status == 'active') return 'Hoạt động';
    if (status == 'pending') return 'Chờ duyệt';
    if (status == false) return 'Đóng cửa';
    return 'Từ chối';
  }
}
