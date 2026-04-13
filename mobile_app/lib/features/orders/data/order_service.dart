import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_error.dart';
import '../../../core/api/api_routes.dart';
import 'order_model.dart';

/// Orders API: get store orders, update order status.
class OrderService {
  OrderService() : _client = ApiClient();

  final ApiClient _client;

  // Local persistence simulation for Admin Dashboard (Clearing as per user request)
  static final List<OrderModel> _mockOrders = [];

  /// GET /orders/my-store-orders — backend không hỗ trợ page/limit/status query.
  Future<List<OrderModel>> getStoreOrders() async {
    try {
      final response = await _client.get<dynamic>(ApiRoutes.myStoreOrders);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Phản hồi danh sách đơn hàng không hợp lệ',
        );
      }
      final raw = data['data'];
      if (raw == null) {
        throw const ApiException(
          message: 'Phản hồi danh sách đơn hàng không hợp lệ',
        );
      }
      if (raw is! List) {
        throw const ApiException(
          message: 'Phản hồi danh sách đơn hàng không hợp lệ',
        );
      }
      final out = <OrderModel>[];
      for (final item in raw) {
        if (item is! Map) {
          debugPrint('getStoreOrders: bỏ qua phần tử không phải object');
          continue;
        }
        try {
          out.add(
            OrderModel.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (e, st) {
          debugPrint('getStoreOrders: lỗi parse một đơn — $e\n$st');
        }
      }
      if (raw.isNotEmpty && out.isEmpty) {
        throw const ApiException(
          message: 'Không đọc được dữ liệu đơn hàng',
        );
      }
      return out;
    } on DioException catch (e) {
      debugPrint('getStoreOrders error: $e');
      if (e.error is ApiException) throw e.error as ApiException;
      rethrow;
    }
  }

  // ========== ADMIN DISCOVERY METHODS (NO BACKEND CHANGES) ==========

  // Cache để tránh quét lại nhiều lần trong cùng một phiên làm việc
  static List<OrderModel>? _cachedDiscoveredOrders;

  /// Cơ chế Khám phá Đơn hàng dựa trên danh sách User (Theo gợi ý: Check Users -> Load Orders)
  /// Không quét mù quáng dải ID rộng, tập trung vào các ID có khả năng tồn tại cao.
  /// Lấy đơn hàng của một User bất kỳ (API mới dành riêng cho Admin)
  Future<List<OrderModel>> getOrdersByUserIdForAdmin(dynamic userId) async {
    try {
      final response = await _client.get<dynamic>('/orders/user/$userId');
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        final List list = data['data'];
        return list.map((json) => OrderModel.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting orders for user $userId: $e');
      return [];
    }
  }

  /// Cơ chế Khám phá Đơn hàng dựa trên danh sách User (Theo yêu cầu: Get Users -> Load Orders)
  Future<List<OrderModel>> discoverRealOrders({bool forceRefresh = false, Function(int)? onProgress}) async {
    if (!forceRefresh && _cachedDiscoveredOrders != null) {
      return _cachedDiscoveredOrders!;
    }

    debugPrint('🔍 Bắt đầu khám phá đơn hàng thông qua danh sách Users (API chính thức)...');
    
    try {
      // 1. Lấy danh sách toàn bộ User thực tế
      final usersRes = await _client.get<dynamic>('/users');
      final List rawList = (usersRes.data != null && usersRes.data['data'] != null) 
          ? usersRes.data['data'] 
          : [];
      
      final List<String> userIds = rawList
          .map((u) => u['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      
      // 2. Gọi API lấy đơn hàng cho từng User (Dùng API mới tạo ở Backend)
      final Set<OrderModel> allFoundOrders = {};
      final List<Future<List<OrderModel>>> futures = [];
      
      for (var uid in userIds) {
        futures.add(getOrdersByUserIdForAdmin(uid));
      }

      final results = await Future.wait(futures);
      for (var list in results) {
        allFoundOrders.addAll(list);
        if (onProgress != null) onProgress(allFoundOrders.length);
      }

      final List<OrderModel> finalOrders = allFoundOrders.toList();
      
      // Sắp xếp theo thời gian mới nhất
      finalOrders.sort((a, b) {
        final dateA = DateTime.tryParse(a.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      _cachedDiscoveredOrders = finalOrders;
      return finalOrders.isNotEmpty ? finalOrders : _mockOrders;
    } catch (e) {
      debugPrint('❌ Lỗi trong quá trình khám phá Đơn hàng theo User: $e');
      return _cachedDiscoveredOrders ?? _mockOrders;
    }
  }

  /// Lấy toàn bộ danh sách đơn hàng cho Admin thông qua API chuẩn (đã sửa ở Backend)
  Future<List<OrderModel>> getAllOrdersAdmin({bool forceRefresh = false}) async {
    try {
      final response = await _client.get<dynamic>('/orders/admin/all');
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        final List list = data['data'];
        final orders = list.map((json) => OrderModel.fromJson(Map<String, dynamic>.from(json))).toList();
        _cachedDiscoveredOrders = orders;
        return orders;
      }
      return discoverRealOrders(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('getAllOrdersAdmin API Error: $e. Falling back to discovery...');
      return discoverRealOrders(forceRefresh: forceRefresh);
    }
  }

  /// Kiểm tra số lượng User trong hệ thống (để chứng minh DB đang hoạt động)
  Future<int> getTotalUsersCount() async {
    try {
      final response = await _client.get<dynamic>('/users');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return (data['data'] as List).length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Utilize existing API to suggest Customers
  Future<List<Map<String, dynamic>>> fetchCustomersSuggestion() async {
    try {
      final response = await _client.get<dynamic>('/users/role/CUSTOMER');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchCustomersSuggestion error: $e');
      return [];
    }
  }

  /// Utilize existing API to suggest Shippers
  Future<List<Map<String, dynamic>>> fetchShippersSuggestion() async {
    try {
      final response = await _client.get<dynamic>('/users/role/SHIPPER');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchShippersSuggestion error: $e');
      return [];
    }
  }

  /// Utilize existing API to suggest Stores
  Future<List<Map<String, dynamic>>> fetchStoresSuggestion() async {
    try {
      final response = await _client.get<dynamic>('/stores');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchStoresSuggestion error: $e');
      return [];
    }
  }

  /// Utilize existing API to suggest Products per Store
  Future<List<Map<String, dynamic>>> fetchProductsByStore(String storeId) async {
    try {
      final response = await _client.get<dynamic>('/products/store/$storeId');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchProductsByStore error: $e');
      return [];
    }
  }

  Future<bool> createOrderSimulated(OrderModel order) async {
    // Create a copy with generated ID and timestamp
    final newOrder = OrderModel(
      id: 1000 + _mockOrders.length + 1,
      status: order.status ?? 'PENDING',
      totalAmount: order.totalAmount,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      storeName: order.storeName,
      shipperName: order.shipperName,
      createdAt: DateTime.now().toIso8601String(),
      items: order.items,
    );
    _mockOrders.insert(0, newOrder);
    return true;
  }

  Future<bool> deleteOrderSimulated(int id) async {
    _mockOrders.removeWhere((o) => o.id == id);
    return true;
  }

  /// PATCH /orders/{id}/status — body: newStatus, optional cancelReason / podImageUrl.
  Future<OrderModel> updateOrderStatus(
    dynamic orderId, {
    required String newStatus,
    String? cancelReason,
    String? podImageUrl,
  }) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        ApiRoutes.updateOrderStatus(orderId),
        data: UpdateOrderStatusRequest(
          newStatus: newStatus,
          cancelReason: cancelReason,
          podImageUrl: podImageUrl,
        ).toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Phản hồi trống');
      }
      final order = data['data'] ?? data;
      return OrderModel.fromJson(
        order is Map<String, dynamic>
            ? order
            : Map<String, dynamic>.from(order as Map),
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(
        message: e.message ?? 'Lỗi cập nhật trạng thái đơn hàng',
      );
    }
  }
}
