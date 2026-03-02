# 📱 App Đi Chợ Hộ - Ứng Dụng Flutter

Ứng dụng di động đa nền tảng được xây dựng bằng Flutter cho dự án App Đi Chợ Hộ.

## 🎯 Tổng Quan Dự Án

Đây là ứng dụng di động đa nền tảng được xây dựng bằng Flutter, phục vụ như giao diện người dùng cho App Đi Chợ Hộ. Ứng dụng hỗ trợ nhiều vai trò người dùng: Khách hàng, Chủ cửa hàng, Shipper và Quản trị viên.

### Công Nghệ Sử Dụng
- **Framework**: Flutter (Đa nền tảng)
- **Ngôn ngữ**: Dart
- **Quản lý trạng thái**: flutter_bloc
- **Điều hướng**: go_router
- **HTTP Client**: Dio
- **Lưu trữ cục bộ**: Hive + SharedPreferences
- **Giao diện**: Material 3 Design System

## 🚀 Bắt Đầu

### Yêu Cầu Trước Khi Chạy

Trước khi chạy ứng dụng này, đảm bảo bạn đã có:

1. **Flutter SDK** (>=3.10.0)
   ```bash
   flutter --version
   ```

2. **Dart SDK** (>=3.0.0)

3. **Môi Trường Phát Triển**:
   - VS Code với Flutter/Dart extensions
   - Hoặc Android Studio với Flutter plugin

4. **Thiết Bị/Emulator**:
   - Thiết bị thật kết nối qua USB
   - Android Emulator
   - iOS Simulator (chỉ macOS)
   - Trình duyệt Chrome (cho web)
   - Windows desktop (cho Windows)

### Cài Đặt

1. **Di chuyển vào thư mục mobile_app**:
   ```bash
   cd mobile_app
   ```

2. **Cài đặt dependencies**:
   ```bash
   flutter pub get
   ```

3. **Kiểm tra Flutter doctor**:
   ```bash
   flutter doctor
   ```

### Chạy Ứng Dụng

#### 🔍 Kiểm Tra Thiết Bị Có Sẵn
```bash
flutter devices
```

#### 📱 Chạy Trên Thiết Bị Di Động/Emulator
```bash
# Chạy trên thiết bị được kết nối (tự động phát hiện)
flutter run

# Chạy trên thiết bị Android cụ thể
flutter run -d android

# Chạy trên iOS Simulator (chỉ macOS)
flutter run -d ios
```

#### 🌐 Chạy Trên Trình Duyệt Web
```bash
# Chạy trên Chrome
flutter run -d chrome

# Chạy trên Edge
flutter run -d edge
```

#### 💻 Chạy Trên Desktop
```bash
# Chạy trên Windows (chỉ Windows)
flutter run -d windows

# Chạy trên macOS (chỉ macOS)
flutter run -d macos

# Chạy trên Linux (chỉ Linux)
flutter run -d linux
```

#### 🔥 Chạy Ở Chế Độ Debug Với Hot Reload
```bash
flutter run --debug
```

Sau khi chạy, bạn có thể:
- Nhấn `r` để hot reload
- Nhấn `R` để hot restart
- Nhấn `h` để xem trợ giúp
- Nhấn `q` để thoát

### Build Cho Release

#### 📱 Build APK (Android)
```bash
flutter build apk --release
```

#### 🍎 Build IPA (iOS - chỉ macOS)
```bash
flutter build ios --release
```

#### 🌐 Build Web
```bash
flutter build web --release
```

#### 💻 Build Desktop
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## 🏗️ Cấu Trúc Dự Án

```
mobile_app/
├── lib/
│   ├── core/                 # Chức năng cốt lõi
│   │   ├── constants/        # Hằng số ứng dụng
│   │   ├── errors/           # Xử lý lỗi
│   │   ├── network/          # Cấu hình API
│   │   ├── theme/            # Chủ đề ứng dụng
│   │   └── utils/            # Hàm tiện ích
│   ├── features/             # Các module tính năng
│   │   ├── auth/             # Xác thực
│   │   ├── home/             # Màn hình chính
│   │   ├── products/         # Quản lý sản phẩm
│   │   ├── orders/           # Quản lý đơn hàng
│   │   └── profile/          # Hồ sơ người dùng
│   ├── shared/               # Thành phần chia sẻ
│   │   ├── widgets/          # Widget có thể tái sử dụng
│   │   ├── models/           # Mô hình dữ liệu
│   │   └── services/         # Dịch vụ chia sẻ
│   └── main.dart             # Điểm vào ứng dụng
├── assets/                   # Tài nguyên tĩnh
│   ├── images/               # Hình ảnh
│   ├── icons/                # Biểu tượng
│   └── fonts/                # Font chữ
├── android/                  # File dành riêng cho Android
├── ios/                      # File dành riêng cho iOS
├── web/                      # File dành riêng cho Web
├── windows/                  # File dành riêng cho Windows
├── pubspec.yaml             # Dependencies
└── README.md                # File này
```

## 🔧 Các Lệnh Phát Triển

### Tạo Code Tự Động
```bash
# Tạo code (JSON serialization, Hive adapters)
dart run build_runner build --delete-conflicting-outputs

# Theo dõi thay đổi và tự động tạo code
dart run build_runner watch --delete-conflicting-outputs
```

### Kiểm Thử
```bash
# Chạy tất cả test
flutter test

# Chạy test với coverage
flutter test --coverage

# Chạy file test cụ thể
flutter test test/widget_test.dart
```

### Phân Tích Code
```bash
# Phân tích code
flutter analyze

# Format code
dart format lib/

# Sửa các vấn đề formatting
dart fix --apply
```

### Dọn Dẹp Build
```bash
# Dọn dẹp build cache
flutter clean

# Cài lại dependencies
flutter pub get
```

## 🐛 Khắc Phục Sự Cố

### Các Vấn Đề Thường Gặp

1. **"Flutter not found" (Không tìm thấy Flutter)**
   ```bash
   # Thêm Flutter vào PATH hoặc cài lại Flutter SDK
   flutter doctor
   ```

2. **"No devices found" (Không tìm thấy thiết bị)**
   ```bash
   # Kiểm tra thiết bị đã kết nối
   flutter devices
   
   # Khởi động Android emulator
   flutter emulators --launch <emulator_id>
   ```

3. **"Pub get failed" (Lỗi pub get)**
   ```bash
   # Xóa pub cache và thử lại
   flutter pub cache clean
   flutter pub get
   ```

4. **"Build failed" (Lỗi build)**
   ```bash
   # Dọn dẹp và build lại
   flutter clean
   flutter pub get
   flutter run
   ```

### Vấn Đề Cấu Hình Firebase
Nếu gặp lỗi liên quan đến Firebase trên web:
1. Các package Firebase tạm thời bị vô hiệu hóa cho Phase 1
2. Chúng sẽ được kích hoạt lại ở Phase 2 khi cần thiết
3. Kiểm tra `pubspec.yaml` cho các Firebase dependencies đã được comment

### Mẹo Hiệu Suất
- Dùng `flutter run --profile` để test hiệu suất
- Dùng `flutter run --release` cho hiệu suất giống production
- Theo dõi bộ nhớ với `flutter run --enable-software-rendering`

## 📋 Trạng Thái Phase 1

✅ **Các Tính Năng Đã Hoàn Thành:**
- [x] Thiết lập dự án với clean architecture
- [x] Cấu hình các dependencies cốt lõi
- [x] Base widgets (Loading, Button, TextField, Dialog, SnackBar)
- [x] Hệ thống theme
- [x] Cấu hình network
- [x] Hệ thống xử lý lỗi

🚧 **Phase Tiếp Theo:** Module Xác Thực (Phase 2)

## 🔗 Tài Liệu Liên Quan

- [README Dự Án Chính](../README.md)
- [Kế Hoạch Backend](../BACKEND_PLAN.md)
- [Kế Hoạch Frontend](../FRONTEND_PLAN.md)
- [Hướng Dẫn Phase 1](../PHASE1_GUIDE.md)

## 🤝 Đóng Góp

1. Tuân theo cấu trúc code hiện có
2. Sử dụng các base widget được cung cấp
3. Tuân theo quy tắc đặt tên Flutter/Dart
4. Chạy `flutter analyze` trước khi commit
5. Viết test cho các tính năng mới

## 📞 Hỗ Trợ

Đối với các vấn đề phát triển:
1. Kiểm tra tài liệu Flutter: https://docs.flutter.dev/
2. Xem lại tài liệu dự án trong thư mục gốc
3. Liên hệ với team phát triển

---

**Thành viên FE🚀**
1. Đàm Thị Ngọc Châu - 3122411020 (Trưởng nhóm)
2. Phan Thị Hải Vân - 3122411243
3. Võ Hoàng Kim Quyên - 3122411173
4. Lê Gia Hân - 3122411049
5. Phan Thị Hồng Nhiên - 3122411141
