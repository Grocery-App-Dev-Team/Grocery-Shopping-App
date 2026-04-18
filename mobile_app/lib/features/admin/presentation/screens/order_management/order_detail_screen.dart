import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderModel _order;
  final OrderService _orderService = OrderService();
  bool _isLoading = false;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _refreshOrder();
  }

  Future<void> _refreshOrder() async {
    setState(() => _isLoading = true);
    try {
      final updatedOrder = await _orderService.getOrderById(_order.id);
      if (mounted) {
        setState(() {
          _order = updatedOrder;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận cập nhật'),
        content: Text('Bạn có chắc chắn muốn chuyển trạng thái đơn hàng sang "$newStatus"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final updatedOrder = await _orderService.updateOrderStatus(_order.id, newStatus: newStatus);
        if (mounted) {
          setState(() {
            _order = updatedOrder;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật trạng thái thành công'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l.byLocale(vi: 'Chi tiết Đơn hàng', en: 'Order Details')} #${_order.id ?? ""}'),
        actions: [
          IconButton(onPressed: _refreshOrder, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading && _order.items == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshOrder,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusCard(l, isDark),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: l.byLocale(vi: 'Khách hàng', en: 'Customer'),
                    icon: Icons.person_outline,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(l.byLocale(vi: 'Tên', en: 'Name'), _order.customerName ?? 'N/A'),
                        _infoRow(l.byLocale(vi: 'SĐT', en: 'Phone'), _order.customerPhone ?? 'N/A'),
                        _infoRow(l.byLocale(vi: 'Địa chỉ giao', en: 'Delivery Address'), _order.address ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: l.byLocale(vi: 'Cửa hàng', en: 'Store'),
                    icon: Icons.storefront_outlined,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(l.byLocale(vi: 'Tên', en: 'Name'), _order.storeName ?? 'N/A'),
                        _infoRow(l.byLocale(vi: 'Địa chỉ', en: 'Address'), _order.storeAddress ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_order.shipperId != null)
                    _buildSectionCard(
                      title: l.byLocale(vi: 'Tài xế', en: 'Shipper'),
                      icon: Icons.delivery_dining_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow(l.byLocale(vi: 'Tên', en: 'Name'), _order.shipperName ?? 'N/A'),
                          _infoRow(l.byLocale(vi: 'SĐT', en: 'Phone'), _order.shipperPhone ?? 'N/A'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: l.byLocale(vi: 'Sản phẩm', en: 'Products'),
                    icon: Icons.shopping_basket_outlined,
                    padding: EdgeInsets.zero,
                    content: Column(
                      children: [
                        if (_order.items == null || _order.items!.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Chưa có thông tin sản phẩm'),
                          )
                        else
                          ..._order.items!.map((item) => _buildItemTile(item)),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _totalRow(l.byLocale(vi: 'Tạm tính', en: 'Subtotal'), _currencyFormat.format(_order.totalAmount ?? 0)),
                              if (_order.shippingFee != null && _order.shippingFee! > 0)
                                _totalRow(l.byLocale(vi: 'Phí ship', en: 'Shipping Fee'), _currencyFormat.format(_order.shippingFee)),
                              const SizedBox(height: 8),
                              _totalRow(
                                l.byLocale(vi: 'TỔNG CỘNG', en: 'GRAND TOTAL'),
                                _currencyFormat.format(_order.grandTotal ?? _order.totalAmount ?? 0),
                                isBold: true,
                                color: Colors.indigo,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_order.status != 'DELIVERED' && _order.status != 'CANCELLED')
                    _buildActionButtons(l),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(AppLocalizations l, bool isDark) {
    Color color = Colors.grey;
    String statusStr = _order.status ?? 'PENDING';
    if (statusStr == 'PENDING') color = Colors.orange;
    if (statusStr == 'CONFIRMED') color = Colors.blue;
    if (statusStr == 'PICKING_UP') color = Colors.indigo;
    if (statusStr == 'DELIVERING') color = Colors.purple;
    if (statusStr == 'DELIVERED') color = Colors.green;
    if (statusStr == 'CANCELLED') color = Colors.red;

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.translate('status').toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.translate('order_${statusStr.toLowerCase()}'),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l.byLocale(vi: 'Cập nhật:', en: 'Updated:')} ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(_order.updatedAt ?? _order.createdAt ?? "") ?? DateTime.now())}',
                    style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget content, EdgeInsets? padding}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(OrderItemModel item) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: item.productImageUrl != null && item.productImageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(item.productImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey)),
              )
            : const Icon(Icons.image, color: Colors.grey),
      ),
      title: Text(item.productName ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text('${item.quantity} x ${_currencyFormat.format(item.unitPrice ?? 0)}', style: const TextStyle(fontSize: 12)),
      trailing: Text(_currencyFormat.format(item.subtotal ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l) {
    return Column(
      children: [
        const SizedBox(height: 16),
        if (_order.status == 'PENDING')
          _actionButton(l.byLocale(vi: 'XÁC NHẬN ĐƠN HÀNG', en: 'CONFIRM ORDER'), Colors.blue, () => _updateStatus('CONFIRMED')),
      ],
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onPressed, {bool isOutline = false}) {
    return SizedBox(
      width: double.infinity,
      child: isOutline
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
    );
  }
}
