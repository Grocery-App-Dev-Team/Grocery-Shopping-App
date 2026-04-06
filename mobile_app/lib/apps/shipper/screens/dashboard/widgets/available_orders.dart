import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/apps/shipper/models/shipper_order.dart';
import 'package:grocery_shopping_app/apps/shipper/services/routing_service.dart';
import 'package:grocery_shopping_app/apps/shipper/bloc/shipper_dashboard_bloc.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/dashboard/widgets/optimized_order_card.dart';
import '../../order_detail/order_detail_screen.dart';
import '../../delivery/delivery_flow_screen.dart';

class AvailableOrdersList extends StatefulWidget {
  final List<ShipperOrder> orders;
  final Map<int, double>? distances;
  final Future<ShipperOrder?> Function(ShipperOrder order)? onAccept;
  final Future<ShipperOrder?> Function(ShipperOrder order)? onComplete;

  const AvailableOrdersList({
    super.key,
    required this.orders,
    this.distances,
    this.onAccept,
    this.onComplete,
  });

  @override
  State<AvailableOrdersList> createState() => _AvailableOrdersListState();
}

class _AvailableOrdersListState extends State<AvailableOrdersList> {
  bool _isLoading = false;
  bool _hasCalculated = false;

  static const String _apiKey = 'c251cd70-5c14-49fe-a134-0ad33f0bf0ed';
  static final _routingService = GraphHopperRoutingService(apiKey: _apiKey);

  Map<int, double> get _distances {
    if (widget.distances != null && widget.distances!.isNotEmpty) {
      return widget.distances!;
    }
    if (context.mounted) {
      final bloc = context.read<ShipperDashboardBloc>();
      return bloc.state.distances;
    }
    return {};
  }

  @override
  void initState() {
    super.initState();
    if (_distances.isEmpty) {
      _calculateAndSaveDistances();
    }
  }

  @override
  void didUpdateWidget(AvailableOrdersList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentDistances = _distances;
    final hasAllDistances = widget.orders.every((order) =>
        currentDistances[order.id] != null && currentDistances[order.id]! > 0);

    if (!hasAllDistances) {
      _hasCalculated = false;
      _calculateAndSaveDistances();
    }
  }

  Future<void> _calculateAndSaveDistances() async {
    final currentDistances = _distances;
    final hasAllDistances = widget.orders.every((order) =>
        currentDistances[order.id] != null && currentDistances[order.id]! > 0);

    if (hasAllDistances && _hasCalculated) return;
    _hasCalculated = true;

    setState(() => _isLoading = true);

    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() => _isLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      final currentLoc = LatLng(position.latitude, position.longitude);
      final distances = await _calculateAllDistances(currentLoc);

      if (!mounted) return;

      context.read<ShipperDashboardBloc>().add(UpdateDistances(distances));
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<int, double>> _calculateAllDistances(LatLng shipperLoc) async {
    final distances = <int, double>{};

    for (final order in widget.orders) {
      try {
        final distance = await _routingService.getDistance(
          origin: shipperLoc,
          destination: _geocodeAddress(order.deliveryAddress),
        );
        distances[order.id] = distance;
      } catch (e) {
        distances[order.id] = 0;
      }
    }

    return distances;
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  LatLng _geocodeAddress(String address) {
    final hash = address.hashCode.abs();
    return LatLng(
      10.762622 + (hash % 100) * 0.001,
      106.660172 + (hash % 50) * 0.001,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Available Orders',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ShipperTheme.textLightGreyColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon for new delivery requests',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final order = widget.orders[index];
        final distance = _distances[order.id];

        return OptimizedOrderCard(
          order: order,
          distance: distance,
          isLoading: _isLoading,
          onStart: () async {
            if (order.status == OrderStatus.CONFIRMED) {
              final updatedOrder = await widget.onAccept?.call(order);
              if (context.mounted && updatedOrder != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(order: updatedOrder),
                  ),
                );
              }
            } else if (order.status == OrderStatus.PICKING_UP ||
                order.status == OrderStatus.DELIVERING) {
              final updatedOrder = await widget.onComplete?.call(order);
              if (context.mounted && updatedOrder != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeliveryFlowScreen(order: updatedOrder),
                  ),
                );
              }
            }
          },
          onDetails: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(order: order),
              ),
            );
          },
          onMap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeliveryFlowScreen(order: order),
              ),
            );
          },
        );
      },
    );
  }
}
