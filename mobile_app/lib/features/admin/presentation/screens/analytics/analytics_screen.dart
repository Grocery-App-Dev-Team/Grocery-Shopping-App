import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../admin/domain/repositories/user_repository.dart';
import '../../../../admin/data/repositories/api_user_repository_impl.dart';
import '../../../../admin/domain/repositories/store_repository.dart';
import '../../../../admin/data/repositories/api_store_repository_impl.dart';
import 'package:grocery_shopping_app/features/auth/models/user_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedTimeFilter = 'week';
  final List<String> _timeFilters = ['today', 'week', 'month', 'year'];
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  final UserRepository _userRepository = ApiUserRepositoryImpl();
  final StoreRepository _storeRepository = ApiStoreRepositoryImpl();

  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final orderService = OrderService();
    
    // Calculate date range for the selected filter
    final now = DateTime.now();
    DateTime? fromDate;
    DateTime? toDate = now; // Typically up to now

    if (_selectedTimeFilter == 'today') {
      fromDate = DateTime(now.year, now.month, now.day);
    } else if (_selectedTimeFilter == 'week') {
      // Start of current week (Monday)
      fromDate = now.subtract(Duration(days: now.weekday - 1));
      fromDate = DateTime(fromDate.year, fromDate.month, fromDate.day);
    } else if (_selectedTimeFilter == 'month') {
      fromDate = DateTime(now.year, now.month, 1);
    } else if (_selectedTimeFilter == 'year') {
      fromDate = DateTime(now.year, 1, 1);
    }

    final String? fromStr = fromDate?.toIso8601String();
    final String? toStr = toDate.toIso8601String();

    _statsFuture = Future.wait<dynamic>([
      _userRepository.getUsers(),
      _storeRepository.getStores(),
      orderService.getAllOrdersAdmin(from: fromStr, to: toStr, size: 200), // Get a larger batch for analytics
    ]).then((results) {
      final users = results[0] as List<UserModel>;
      final stores = results[1] as List<Map<String, dynamic>>;
      final orders = results[2] as List<OrderModel>;
      
      final uCount = users.length;
      final sCount = stores.length;
      final shippersList = users.where((u) => u.role == UserRole.shipper).toList();

      // Dữ liệu đã được lọc từ server
      final filteredOrders = orders;

      // 2. Tổng hợp dữ liệu thực tế (Doanh thu & Tổng đơn)
      double realRevenue = 0;
      int realOrdersCount = filteredOrders.length;
      
      Map<String, double> storeRevenueMap = {};
      Map<String, int> shipperOrdersMap = {};
      Map<int, double> chartDataMap = {}; // index -> revenue

      for (var order in filteredOrders) {
        final status = (order.status ?? '').toUpperCase();
        
        // Count towards revenue if not cancelled
        if (status != 'CANCELLED') {
          realRevenue += (order.totalAmount ?? 0).toDouble();
          
          // Thống kê theo cửa hàng
          final sId = (order.storeId ?? order.storeName ?? 'Khác').toString();
          storeRevenueMap[sId] = (storeRevenueMap[sId] ?? 0) + (order.totalAmount ?? 0).toDouble();
          
          // Thống kê theo shipper
          final shId = (order.shipperId ?? order.shipperName ?? 'Chưa gán').toString();
          shipperOrdersMap[shId] = (shipperOrdersMap[shId] ?? 0) + 1;
        }

        // Dữ liệu biểu đồ (Phân phối theo giờ/ngày/tháng)
        final date = order.createdAt != null ? DateTime.tryParse(order.createdAt!) ?? now : now;
        int chartIdx = 0;
        if (_selectedTimeFilter == 'today') {
          chartIdx = (date.hour / 4).floor().toInt().clamp(0, 5); // 6 mốc
        } else if (_selectedTimeFilter == 'week') {
          chartIdx = (date.weekday - 1).clamp(0, 6); // 7 ngày
        } else if (_selectedTimeFilter == 'month') {
          chartIdx = ((date.day - 1) / 7).floor().toInt().clamp(0, 3); // 4 tuần
        } else if (_selectedTimeFilter == 'year') {
          chartIdx = (date.month - 1).clamp(0, 11); // 12 tháng
        }
        final amount = (order.totalAmount ?? 0).toDouble();
        chartDataMap[chartIdx] = (chartDataMap[chartIdx] ?? 0) + amount;
      }

      // 3. Chuẩn bị danh sách Xếp hạng
      final List<Map<String, dynamic>> topStoreResults = [];
      storeRevenueMap.forEach((key, val) {
        topStoreResults.add({
          'name': key,
          'revenue': val,
        });
      });
      topStoreResults.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      final List<Map<String, dynamic>> topShipperResults = [];
      shipperOrdersMap.forEach((key, val) {
        topShipperResults.add({
          'id': key,
          'count': val,
        });
      });
      topShipperResults.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return {
        'userCount': uCount,
        'storeCount': sCount,
        'revenue': realRevenue,
        'orders': realOrdersCount,
        'allOrders': filteredOrders,
        'chartData': chartDataMap,
        'topStoresData': topStoreResults.take(5).toList(),
        'topShippersData': topShipperResults.take(5).toList(),
        'shippersList': shippersList,
      };
    }).catchError((e) {
      return <String, dynamic>{'userCount': 0, 'storeCount': 0, 'offline': true};
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l.translate('nav_overview'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _exportAnalytics(context),
            tooltip: 'Xuất Báo cáo',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _loadStats()),
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
          final bool isOffline = snapshot.data?['offline'] == true;
          final int userCount = snapshot.data?['userCount'] ?? 0;
          final int storeCount = snapshot.data?['storeCount'] ?? 0;
          final double revenue = snapshot.data?['revenue'] ?? 0;
          final int orders = snapshot.data?['orders'] ?? 0;
          final List topStoresData = snapshot.data?['topStoresData'] ?? [];
          final List topShippersData = snapshot.data?['topShippersData'] ?? [];
          final List<UserModel> shippersList = snapshot.data?['shippersList'] ?? [];
          final Map<int, double> chartData = snapshot.data?['chartData'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Offline notice
                if (isOffline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off, color: Colors.orange[700], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Không kết nối được máy chủ. Số liệu User/Cửa hàng tạm thời là 0.',
                            style: TextStyle(color: Colors.orange[800], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bộ lọc thời gian
                _buildTimeFilter(),
                const SizedBox(height: 20),

                // Hàng 1: User (Real API) + Store (Real API)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        l.translate('nav_users'),
                        isLoading ? '...' : userCount.toString(),
                        Icons.people_outline,
                        Colors.green,
                        isReal: !isOffline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        l.translate('nav_stores'),
                        isLoading ? '...' : storeCount.toString(),
                        Icons.storefront,
                        Colors.blue,
                        isReal: !isOffline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Hàng 2: Real data from scanner
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        l.translate('revenue'),
                        isLoading ? '...' : _currencyFormat.format(revenue),
                        Icons.attach_money,
                        Colors.orange,
                        isReal: !isOffline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        l.translate('nav_orders'),
                        isLoading ? '...' : '$orders ${l.byLocale(vi: 'đơn', en: 'orders')}',
                        Icons.shopping_bag,
                        Colors.purple,
                        isReal: !isOffline,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // Ghi chú nguồn dữ liệu
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                            children: const [
                              TextSpan(text: '🟢 Xanh/Xanh lơ: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: 'Dữ liệu thực từ API.  '),
                              TextSpan(text: '🟡 Cam/Tím: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: 'Dữ liệu thực từ hệ thống quét.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text(l.byLocale(vi: 'Biểu đồ Doanh thu (Hệ thống quét)', en: 'Revenue Chart (Sync Data)'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLineChart(chartData),

                const SizedBox(height: 32),
                Text(l.byLocale(vi: 'Bảng Xếp Hạng', en: 'Leaderboards'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLeaderboards(topStoresData, topShippersData, shippersList),

                const SizedBox(height: 32),
                Text(l.byLocale(vi: 'Cơ cấu Thanh toán (Ước tính)', en: 'Payment Distribution (Est.)'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPieChart(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeFilter() {
    final l = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          children: [
            const Icon(Icons.filter_list, color: Colors.deepPurple, size: 20),
            const SizedBox(width: 8),
            Text('${l.byLocale(vi: 'Khoảng thời gian', en: 'Time Range')}:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTimeFilter,
                icon: const Icon(Icons.calendar_today, color: Colors.deepPurple, size: 18),
                items: _timeFilters.map((t) => DropdownMenuItem(value: t, child: Text(l.translate(t), style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTimeFilter = val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isReal = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(icon, size: 18, color: color),
                ),
                const Spacer(),
                Tooltip(
                  message: isReal ? 'Real-time API' : 'Estimated',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isReal ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isReal ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      isReal ? 'LIVE' : 'EST.',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isReal ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey[800]),
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(Map<int, double> chartData) {
    final l = AppLocalizations.of(context)!;
    int pointCount = 7;
    List<String> xLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    if (_selectedTimeFilter == 'today') {
      pointCount = 6; xLabels = ['0h', '4h', '8h', '12h', '16h', '20h'];
    } else if (_selectedTimeFilter == 'month') {
      pointCount = 4; xLabels = [l.byLocale(vi: 'Tuần 1', en: 'W1'), l.byLocale(vi: 'Tuần 2', en: 'W2'), l.byLocale(vi: 'Tuần 3', en: 'W3'), l.byLocale(vi: 'Tuần 4', en: 'W4')];
    } else if (_selectedTimeFilter == 'year') {
      pointCount = 12; xLabels = ['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'];
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.only(top: 32, right: 24, left: 16, bottom: 16),
        child: SizedBox(
          height: 250,
          child: LineChart(LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 30, interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < pointCount) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(xLabels[value.toInt()], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    );
                  }
                  return const Text('');
                },
              )),
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 55,
                getTitlesWidget: (value, meta) {
                   String text = '';
                   if (value >= 1000000) {
                     text = '${(value / 1000000).toStringAsFixed(1)}Tr';
                   } else if (value >= 1000) {
                     text = '${(value / 1000).toStringAsFixed(0)}K';
                   } else {
                     text = value.toStringAsFixed(0);
                   }
                   return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(text, style: const TextStyle(fontSize: 10)),
                  );
                },
              )),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
                LineChartBarData(
                spots: List.generate(pointCount, (index) {
                  double val = chartData[index] ?? 0;
                  return FlSpot(index.toDouble(), val);
                }),
                isCurved: true, color: Colors.deepPurple, barWidth: 4,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: Colors.deepPurple.withValues(alpha: 0.2)),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildLeaderboards(List topStoresData, List topShippersData, List<UserModel> shippersList) {
    final l = AppLocalizations.of(context)!;
    // Chuẩn bị dữ liệu hiển thị cho Cửa hàng
    final storeItems = topStoresData.map((s) {
      return {
        'name': s['name'],
        'metric': _currencyFormat.format(s['revenue']),
        'subtitle': l.byLocale(vi: 'Doanh thu đóng góp', en: 'Contribution Revenue'),
      };
    }).toList();

    // Chuẩn bị dữ liệu hiển thị cho Shipper (mapping tên từ ID nếu cần)
    final shipperItems = topShippersData.map((s) {
      final shipperObj = shippersList.firstWhere(
        (u) => u.id == s['id'].toString(), 
        orElse: () => UserModel(
          id: s['id'].toString(), 
          fullName: s['id'].toString(), 
          phoneNumber: 'N/A', 
          role: UserRole.shipper, 
          status: UserStatus.active, 
          createdAt: DateTime.now(), 
          updatedAt: DateTime.now()
        )
      );
      return {
        'name': shipperObj.fullName,
        'metric': '${s['count']} ${l.byLocale(vi: 'Đơn', en: 'Orders')}',
        'subtitle': 'SĐT: ${shipperObj.phoneNumber}',
      };
    }).toList();

    return Column(
      children: [
        if (storeItems.isNotEmpty)
          _buildLeaderboardCard('🏆 ${l.byLocale(vi: 'Top Cửa Hàng Xuất Sắc', en: 'Top Performing Stores')}', storeItems, Colors.amber),
        if (storeItems.isNotEmpty) const SizedBox(height: 16),
        if (shipperItems.isNotEmpty)
          _buildLeaderboardCard('🚀 ${l.byLocale(vi: 'Top Shipper Nổi Bật', en: 'Outstanding Shippers')}', shipperItems, Colors.blueAccent),
        if (storeItems.isEmpty && shipperItems.isEmpty)
          Center(child: Text(l.translate('no_data'))),
      ],
    );
  }

  Widget _buildLeaderboardCard(String title, List<Map<String, dynamic>> items, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800])),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(items[index]['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(items[index]['subtitle'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                trailing: Text(items[index]['metric'], style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final l = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 150,
                child: PieChart(PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: [
                    PieChartSectionData(value: 70, color: Colors.green, title: '70%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 20, color: Colors.blue, title: '20%', radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 10, color: Colors.orange, title: '10%', radius: 30, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                )),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIndicator(Colors.green, l.byLocale(vi: 'TT Trực tuyến (70%)', en: 'Online Payment (70%)')),
                const SizedBox(height: 8),
                _buildIndicator(Colors.blue, l.byLocale(vi: 'COD Giao hàng (20%)', en: 'Cash on Delivery (20%)')),
                const SizedBox(height: 8),
                _buildIndicator(Colors.orange, l.byLocale(vi: 'Ví Điện Tử (10%)', en: 'E-Wallet (10%)')),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _exportAnalytics(BuildContext context) async {
    final snapshot = await _statsFuture;
    final List<Map<String, dynamic>> exportData = [
      {'Hạng mục': 'Khoảng thời gian', 'Giá trị': _selectedTimeFilter},
      {'Hạng mục': 'Tổng người dùng', 'Giá trị': snapshot['userCount']},
      {'Hạng mục': 'Tổng cửa hàng', 'Giá trị': snapshot['storeCount']},
      {'Hạng mục': 'Doanh thu thực', 'Giá trị': _currencyFormat.format(snapshot['revenue'])},
      {'Hạng mục': 'Số lượng đơn hàng', 'Giá trị': snapshot['orders']},
      {'Hạng mục': 'Nguồn dữ liệu', 'Giá trị': 'Hệ thống Quét thực tế'},
    ];

    if (mounted) {
      await ExportService.exportToCsv(
        context: context,
        data: exportData,
        fileName: 'baocao_phantich_thuc_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    }
  }

  Widget _buildIndicator(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
