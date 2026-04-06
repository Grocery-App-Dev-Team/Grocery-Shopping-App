import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/shipper_order.dart';
import '../../services/routing_service.dart';
import '../../../../core/theme/shipper_theme.dart';
import 'delivery_confirmation_screen.dart';

class OrderMapScreen extends StatefulWidget {
  final ShipperOrder order;
  final bool showDeliveryRoute;
  final String graphHopperApiKey;
  final VoidCallback? onStartDelivery;

  const OrderMapScreen({
    super.key,
    required this.order,
    this.showDeliveryRoute = false,
    this.graphHopperApiKey = 'c251cd70-5c14-49fe-a134-0ad33f0bf0ed',
    this.onStartDelivery,
  });

  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends State<OrderMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  late LatLng _destination = const LatLng(10.762622, 106.660172);
  final List<LatLng> _storeLocations = [];
  final List<LatLng> _routePoints = [];
  bool _isLoading = true;
  bool _isLoadingRoute = false;
  bool _isDelivering = false; // Track delivery status
  String? _error;
  MultiStopRouteResult? _routeResult;
  StreamSubscription<Position>? _positionStream;
  final GraphHopperRoutingService _routingService;
  bool _showDirections = false;

  _OrderMapScreenState()
      : _routingService = GraphHopperRoutingService(
            apiKey: 'c251cd70-5c14-49fe-a134-0ad33f0bf0ed');

  @override
  void initState() {
    super.initState();
    _initLocations();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocations() async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() {
          _error = 'Vui lòng cấp quyền truy cập vị trí';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _setupMarkers();
      await _fetchMultiStopRoute();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Không thể xác định vị trí: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMultiStopRoute() async {
    if (_currentPosition == null || _storeLocations.isEmpty) return;

    setState(() => _isLoadingRoute = true);

    try {
      final waypoints = <LatLng>[
        _currentPosition!,
        ..._storeLocations,
        _destination
      ];
      final labels = <String>['Vị trí hiện tại', ..._storeLabels, 'Khách hàng'];

      final result = await _routingService.getMultiStopRoute(
        waypoints: waypoints,
        labels: labels,
      );

      _routePoints.clear();
      _routePoints.addAll(result.points);
      _routeResult = result;
    } catch (e) {
      // Route calculation failed
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  List<String> get _storeLabels {
    final order = widget.order;
    if (order.stores.isNotEmpty) {
      return order.stores.map((s) => s.name).toList();
    }
    return [order.storeName];
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _updateCurrentMarker();
      }
    });
  }

  Future<bool> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  void _setupMarkers() {
    _storeLocations.clear();
    final order = widget.order;
    if (order.stores.isNotEmpty) {
      for (final store in order.stores) {
        _storeLocations.add(_geocodeAddress(store.address));
      }
    } else {
      _storeLocations.add(_geocodeAddress(order.storeAddress));
    }
    _destination = _geocodeAddress(order.deliveryAddress);
  }

  void _updateCurrentMarker() {
    if (_currentPosition == null || !mounted) return;
    setState(() {});
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
    return Scaffold(
      backgroundColor: ShipperTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bản đồ giao hàng'),
        backgroundColor: ShipperTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoadingRoute)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          IconButton(
            icon: Icon(_showDirections ? Icons.map : Icons.directions),
            onPressed: () => setState(() => _showDirections = !_showDirections),
            tooltip: _showDirections ? 'Ẩn chỉ dẫn' : 'Hiển thị chỉ dẫn',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToCurrentLocation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition ??
                            (_storeLocations.isNotEmpty
                                ? _storeLocations.first
                                : _destination),
                        initialZoom: 14,
                        minZoom: 10,
                        maxZoom: 18,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.grocery.shopping_app',
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: Colors.blue,
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                        MarkerLayer(markers: _buildMarkers()),
                      ],
                    ),
                    if (_showDirections) _buildDirectionsPanel(),
                    _buildLocationInfoPanel(),
                  ],
                ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_currentPosition != null) {
      markers.add(Marker(
        point: _currentPosition!,
        width: 40,
        height: 40,
        child: _buildCurrentLocationMarker(),
      ));
    }

    for (int i = 0; i < _storeLocations.length; i++) {
      final storeName = i < widget.order.stores.length
          ? widget.order.stores[i].name
          : widget.order.storeName;
      markers.add(Marker(
        point: _storeLocations[i],
        width: 40,
        height: 40,
        child: _buildLocationMarker(Icons.store, Colors.purple, storeName),
      ));
    }

    markers.add(Marker(
      point: _destination,
      width: 40,
      height: 40,
      child:
          _buildLocationMarker(Icons.location_on, Colors.green, 'Khách hàng'),
    ));

    return markers;
  }

  Widget _buildCurrentLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }

  Widget _buildLocationMarker(IconData icon, Color color, String label) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 5,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _initLocations();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfoPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isDelivering) ...[
              // ===== BEFORE DELIVERY - Route info =====
              if (_routeResult != null && _routeResult!.segments.isNotEmpty)
                ..._buildStoreSteps()
              else
                _buildLocationStep(
                  icon: Icons.store,
                  title: widget.order.storeName,
                  subtitle: widget.order.storeAddress,
                  color: Colors.purple,
                  isActive: !widget.showDeliveryRoute,
                  distance: null,
                  duration: null,
                ),
              const SizedBox(height: 16),

              // Start delivery button (56px, full width)
              if (_routeResult != null && _routeResult!.totalDistanceKm > 0)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _startDelivery,
                    icon: const Icon(Icons.play_arrow, size: 22),
                    label: Text(
                      'Bắt đầu giao hàng • ${_routeResult!.totalDistanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShipperTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ] else ...[
              // ===== DURING DELIVERY - Customer info + Actions =====
              // Status badge (16px text)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đang giao hàng',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer info card (16px+ text)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ShipperTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer name - LARGE (18px)
                    Text(
                      widget.order.customerName,
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Phone (clickable)
                    InkWell(
                      onTap: () async {
                        try {
                          await launchUrl(Uri(
                              scheme: 'tel', path: widget.order.customerPhone));
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Không thể gọi')),
                            );
                          }
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.phone,
                              color: ShipperTheme.primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.order.customerPhone,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: ShipperTheme.primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Address (16px)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.order.deliveryAddress,
                            style: Theme.of(context).textTheme.bodyLarge,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ===== ACTION BUTTONS - Thumb zone (56px) =====
              Row(
                children: [
                  // Call button (44px, secondary)
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await launchUrl(Uri(
                              scheme: 'tel', path: widget.order.customerPhone));
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Không thể gọi')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.phone, size: 20),
                      label: const Text(
                        'Gọi',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ShipperTheme.secondaryColor,
                        side: const BorderSide(
                            color: ShipperTheme.secondaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // POD Proof button (44px, secondary)
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeliveryConfirmationScreen(
                              order: widget.order,
                              onConfirm: () {
                                // TODO: Update order status to DELIVERED
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.photo_camera, size: 20),
                      label: const Text(
                        'Ảnh',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Confirm delivery button (56px, PRIMARY - spans remaining space)
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeliveryConfirmationScreen(
                                order: widget.order,
                                onConfirm: () {
                                  // TODO: Update order status to DELIVERED
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle, size: 22),
                        label: const Text(
                          'Xác nhận',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShipperTheme.successColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isActive,
    double? distance,
    int? duration,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (distance != null && duration != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${distance.toStringAsFixed(1)} km • $duration ph',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isActive)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(Icons.circle, size: 10, color: color),
          ),
      ],
    );
  }

  void _moveToCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15);
    }
  }

  void _moveToLocation(LatLng location) {
    _mapController.move(location, 16);
  }

  void _startDelivery() {
    setState(() => _isDelivering = true);
    // Stay on map - no pop!
    // Update order status in backend via callback if provided
    if (widget.onStartDelivery != null) {
      widget.onStartDelivery!();
    }
  }

  List<Widget> _buildStoreSteps() {
    if (_routeResult == null) return [];
    final widgets = <Widget>[];
    final order = widget.order;

    for (int i = 0; i < _routeResult!.segments.length; i++) {
      final segment = _routeResult!.segments[i];
      final isLastStore = i == _routeResult!.segments.length - 1 ||
          segment.label.contains('Khách');

      String subtitle = '';
      if (isLastStore) {
        subtitle = order.deliveryAddress;
      } else if (order.stores.isNotEmpty && i < order.stores.length) {
        subtitle = order.stores[i].address;
      } else {
        subtitle = order.storeAddress;
      }

      widgets.add(
        _buildLocationStep(
          icon: isLastStore ? Icons.location_on : Icons.store,
          title: segment.label,
          subtitle: subtitle,
          color: isLastStore ? Colors.green : Colors.purple,
          isActive: true,
          distance: segment.distanceKm,
          duration: segment.durationMinutes,
        ),
      );
      if (i < _routeResult!.segments.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  Widget _buildDirectionsPanel() {
    final segments = _routeResult?.segments ?? [];
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 300,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ShipperTheme.primaryColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Tổng quãng đường',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_routeResult != null)
                    Text(
                      '${_routeResult!.totalDistanceKm.toStringAsFixed(1)} km • ${_routeResult!.totalDurationMinutes} ph',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: segments.length,
                itemBuilder: (context, index) {
                  final seg = segments[index];
                  return _buildSegmentItem(seg, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionItem(RouteInstruction inst, int index) {
    IconData icon;
    switch (inst.sign) {
      case -3:
      case 3:
        icon = Icons.turn_left;
        break;
      case -2:
      case 2:
        icon = Icons.turn_right;
        break;
      case -1:
      case 1:
        icon = Icons.straight;
        break;
      case 4:
        icon = Icons.roundabout_left;
        break;
      case 5:
        icon = Icons.roundabout_right;
        break;
      default:
        icon = Icons.circle;
    }

    final distanceText = inst.distance >= 1000
        ? '${(inst.distance / 1000).toStringAsFixed(1)} km'
        : '${inst.distance.toInt()} m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ShipperTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: ShipperTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              inst.text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            distanceText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(RouteSegment seg, int index) {
    final segments = _routeResult?.segments ?? [];
    final isLast = index == segments.length - 1;
    final distanceText = seg.distanceKm >= 1
        ? '${seg.distanceKm.toStringAsFixed(1)} km'
        : '${(seg.distance * 1000).toInt()} m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isLast ? Colors.green : Colors.purple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isLast ? Icons.location_on : Icons.store,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.directions, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seg.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (!isLast)
                  Text(
                    '→ ${segments[index + 1].label}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Text(
            distanceText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
