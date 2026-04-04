import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import 'payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final int orderId;
  const PaymentScreen({super.key, required this.orderId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final PaymentService _paymentService;
  bool _loading = false;
  String _status = 'IDLE';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final client = ApiClient(prefs: prefs);
      _paymentService = PaymentService(apiClient: client);
    });
  }

  Future<void> _startPayment(String method) async {
    setState(() { _loading = true; _status = 'Initiating'; });
    try {
      final result = await _paymentService.initiatePayment(widget.orderId, method);
      final paymentId = result['paymentId'];
      final redirectUrl = result['redirectUrl'];

      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        await _paymentService.openPaymentUrl(redirectUrl);
        setState(() { _status = 'Waiting for confirmation...'; });

        final ps = await _paymentService.pollPaymentStatus(widget.orderId);
        setState(() { _status = 'Payment status: $ps'; });
      } else {
        setState(() { _status = 'No redirect URL returned'; });
      }
    } catch (e) {
      setState(() { _status = 'Error: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : () => _startPayment('MOMO'),
              child: const Text('Pay with Momo'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : () => _startPayment('VNPAY'),
              child: const Text('Pay with VNPay'),
            ),
            const SizedBox(height: 24),
            Text('Status: $_status'),
          ],
        ),
      ),
    );
  }
}
