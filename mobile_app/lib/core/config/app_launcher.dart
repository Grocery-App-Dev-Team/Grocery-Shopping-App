import 'package:flutter/material.dart';
import '../enums/app_type.dart'; 
import 'app_config.dart';

class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  /// Helper cung cấp màu và tên riêng cho Launcher 
  /// (Vì AppConfig hiện tại chỉ chứa thông tin của App đang build)
  Map<String, dynamic> _getAppUIInfo(AppType type) {
    switch (type) {
      case AppType.customer:
        return {'name': 'Khách Hàng', 'color': 0xFF2E7D32}; // Màu xanh lá
      case AppType.store:
        return {'name': 'Cửa Hàng', 'color': 0xFF1565C0};   // Màu xanh dương
      case AppType.shipper:
        return {'name': 'Giao Hàng', 'color': 0xFFE65100};  // Màu cam
      case AppType.admin:
        return {'name': 'Quản Trị Viên', 'color': 0xFF6A1B9A}; // Màu tím
    }
  }

  @override
  Widget build(BuildContext context) {
    const apps = AppType.values; 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Menu: Khởi động App'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.15,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: apps.map((appType) {
            final uiInfo = _getAppUIInfo(appType);
            return _buildAppCard(context, appType, uiInfo);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, AppType appType, Map<String, dynamic> uiInfo) {
    final Color primaryColor = Color(uiInfo['color']);
    final String appName = uiInfo['name'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _launchApp(context, appType, appName, primaryColor),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                primaryColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getAppIcon(appType),
                size: 42,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                appType.displayName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAppIcon(AppType appType) {
    switch (appType) {
      case AppType.customer:
        return Icons.shopping_cart;
      case AppType.store:
        return Icons.store;
      case AppType.shipper:
        return Icons.local_shipping;
      case AppType.admin:
        return Icons.admin_panel_settings;
    }
  }

  void _launchApp(BuildContext context, AppType appType, String appName, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('App đã build cho: ${AppConfig.appName}. Tham số môi trường: APP=${AppConfig.app}'),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}