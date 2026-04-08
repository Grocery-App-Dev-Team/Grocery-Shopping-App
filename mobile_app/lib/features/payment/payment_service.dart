import 'dart:async';

import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';

class PaymentService {
  final ApiClient apiClient;

  PaymentService({required this.apiClient});

  /// Initiate payment on backend. Returns map with paymentId and redirectUrl
  Future<Map<String, dynamic>> initiatePayment(int orderId, String method) async {
    final resp = await apiClient.post('/payments/initiate', data: {
      'orderId': orderId,
      'paymentMethod': method,
    });

    return Map<String, dynamic>.from(resp.data);
  }

  /// Open redirectUrl in external browser
  Future<void> openPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  /// Poll order status until paymentStatus != PENDING or timeout
  Future<String> pollPaymentStatus(int orderId,
      {Duration interval = const Duration(seconds: 3), Duration timeout = const Duration(seconds: 60)}) async {
    final completer = Completer<String>();
    Timer? timer;
    Timer? timeoutTimer;

    void stopTimers() {
      timer?.cancel();
      timeoutTimer?.cancel();
    }

    timer = Timer.periodic(interval, (_) async {
      try {
        final resp = await apiClient.get('/orders/$orderId');
        final data = resp.data as Map<String, dynamic>;
        final paymentStatus = data['paymentStatus'] as String? ?? 'PENDING';
        if (paymentStatus != 'PENDING') {
          stopTimers();
          completer.complete(paymentStatus);
        }
      } catch (e) {
        // ignore errors during polling
      }
    });

    timeoutTimer = Timer(timeout, () {
      stopTimers();
      if (!completer.isCompleted) completer.complete('TIMEOUT');
    });

    return completer.future;
  }
}
