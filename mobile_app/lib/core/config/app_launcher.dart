import 'package:flutter/material.dart';
import '../../../core/enums/app_type.dart';

class AppConfiguration {
  final int primaryColor;
  final String appName;
  final String appId;
  final List<String> allowedRoutes;

  const AppConfiguration({
    required this.primaryColor,
    required this.appName,
    required this.appId,
    this.allowedRoutes = const [],
  });
}

class AppConfig {
  static AppType currentApp = AppType.customer;

  static final Map<AppType, AppConfiguration> _configs = {
    AppType.customer: const AppConfiguration(
      primaryColor: 0xFF4CAF50,
      appName: 'Đi Chợ Hộ - Khách Hàng',
      appId: 'com.dichohho.customer',
      allowedRoutes: ['/home', '/auth'],
    ),
    AppType.store: const AppConfiguration(
      primaryColor: 0xFF2196F3,
      appName: 'Đi Chợ Hộ - Chủ Cửa Hàng',
      appId: 'com.dichohho.store',
      allowedRoutes: ['/store', '/auth'],
    ),
    AppType.shipper: const AppConfiguration(
      primaryColor: 0xFFFF9800,
      appName: 'Đi Chợ Hộ - Shipper',
      appId: 'com.dichohho.shipper',
      allowedRoutes: ['/shipper', '/auth'],
    ),
    AppType.admin: const AppConfiguration(
      primaryColor: 0xFF9C27B0,
      appName: 'Đi Chợ Hộ - Quản Trị Viên',
      appId: 'com.dichohho.admin',
      allowedRoutes: ['/admin', '/auth'],
    ),
  };

  static AppConfiguration getConfig(AppType type) => _configs[type]!;
  static AppConfiguration get current => getConfig(currentApp);
  static void switchApp(AppType type) => currentApp = type;

  static String get appName => current.appName;
  static String get appId => current.appId;
}

class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    const apps = AppType.values; // use const to satisfy prefer_const_declarations
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose App'),
        backgroundColor: Colors.grey[800],
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
            final config = AppConfig.getConfig(appType);
            return _buildAppCard(context, appType, config);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, AppType appType, AppConfiguration config) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _launchApp(context, appType),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(config.primaryColor),
                // avoid deprecated withOpacity; use withAlpha (191 == 0.75*255)
                Color(config.primaryColor).withAlpha(191),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getAppIcon(appType),
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                config.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                // directly use display helper (remove unnecessary type-check)
                _displayName(appType),
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

  String _displayName(AppType appType) {
    try {
      final dynamic dyn = appType;
      final value = dyn.displayName;
      if (value is String) return value;
    } catch (_) {}
    final parts = appType.toString().split('.');
    return parts.isNotEmpty ? _capitalize(parts.last) : appType.toString();
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  void _launchApp(BuildContext context, AppType appType) {
    AppConfig.switchApp(appType);
    Navigator.of(context).pushReplacementNamed('/app');
  }
}