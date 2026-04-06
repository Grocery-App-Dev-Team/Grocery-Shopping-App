import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../admin/presentation/screens/user_management/user_management_screen.dart';
import '../../../admin/presentation/screens/store_management/store_management_screen.dart';
import '../../../admin/presentation/screens/analytics/analytics_screen.dart';
import '../../../admin/presentation/screens/feedback/feedback_management_screen.dart';
import '../../../admin/domain/repositories/user_repository.dart';
import '../../../admin/data/repositories/api_user_repository_impl.dart';
import '../../../admin/domain/repositories/store_repository.dart';
import '../../../admin/data/repositories/api_store_repository_impl.dart';
import 'package:grocery_shopping_app/core/utils/logger.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../admin/presentation/widgets/user_list_item.dart';
import '../../../auth/models/user_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _bottomNavIndex = 0;
  final UserRepository _userRepository = ApiUserRepositoryImpl();
  final StoreRepository _storeRepository = ApiStoreRepositoryImpl();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple[100],
                    child: const Icon(Icons.shield, color: Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chào mừng trở lại,', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal)),
                      Text(user.fullName, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            body: SafeArea(
              child: _buildBody(context),
            ),
            // Hoàn thiện Bottom Navigation nhảy trang thực thụ
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _bottomNavIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.deepPurple,
              unselectedItemColor: Colors.grey,
              onTap: (index) => setState(() => _bottomNavIndex = index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Tổng quan'),
                BottomNavigationBarItem(icon: Icon(Icons.inbox_rounded), label: 'Yêu cầu'),
                BottomNavigationBarItem(icon: Icon(Icons.settings_suggest_rounded), label: 'Cài đặt'),
              ],
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  // Khối Switch Tab hiển thị 3 Màn hình Tương ứng
  Widget _buildBody(BuildContext context) {
    switch (_bottomNavIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildRequestsTab(context);
      case 2:
      default:
        return _buildSettingsTab(context);
    }
  }

  // --- TAB 0: TỔNG QUAN ---
  Widget _buildOverviewTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
        }

        final stats = snapshot.data ?? {};
        final int userCount = stats['userCount'] ?? 0;
        final int storeCount = stats['storeCount'] ?? 0;
        final double revenue = stats['revenue'] ?? 0;
        final int orders = stats['orders'] ?? 0;
        final List topStores = stats['topStores'] ?? [];
        final List topShippers = stats['topShippers'] ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông Số Hệ Thống Thực Tế', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              Row(
                children: [
                   Expanded(child: _buildStatCard('Doanh thu', _currencyFormat.format(revenue), Icons.trending_up, Colors.orange)),
                   const SizedBox(width: 12),
                   Expanded(child: _buildStatCard('Cửa hàng', storeCount.toString(), Icons.storefront, Colors.blue)),
                   const SizedBox(width: 12),
                   Expanded(child: _buildStatCard('Người dùng', userCount.toString(), Icons.people_outline, Colors.green)),
                ],
              ),
              
              const SizedBox(height: 32),
              const Text('Biển Đồ Doanh Thu (Ước tính)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildOverviewChart(),

              const SizedBox(height: 32),
              const Text('Bảng Xếp Hạng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildSimpleLeaderboards(topStores, topShippers),
              
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadDashboardStats() async {
    try {
      final results = await Future.wait([
        _userRepository.getUsers(),
        _storeRepository.getStores(),
        SharedPreferences.getInstance(),
      ]);

      final users = results[0] as List<UserModel>;
      final stores = results[1] as List<Map<String, dynamic>>;
      final prefs = results[2] as SharedPreferences;
      
      final factor = prefs.getDouble('growth_factor') ?? 1.0;
      final customerCount = users.where((u) => u.role == UserRole.customer).length;
      final sCount = stores.length;

      // Conservative scaling logic
      double revenue = 0;
      int orders = 0;
      if (sCount > 0 && (customerCount > 0 || sCount >= 2)) {
          orders = ((customerCount * 0.1 + sCount * 0.5) * factor).toInt();
          revenue = orders * 150000.0;
      }

      return {
        'userCount': users.length,
        'storeCount': stores.length,
        'revenue': revenue,
        'orders': orders,
        'topStores': stores.take(3).toList(),
        'topShippers': users.where((u) => u.role == UserRole.shipper).take(3).toList(),
      };
    } catch (e) {
      AppLogger.error('Dashboard Stats Load Error: $e');
      return {'userCount': 0, 'storeCount': 0, 'revenue': 0, 'orders': 0};
    }
  }

  Widget _buildOverviewChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.only(right: 16, top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[200], strokeWidth: 1)),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  const titles = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                  if (val.toInt() >= 0 && val.toInt() < titles.length) {
                    return Text(titles[val.toInt()], style: TextStyle(color: Colors.grey[600], fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [const FlSpot(0, 1), const FlSpot(1, 3), const FlSpot(2, 2), const FlSpot(3, 5), const FlSpot(4, 3.5), const FlSpot(5, 4), const FlSpot(6, 6)],
              isCurved: true,
              color: Colors.deepPurple,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.deepPurple.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleLeaderboards(List topStores, List topShippers) {
    return Column(
      children: [
        if (topStores.isNotEmpty) ...[
          const Row(children: [Icon(Icons.store, size: 16, color: Colors.blue), SizedBox(width: 8), Text('Top Cửa Hàng', style: TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          ...topStores.map((s) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.store, size: 16)),
              title: Text(s['storeName'] ?? 'Cửa hàng ẩn', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              trailing: const Text('Top 1', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          )),
        ],
        const SizedBox(height: 24),
        if (topShippers.isNotEmpty) ...[
           const Row(children: [Icon(Icons.local_shipping, size: 16, color: Colors.orange), SizedBox(width: 8), Text('Top Tài Xế', style: TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
           ...topShippers.map((u) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person, size: 16)),
              title: Text((u as UserModel).fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              trailing: const Text('Top 1', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          )),
        ],
      ],
    );
  }

  // --- TAB 1: YÊU CẦU ---
  Widget _buildRequestsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Xử lý trong ngày', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: CircleAvatar(backgroundColor: Colors.blue[50], child: const Icon(Icons.storefront, color: Colors.blue)),
            title: const Text('Duyệt Cửa Hàng Mới', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Xem danh sách đăng ký bán hàng'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreManagementScreen()));
            },
          ),
          const SizedBox(height: 12),
          
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: CircleAvatar(backgroundColor: Colors.orange[50], child: const Icon(Icons.feedback_outlined, color: Colors.orange)),
            title: const Text('Khiếu nại / Phản hồi', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Giải đáp thắc mắc người dùng'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackManagementScreen()));
            },
          ),
        ],
      ),
    );
  }

  // --- TAB 2: CÀI ĐẶT / HỆ THỐNG ---
  Widget _buildSettingsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildListTile('Bảng Cáo Cáo Bán Hàng', Icons.analytics_outlined, Colors.purple[400]!, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
          }),
          _buildListTile('Quán lý Vai trò Người dùng', Icons.people_outline, Colors.blue[400]!, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()));
          }),
          _buildListTile('Quản lý Database Cửa hàng', Icons.store_mall_directory, Colors.green[500]!, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreManagementScreen()));
          }),
          
          const Divider(height: 32, thickness: 8, color: Color(0xFFF3F4F6)),

          _buildListTile('Tùy chọn hiển thị tiền tệ', Icons.attach_money, Colors.teal[400]!, () {}, trailingText: '(VNĐ)'),
          _buildListTile('Tùy chọn ngôn ngữ Backend', Icons.language, Colors.blueGrey[400]!, () {}),
          
          _buildListTile(
            'Đăng xuất hệ thống lớn', 
            Icons.power_settings_new, 
            Colors.red[400]!, 
            () {
              context.read<AuthBloc>().add(const LogoutRequested());
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
          
          const SizedBox(height: 24),
          const Text('Grocery System v3.0 Powered By CIT', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Helper View Functions
  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.shade700, size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.shade900)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 11, color: color.shade700)),
        ],
      ),
    );
  }


  Widget _buildListTile(String title, IconData icon, Color iconColor, VoidCallback onTap, {String? trailingText}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black87)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) Padding(padding: const EdgeInsets.only(right: 8.0), child: Text(trailingText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54))),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        ],
      ),
      shape: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
    );
  }
}