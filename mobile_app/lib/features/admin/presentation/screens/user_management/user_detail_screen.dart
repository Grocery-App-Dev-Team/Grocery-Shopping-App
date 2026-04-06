import 'package:flutter/material.dart';
import '../../../../../core/enums/app_type.dart';
import '../../../../auth/models/user_model.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../data/repositories/api_user_repository_impl.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final UserRepository _userRepository = ApiUserRepositoryImpl();
  late UserModel _user;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _cartItems = [
    {'id': 'c1', 'name': 'Táo NZ nhập khẩu (1kg)', 'price': 120000, 'store': 'Winmart', 'qty': 2, 'isHidden': false},
    {'id': 'c2', 'name': 'Sữa chua Vinamilk lốc 4', 'price': 32000, 'store': 'Bách Hóa Xanh', 'qty': 1, 'isHidden': false},
    {'id': 'c3', 'name': 'Bánh mì sandwich mềm', 'price': 25000, 'store': 'Gia Đình Mart', 'qty': 3, 'isHidden': false},
  ];

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa ${_user.fullName}? Mọi dữ liệu liên quan sẽ bị mất.'),
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
      await _userRepository.deleteUser(_user.id);
      if (mounted) {
        Navigator.pop(context); // Go back to list
      }
    }
  }

  void _editUser() {
    final formKey = GlobalKey<FormState>();
    String newName = _user.fullName;
    String newPhone = _user.phoneNumber;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa thông tin'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: newName,
                decoration: const InputDecoration(labelText: 'Họ tên'),
                onSaved: (val) => newName = val!,
              ),
              TextFormField(
                initialValue: newPhone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                onSaved: (val) => newPhone = val!,
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
              final updated = _user.copyWith(fullName: newName, phoneNumber: newPhone);
              await _userRepository.updateUser(updated);
              setState(() {
                _user = updated;
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
    final bool isCustomer = _user.role == UserRole.customer;
    final bool isShipper = _user.role == UserRole.shipper;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Chi tiết người dùng'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editUser,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deleteUser,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(),
                const SizedBox(height: 24),
                
                if (isCustomer) ...[
                  const Text('Giỏ hàng chi tiết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildDetailedCartMock(),
                  const SizedBox(height: 24),
                ],

                if (isShipper) ...[
                  const Text('Đơn hảng được giao (Gần đây)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildShipperOrdersMock(),
                  const SizedBox(height: 24),
                ],

                if (!isShipper) ...[
                  const Text('Lịch sử đơn hàng (gần đây)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRecentOrdersMock(),
                ],
              ],
            ),
          ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                // Mock avatar change
                final updated = _user.copyWith(avatarUrl: 'mock_avatar_url');
                setState(() => _isLoading = true);
                await _userRepository.updateUser(updated);
                setState(() {
                  _user = updated;
                  _isLoading = false;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật avatar thành công!')));
                }
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    backgroundImage: _user.avatarUrl != null 
                        ? const NetworkImage('https://i.pravatar.cc/150') // Fake UI image
                        : null,
                    child: _user.avatarUrl == null
                        ? Text(
                            _user.fullName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.purple),
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(_user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_user.roleDisplayName, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const Divider(height: 32),
            _buildInfoRow(Icons.phone, 'Số điện thoại', _user.phoneNumber),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, 'Ngày tham gia', _user.createdAt.toString().split(' ')[0]),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.local_activity, 'Trạng thái', _user.isActive ? 'Đang hoạt động' : 'Bị khóa', color: _user.isActive ? Colors.green : Colors.red),
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
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color ?? Colors.black87),
        ),
      ],
    );
  }

  Widget _buildDetailedCartMock() {
    int total = 0;
    for (var item in _cartItems) {
      if (!item['isHidden']) {
        total += (item['price'] as int) * (item['qty'] as int);
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cartItems.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              final bool isHidden = item['isHidden'];
              
              return ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isHidden ? Colors.grey[300] : Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.shopping_basket, color: isHidden ? Colors.grey : Colors.purple),
                ),
                title: Text(
                  item['name'], 
                  style: TextStyle(
                    fontWeight: FontWeight.w600, 
                    decoration: isHidden ? TextDecoration.lineThrough : null,
                    color: isHidden ? Colors.grey : Colors.black,
                  )
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Từ: ${item['store']}', style: TextStyle(color: isHidden ? Colors.grey : Colors.blue)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('SL: ${item['qty']} x ${item['price']}đ'),
                        if (isHidden) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(4)),
                            child: const Text('Bị ẩn do vi phạm', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ]
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item['qty'] * item['price']}đ', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: isHidden ? Colors.grey : Colors.green, 
                        fontSize: 16
                      )
                    ),
                    IconButton(
                      icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off, color: isHidden ? Colors.green : Colors.red),
                      tooltip: isHidden ? 'Bỏ ẩn' : 'Ẩn vi phạm',
                      onPressed: () {
                        setState(() {
                          item['isHidden'] = !isHidden;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isHidden ? 'Đã cho phép hiển thị lại sản phẩm' : 'Đã ẩn sản phẩm do vi phạm'))
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng giỏ hàng hợp lệ:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${total}đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildShipperOrdersMock() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final statuses = ['Đang giao', 'Đã giao (Hôm qua)', 'Đã lấy hàng'];
          final colors = [Colors.blue, Colors.green, Colors.orange];
          
          return ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: colors[index].withOpacity(0.1),
              child: Icon(Icons.two_wheeler, color: colors[index]),
            ),
            title: Text('Đơn hàng #${20245 + index}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text('Bách Hóa Xanh'),
                  ],
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Icon(Icons.flag_circle_outlined, size: 14, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('123 Lê Lợi, Q.1'),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Trạng thái: ${statuses[index]}', style: TextStyle(fontWeight: FontWeight.w600, color: colors[index])),
              ],
            ),
            trailing: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Thu hộ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('150k', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentOrdersMock() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: index == 0 ? Colors.green[100] : Colors.orange[100],
              child: Icon(
                index == 0 ? Icons.check_circle : Icons.local_shipping,
                color: index == 0 ? Colors.green : Colors.orange,
              ),
            ),
            title: Text('Đơn hàng #${10024 - index}', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(index == 0 ? 'Đã giao thành công' : 'Đang giao hàng'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          );
        },
      ),
    );
  }
}
