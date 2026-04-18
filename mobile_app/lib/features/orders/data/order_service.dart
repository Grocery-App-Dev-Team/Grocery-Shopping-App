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

  /// Lấy chi tiết đơn hàng theo ID
  Future<OrderModel> getOrderById(dynamic id) async {
    try {
      final response = await _client.get<dynamic>(
        '${ApiRoutes.adminOrders.replaceAll('/all', '')}/$id',
      );
      final data = response.data;
      if (data == null || data['data'] == null) {
        throw const ApiException(message: 'Không tìm thấy dữ liệu đơn hàng');
      }
      return OrderModel.fromJson(Map<String, dynamic>.from(data['data']));
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Lỗi khi lấy chi tiết đơn hàng');
    }
  }

  /// Lấy toàn bộ danh sách đơn hàng cho Admin với phân trang và lọc
  Future<List<OrderModel>> getAllOrdersAdmin({
    int page = 0,
    int size = 100, // Lấy nhiều một chút để demo, thực tế nên phân trang cuộn
    String sortBy = 'createdAt',
    String sortDir = 'desc',
    int? storeId,
    int? customerId,
    int? shipperId,
    String? status,
    String? from,
    String? to,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDir': sortDir,
      };

      if (storeId != null) queryParams['storeId'] = storeId;
      if (customerId != null) queryParams['customerId'] = customerId;
      if (shipperId != null) queryParams['shipperId'] = shipperId;
      if (status != null && status != 'all' && status != 'Tất cả') {
        queryParams['status'] = status;
      }
      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;

      debugPrint('Dio Request: GET ${ApiRoutes.adminOrders} with params: $queryParams');

      final response = await _client.get<dynamic>(
        ApiRoutes.adminOrders,
        queryParameters: queryParams,
      );

      final data = response.data;
      debugPrint('Dio Response Data: $data');
      if (data == null || data['data'] == null) return [];

      // Response format: { success: true, message: "...", data: { content: [...], pageNo: 0, ... } }
      final content = data['data']['content'];
      if (content is! List) return [];
      debugPrint('Extracted content length: ${content.length}');

      return content
          .map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      debugPrint('getAllOrdersAdmin error: $e');
      if (e.error is ApiException) throw e.error as ApiException;
      rethrow;
    }
  }

  /// Lấy thống kê tổng quan cho Dashboard Admin
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final results = await Future.wait([
        _client.get<dynamic>('/users').catchError((e) => Response(requestOptions: RequestOptions(path: ''), data: {'data': []})),
        _client.get<dynamic>('/stores').catchError((e) => Response(requestOptions: RequestOptions(path: ''), data: {'data': []})),
      ]);

      final usersList = (results[0].data['data'] as List?) ?? [];
      final storesList = (results[1].data['data'] as List?) ?? [];
      
      final orders = await getAllOrdersAdmin(size: 10); // Chỉ lấy 10 cái bản tin mới nhất cho stats

      double totalRevenue = 0;
      for (var o in orders) {
        if (o.status != 'CANCELLED') {
          totalRevenue += (o.totalAmount ?? 0).toDouble();
        }
      }

      return {
        'userCount': usersList.length,
        'storeCount': storesList.length,
        'orders': orders.length, // Lưu ý: đây chỉ là count của trang 1, thực tế nên có endpoint stats riêng
        'revenue': totalRevenue,
        'profit': totalRevenue * 0.1, 
        'recentOrders': orders.take(5).toList(),
        'recentUsers': usersList.take(3).toList(),
      };
    } catch (e) {
      return {
        'userCount': 0, 'storeCount': 0, 'orders': 0, 'revenue': 0, 'recentOrders': [],
      };
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
