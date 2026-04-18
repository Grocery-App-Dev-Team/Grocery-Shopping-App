import 'package:flutter/material.dart';
import '../../../../auth/models/user_model.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../data/repositories/api_user_repository_impl.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/api/upload_service.dart';
import '../../../../../core/api/api_routes.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final UserRepository _userRepository = ApiUserRepositoryImpl();
  final OrderService _orderService = OrderService();
  final _uploadService = UploadService();
  final _picker = ImagePicker();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  late UserModel _user;
  bool _isLoading = false;
  bool _isScanning = false;
  List<OrderModel> _userOrders = [];

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadUserData();
    _loadUserOrders();
  }

  Future<void> _loadUserData() async {
    try {
      final updatedUser = await _userRepository.getUserById(_user.id);
      if (mounted) {
        setState(() {
          _user = updatedUser;
        });
      }
    } catch (e) {
    }
  }

  Future<void> _loadUserOrders({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      if (forceRefresh) _isScanning = true;
    });
    try {
      final userId = int.tryParse(_user.id.toString());
      
      // Lọc theo role của user để gọi đúng filter
      final bool isCust = _user.role == UserRole.customer;
      final bool isShip = _user.role == UserRole.shipper;
      
      final allOrders = await _orderService.getAllOrdersAdmin(
        customerId: isCust ? userId : null,
        shipperId: isShip ? userId : null,
      );
      
      if (mounted) {
        setState(() {
          _isScanning = false;
          _userOrders = allOrders;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isScanning = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser() async {
    final l = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.translate('confirm_delete')),
        content: Text('Delete ${_user.fullName}? All related data will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.translate('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l.translate('all').split(' ')[0]),
          ),
        ],
      )
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await _userRepository.deleteUser(_user.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _editUser() {
    final l = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    String newName = _user.fullName;
    String newPhone = _user.phoneNumber;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.translate('edit_profile')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: newName,
                decoration: InputDecoration(labelText: l.translate('full_name')),
                onSaved: (val) => newName = val!,
              ),
              TextFormField(
                initialValue: newPhone,
                decoration: InputDecoration(labelText: l.translate('contact_phone')),
                onSaved: (val) => newPhone = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.translate('cancel'))),
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
            child: Text(l.translate('save')),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isCustomer = _user.role == UserRole.customer;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l.translate('detail_user')),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editUser),
          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: _deleteUser),
        ],
      ),
      body: _isLoading && _userOrders.isEmpty
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _loadUserOrders,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(l),
                  const SizedBox(height: 24),
                  


                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(l.translate('order_history'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (_isScanning) ...[
                            const SizedBox(width: 8),
                            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 4),
                            Text('Scanning IDs...', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.sync, color: _isScanning ? Colors.grey : Colors.blue, size: 20),
                        onPressed: _isScanning ? null : () => _loadUserOrders(forceRefresh: true),
                        tooltip: 'Sync Orders (Scans IDs 1-5000)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_userOrders.isEmpty)
                    _buildEmptySection(l.translate('no_data'), Icons.inventory_2_outlined)
                  else
                    ..._userOrders.map((o) => _buildOrderTile(o, l)),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildOrderTile(OrderModel order, AppLocalizations l) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).cardColor,
      child: ListTile(
        title: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_currencyFormat.format(order.totalAmount)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(
            order.status?.toUpperCase() ?? 'N/A', 
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message, IconData icon) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AppLocalizations l) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndUploadAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.purple.withValues(alpha: 0.1),
                    backgroundImage: _user.avatarUrl != null && _user.avatarUrl!.isNotEmpty 
                        ? NetworkImage(_user.avatarUrl!)
                        : null,
                    child: (_user.avatarUrl == null || _user.avatarUrl!.isEmpty)
                        ? Text(
                            _user.fullName.isNotEmpty ? _user.fullName[0].toUpperCase() : 'U',
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
            _buildInfoRow(Icons.phone, l.translate('contact_phone'), _user.phoneNumber),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, l.translate('joined_date'), _user.createdAt.toString().split(' ')[0]),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.local_activity, l.translate('status'), _user.isActive ? l.translate('active') : l.translate('inactive'), color: _user.isActive ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      setState(() => _isLoading = true);
      
      const String endpoint = ApiRoutes.uploadAvatar;
      final String newUrl = await _uploadService.uploadImage(endpoint, image);

      if (mounted) {
        setState(() {
          _user = _user.copyWith(avatarUrl: newUrl);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
}
