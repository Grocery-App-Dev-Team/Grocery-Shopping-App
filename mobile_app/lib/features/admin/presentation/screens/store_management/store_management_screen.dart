import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grocery_shopping_app/features/admin/presentation/screens/store_management/store_detail_screen.dart';
import 'package:grocery_shopping_app/features/admin/domain/repositories/store_repository.dart';
import 'package:grocery_shopping_app/features/admin/data/repositories/api_store_repository_impl.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';
import '../../widgets/address_selection_2_dropdowns.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  final StoreRepository _storeRepository = ApiStoreRepositoryImpl();
  final OrderService _orderService = OrderService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _searchQuery = '';
  bool _isLoadingRevenue = false;
  Map<String, double> _storeRevenueMap = {};

  @override
  void initState() {
    super.initState();
    _loadStoreRevenue();
  }

  Future<void> _loadStoreRevenue() async {
    if (!mounted) return;
    setState(() => _isLoadingRevenue = true);
    
    try {
      final orders = await _orderService.getAllOrdersAdmin();
      
      final Map<String, double> revenueMap = {};
      for (var o in orders) {
        final status = (o.status ?? '').toUpperCase();
        if (status != 'CANCELLED') {
           final sId = o.storeId?.toString() ?? 'unknown';
           revenueMap[sId] = (revenueMap[sId] ?? 0) + (o.totalAmount ?? 0).toDouble();
        }
      }
      
      if (!mounted) return;
      setState(() {
        _storeRevenueMap = revenueMap;
        _isLoadingRevenue = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingRevenue = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showAddStoreDialog() {
    final l = AppLocalizations.of(context)!;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l.translate('add'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: _inputDecoration(l.translate('nav_stores'), Icons.store_outlined),
                    validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                    onSaved: (v) => name = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: _inputDecoration(l.translate('full_name'), Icons.person_outline),
                    validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                    onSaved: (v) => ownerName = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: _inputDecoration(l.translate('contact_phone'), Icons.phone_android_outlined),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || !RegExp(r'^0\d{9}$').hasMatch(v)) ? 'SĐT không hợp lệ' : null,
                    onSaved: (v) => phone = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: _inputDecoration(l.translate('password_hint'), Icons.lock_outline),
                    obscureText: true,
                    validator: (v) => v!.isEmpty || v.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                    onSaved: (v) => password = v!,
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  Text(l.byLocale(vi: 'Địa chỉ', en: 'Address'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  AddressSelection2Dropdowns(
                    onAddressChanged: (val) => address = val,
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
                      if (mounted) setState(() {});
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}')));
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
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      prefixIcon: Icon(icon, size: 20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l.translate('mgmt_stores'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.indigo),
            onPressed: () => _exportStores(l),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStoreDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add_business, color: Colors.white),
      ),
      body: _buildStoreList(l),
    );
  }

  Widget _buildStoreList(AppLocalizations l) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _storeRepository.getStores(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.indigo));
        }

        final allStores = snapshot.data ?? [];
        final filteredStores = allStores.where((s) {
          final name = (s['storeName'] ?? '').toString().toLowerCase();
          final owner = (s['ownerName'] ?? '').toString().toLowerCase();
          final addr = (s['address'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || owner.contains(_searchQuery) || addr.contains(_searchQuery);
        }).toList();

        if (filteredStores.isEmpty) {
          return _buildEmptyState(l);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _loadStoreRevenue();
            if (mounted) setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredStores.length,
            itemBuilder: (context, index) {
              final store = filteredStores[index];
              final bool isPending = store['isOpen'] == 'pending' || store['status'] == 'PENDING';
              return _buildStoreCard(store, isPending, l);
            },
          ),
        );
      },
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store, bool isPending, AppLocalizations l) {
    final sId = store['id']?.toString() ?? store['storeName']?.toString() ?? '';
    final double revenue = _storeRevenueMap[sId] ?? (store['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailScreen(store: store))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      image: store['imageUrl'] != null && store['imageUrl'].toString().isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(store['imageUrl'].toString()),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: store['imageUrl'] == null || store['imageUrl'].toString().isEmpty
                        ? const Icon(Icons.store, color: Colors.indigo, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store['storeName'] ?? 'Cửa hàng', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Owner: ${store['ownerName'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(store['isOpen'], l),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                   const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                   const SizedBox(width: 4),
                   Expanded(child: Text(store['address'] ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontSize: 12), overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.translate('revenue'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(_currencyFormat.format(revenue), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ],
                  ),
                  if (isPending) _buildActionButtons(store['id']),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(dynamic isOpen, AppLocalizations l) {
    final bool active = isOpen == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(active ? l.translate('active') : l.translate('inactive'), style: TextStyle(color: active ? Colors.green[700] : Colors.red[700], fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButtons(dynamic storeId) {
    return Row(
      children: [
        IconButton(
          onPressed: () async {
            await _storeRepository.rejectStore(storeId);
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 28),
        ),
        IconButton(
          onPressed: () async {
            await _storeRepository.approveStore(storeId);
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
        ),
      ],
    );
  }

  void _exportStores(AppLocalizations l) async {
    try {
      final List<Map<String, dynamic>> allStores = await _storeRepository.getStores();
      
      final exportData = allStores.map((s) => {
        'ID': s['id'],
        'Name': s['storeName'],
        'Owner': s['ownerName'],
        'Address': s['address'],
        'Revenue': _currencyFormat.format(s['totalRevenue'] ?? 0),
        'Status': s['isOpen'] == true ? l.translate('active') : l.translate('inactive'),
      }).toList();

      if (mounted) {
        await ExportService.exportToCsv(
          context: context,
          data: exportData,
          fileName: 'danhsach_cuahang_${DateFormat('yyyyMMdd').format(DateTime.now())}',
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
          Icon(Icons.store_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(l.translate('no_data'), style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }
}
