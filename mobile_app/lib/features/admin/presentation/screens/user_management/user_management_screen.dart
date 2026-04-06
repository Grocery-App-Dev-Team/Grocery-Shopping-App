import 'package:flutter/material.dart';
import '../../../../../core/enums/app_type.dart';
import '../../../../auth/models/user_model.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../data/repositories/api_user_repository_impl.dart';
import '../../widgets/user_list_item.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserRepository _userRepository = ApiUserRepositoryImpl();

  final List<AppType> _tabs = [
    AppType.customer,
    AppType.store,
    AppType.shipper,
    AppType.admin,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    String fullName = '';
    String phoneNumber = '';
    String password = '';
    UserRole selectedRole = UserRole.customer;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Thêm người dùng mới'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Họ và tên'),
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                        onSaved: (v) => fullName = v!,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Số điện thoại'),
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập SĐT';
                          if (!RegExp(r'^0\d{9}$').hasMatch(v)) {
                            return 'SĐT phải có 10 chữ số và bắt đầu bằng 0';
                          }
                          return null;
                        },
                        onSaved: (v) => phoneNumber = v!,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Mật khẩu'),
                        obscureText: true,
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                        onSaved: (v) => password = v!,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'Vai trò'),
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedRole = val!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      final newUser = UserModel(
                        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                        fullName: fullName,
                        phoneNumber: phoneNumber,
                        role: selectedRole,
                        status: UserStatus.active,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      await _userRepository.createUser(newUser, password: password);
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {}); // Refresh
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm người dùng')),
                        );
                      }
                    }
                  },
                  child: const Text('Thêm'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        backgroundColor: const Color(0xFF6A1B9A), 
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabs.map((type) => Tab(text: type.displayName)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((type) => _buildUserList(type)).toList(),
      ),
    );
  }

  Widget _buildUserList(AppType type) {
    return FutureBuilder<List<UserModel>>(
      future: _userRepository.getUsers(appType: type),
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
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Không có người dùng nào',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        final List<UserModel> allUsers = snapshot.data!;
        final List<UserModel> users = allUsers.where((u) {
          switch (type) {
            case AppType.customer: return u.role == UserRole.customer;
            case AppType.store: return u.role == UserRole.store;
            case AppType.shipper: return u.role == UserRole.shipper;
            case AppType.admin: return u.role == UserRole.admin;
            default: return true;
          }
        }).toList();

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Không có ${type.displayName} nào',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return UserListItem(
                user: users[index],
                onStatusChanged: (newStatus) async {
                  await _userRepository.updateUserStatus(users[index].id, newStatus);
                  setState(() {}); // Refresh list
                },
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserDetailScreen(user: users[index]),
                    ),
                  );
                  // Refresh automatically when returning from details
                  setState(() {});
                },
              );
            },
          ),
        );
      },
    );
  }
}
