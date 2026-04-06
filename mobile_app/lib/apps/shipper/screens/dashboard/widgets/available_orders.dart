import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/apps/shipper/models/shipper_order.dart';
import 'package:grocery_shopping_app/apps/shipper/constants/shipper_strings.dart';
import 'package:grocery_shopping_app/apps/shipper/services/routing_service.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/dashboard/widgets/optimized_order_card.dart';
import '../../order_detail/order_detail_screen.dart';
import '../../delivery/delivery_flow_screen.dart';

class AvailableOrdersList extends StatefulWidget {
  final List<ShipperOrder> orders;
  final Future<ShipperOrder?> Function(ShipperOrder order)? onAccept;
  final Future<ShipperOrder?> Function(ShipperOrder order)? onComplete;

  const AvailableOrdersList({
    super.key,
    required this.orders,
    this.onAccept,
    this.onComplete,
  });

  @override
  State<AvailableOrdersList> createState() => _AvailableOrdersListState();
}

class _AvailableOrdersListState extends State<AvailableOrdersList> {
  static const String _apiKey = 'c251cd70-5c14-49fe-a134-0ad33f0bf0ed';
  static final _routingService = GraphHopperRoutingService(apiKey: _apiKey);

  final Map<int, double> _distanceCache = {};
  bool _isLoadingDistances = false;

  @override
  void initState() {
    super.initState();
    _calculateDistances();
  }

  @override
  void didUpdateWidget(AvailableOrdersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu orders thay đổi (từ refresh), tính lại khoảng cách cho orders mới
    if (oldWidget.orders.length != widget.orders.length ||
        oldWidget.orders.any((o) =>
            !widget.orders.any((n) => n.id == o.id))) {
      _distanceCache.clear();
      _calculateDistances();
    }
  }

  Future<void> _calculateDistances() async {
    if (widget.orders.isEmpty) return;

    setState(() => _isLoadingDistances = true);

    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() => _isLoadingDistances = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      final shipperLoc = LatLng(position.latitude, position.longitude);

      for (final order in widget.orders) {
        if (_distanceCache.containsKey(order.id)) continue;

        try {
          // Tạo waypoints: Shipper -> Stores -> Customer
          final waypoints = <LatLng>[shipperLoc];
          final labels = <String>['Vị trí hiện tại'];

          // Thêm tất cả cửa hàng
          if (order.stores.isNotEmpty) {
            for (final store in order.stores) {
              waypoints.add(_parseAddress(store.address));
              labels.add(store.name);
            }
          } else {
            waypoints.add(_parseAddress(order.storeAddress));
            labels.add(order.storeName);
          }

          // Thêm địa chỉ giao hàng
          waypoints.add(_parseAddress(order.deliveryAddress));
          labels.add('Khách hàng');

          // Tính multi-stop route
          final routeInfo = await _routingService.getMultiStopRoute(
            waypoints: waypoints,
            labels: labels,
          );

          // Lấy khoảng cách đã convert thành km
          final distanceKm = routeInfo.totalDistanceKm;

          if (mounted) {
            setState(() => _distanceCache[order.id] = distanceKm);
          }
        } catch (e) {
          if (mounted) {
            setState(() => _distanceCache[order.id] = 0);
          }
        }
      }
    } catch (e) {
      // Lỗi lấy location
    } finally {
      if (mounted) {
        setState(() => _isLoadingDistances = false);
      }
    }
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  LatLng _parseAddress(String address) {
    // Mock geocoding - sử dụng hash từ address
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
              ShipperStrings.emptyOrdersTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ShipperTheme.textLightGreyColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              ShipperStrings.emptyOrdersSubtitle,
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
        final distance = _distanceCache[order.id] ?? order.distanceKm;

        return OptimizedOrderCard(
          order: order,
          distance: distance,
          isLoading: _isLoadingDistances,
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
