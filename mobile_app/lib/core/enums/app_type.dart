enum AppType {
  customer,  // App riêng cho khách hàng
  store,     // App riêng cho chủ cửa hàng  
  shipper,   // App riêng cho shipper
  admin,     // Web app riêng cho admin
}

extension AppTypeExt on AppType {
  String get displayName {
    switch (this) {
      case AppType.customer:
        return 'Customer';
      case AppType.store:
        return 'Store';
      case AppType.shipper:
        return 'Shipper';
      case AppType.admin:
        return 'Admin';
    }
  }

  /// String used by backend / permission mapping
  String get roleString {
    switch (this) {
      case AppType.customer:
        return 'customer';
      case AppType.store:
        return 'store_owner';
      case AppType.shipper:
        return 'shipper';
      case AppType.admin:
        return 'admin';
    }
  }
}