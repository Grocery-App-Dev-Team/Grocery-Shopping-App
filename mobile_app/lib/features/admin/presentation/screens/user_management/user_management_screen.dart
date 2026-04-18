import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/features/auth/models/user_model.dart';
import 'package:grocery_shopping_app/features/admin/domain/repositories/user_repository.dart';
import 'package:grocery_shopping_app/features/admin/data/repositories/api_user_repository_impl.dart';
import 'package:grocery_shopping_app/features/admin/presentation/widgets/user_list_item.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/user_management/user_detail_screen.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';
import 'package:intl/intl.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';

class UserManagementScreen extends StatefulWidget {
  final UserRole? initialRole;
  const UserManagementScreen({super.key, this.initialRole});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserRepository _userRepository = ApiUserRepositoryImpl();
  String _searchQuery = '';
  UserStatus? _statusFilter;

  final List<UserRole> _roles = [
    UserRole.customer,
    UserRole.store,
    UserRole.shipper,
    UserRole.admin,
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = widget.initialRole != null ? _roles.indexOf(widget.initialRole!) : 0;
    if (initialIndex == -1) initialIndex = 0;
    _tabController = TabController(length: _roles.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddUserDialog() {
    final l = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    String fullName = '';
    String phoneNumber = '';
    String password = '';
    UserRole selectedRole = _roles[_tabController.index];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(l.translate('add'), style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: _inputDecoration(l.translate('full_name'), Icons.person_outline),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return l.byLocale(vi: 'Vui lòng nhập họ và tên', en: 'Please enter full name');
                          if (v.trim().length < 3) return l.byLocale(vi: 'Họ và tên phải có ít nhất 3 ký tự', en: 'Name must be at least 3 chars');
                          return null;
                        },
                        onSaved: (v) => fullName = v!.trim(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: _inputDecoration(l.translate('contact_phone'), Icons.phone_android_outlined),
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.isEmpty) return l.byLocale(vi: 'Vui lòng nhập SĐT', en: 'Please enter phone');
                          if (!RegExp(r'^0\d{9}$').hasMatch(v)) return l.byLocale(vi: 'SĐT không hợp lệ', en: 'Invalid phone');
                          return null;
                        },
                        onSaved: (v) => phoneNumber = v!,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: _inputDecoration(l.translate('password_hint'), Icons.lock_outline),
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return l.byLocale(vi: 'Vui lòng nhập mật khẩu', en: 'Please enter password');
                          if (v.length < 6) return l.byLocale(vi: 'Mật khẩu phải từ 6 ký tự trở lên', en: 'Password must be at least 6 chars');
                          return null;
                        },
                        onSaved: (v) => password = v!,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole>(
                        initialValue: selectedRole,
                        decoration: _inputDecoration(l.translate('detail_user').split(' ')[1], Icons.shield_outlined),
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(_getRoleDisplayName(role, l)),
                          );
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedRole = val!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(l.translate('cancel'))),
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
                        setState(() {});
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  child: Text(l.translate('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l.translate('mgmt_users'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<UserStatus?>(
                value: _statusFilter,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                hint: Text(l.translate('status'), style: const TextStyle(fontSize: 12, color: Colors.indigo)),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.translate('all'), style: const TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: UserStatus.active, child: Text(l.translate('active'), style: const TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: UserStatus.inactive, child: Text(l.translate('inactive'), style: const TextStyle(fontSize: 12))),
                ],
                onChanged: (val) => setState(() => _statusFilter = val),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.indigo),
            onPressed: () => _exportUsers(l),
            tooltip: 'Export CSV',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l.translate('search_hint'),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F2F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.indigo,
                indicatorWeight: 3,
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: _roles.map((role) => Tab(text: _getRoleDisplayName(role, l))).toList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _roles.map((role) => _buildUserList(role, l)).toList(),
      ),
    );
  }

  String _getRoleDisplayName(UserRole role, AppLocalizations l) {
    switch (role) {
      case UserRole.customer: return l.translate('nav_users'); 
      case UserRole.store: return l.translate('nav_stores');
      case UserRole.shipper: return l.translate('nav_shippers');
      case UserRole.admin: return 'Admin';
    }
  }

  Widget _buildUserList(UserRole role, AppLocalizations l) {
    return FutureBuilder<List<UserModel>>(
      future: _userRepository.getUsers(role: role),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.indigo));
        }
        
        final List<UserModel> allUsers = snapshot.data ?? [];
        final List<UserModel> filteredUsers = allUsers.where((u) {
          final matchesSearch = u.fullName.toLowerCase().contains(_searchQuery) || u.phoneNumber.contains(_searchQuery);
          final matchesStatus = _statusFilter == null || u.status == _statusFilter;
          return matchesSearch && matchesStatus;
        }).toList();

        if (filteredUsers.isEmpty) {
          return _buildEmptyState(l);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              return UserListItem(
                user: filteredUsers[index],
                onStatusChanged: (newStatus) async {
                  await _userRepository.updateUserStatus(filteredUsers[index].id, newStatus);
                  setState(() {});
                },
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailScreen(user: filteredUsers[index])));
                  setState(() {});
                },
              );
            },
          ),
        );
      },
    );
  }

  void _exportUsers(AppLocalizations l) async {
    try {
      final List<UserModel> allUsers = [];
      await Future.wait(_roles.map((role) async {
        final users = await _userRepository.getUsers(role: role);
        allUsers.addAll(users);
      }));

      final exportData = allUsers.map((u) => {
        'ID': u.id,
        'Name': u.fullName,
        'Phone': u.phoneNumber,
        'Role': _getRoleDisplayName(u.role, l),
        'Status': u.status == UserStatus.active ? l.translate('active') : l.translate('inactive'),
        'Created At': DateFormat('dd/MM/yyyy').format(u.createdAt),
      }).toList();

      if (mounted) {
        await ExportService.exportToCsv(
          context: context,
          data: exportData,
          fileName: 'danhsach_nguoidung_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất dữ liệu: ${e.toString().replaceAll('Exception: ', '')}')));
      }
    }
  }

  Widget _buildEmptyState(AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(l.translate('no_data'), style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }
}
