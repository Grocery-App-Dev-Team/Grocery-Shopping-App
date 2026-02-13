# Phase 1 Setup Script - Grocery Shopping App
# Chạy từng lệnh theo thứ tự

echo "🚀 Bắt đầu Phase 1: Project Setup & Core Infrastructure"

# Bước 1: Tạo Flutter project
echo "📱 Tạo Flutter project..."
flutter create grocery_shopping_app
cd grocery_shopping_app

# Bước 2: Tạo cấu trúc thư mục
echo "📁 Tạo cấu trúc thư mục..."

# Xóa files không cần thiết
rm lib/main.dart
rm -rf test/

# Tạo core folders
mkdir -p lib/core/constants
mkdir -p lib/core/errors
mkdir -p lib/core/network
mkdir -p lib/core/theme
mkdir -p lib/core/utils

# Tạo features folders
mkdir -p lib/features/auth/data/datasources
mkdir -p lib/features/auth/data/repositories
mkdir -p lib/features/auth/domain/entities
mkdir -p lib/features/auth/domain/usecases
mkdir -p lib/features/auth/presentation/bloc
mkdir -p lib/features/auth/presentation/pages
mkdir -p lib/features/auth/presentation/widgets

mkdir -p lib/features/home/data
mkdir -p lib/features/home/domain
mkdir -p lib/features/home/presentation

mkdir -p lib/features/products/data
mkdir -p lib/features/products/domain
mkdir -p lib/features/products/presentation

mkdir -p lib/features/orders/data
mkdir -p lib/features/orders/domain
mkdir -p lib/features/orders/presentation

mkdir -p lib/features/profile/data
mkdir -p lib/features/profile/domain
mkdir -p lib/features/profile/presentation

# Tạo shared folders
mkdir -p lib/shared/widgets
mkdir -p lib/shared/models
mkdir -p lib/shared/services

# Tạo assets folders
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/fonts

echo "✅ Cấu trúc thư mục đã được tạo"

# Bước 3: Tạo các file cấu hình cơ bản
echo "⚙️ Tạo file cấu hình..."

# Sẽ cần tạo các file:
# - pubspec.yaml
# - analysis_options.yaml
# - lib/core/constants/app_constants.dart
# - lib/core/theme/app_colors.dart
# - lib/core/theme/app_theme.dart
# - lib/core/network/network_config.dart
# - lib/core/errors/failures.dart
# - lib/main.dart

echo "📋 Cần tạo các file sau (sẽ được hướng dẫn tiếp theo):"
echo "1. pubspec.yaml - Dependencies"
echo "2. analysis_options.yaml - Linting rules"
echo "3. Core constants và theme files"
echo "4. Network configuration"
echo "5. Error handling"
echo "6. Main app file"

echo "🔧 Tiếp theo: Copy nội dung các file từ FRONTEND_PLAN vào project"

# Bước 4: Cài đặt dependencies
echo "📦 Sau khi tạo pubspec.yaml, chạy:"
echo "flutter pub get"

# Bước 5: Test chạy app
echo "🏃‍♂️ Test chạy app:"
echo "flutter run"

echo ""
echo "📝 CHECKLIST Phase 1:"
echo "□ Tạo Flutter project"
echo "□ Tạo cấu trúc thư mục"
echo "□ Cấu hình pubspec.yaml"
echo "□ Cấu hình analysis_options.yaml"
echo "□ Tạo app constants"
echo "□ Tạo theme system"
echo "□ Tạo network config"
echo "□ Tạo error handling"
echo "□ Tạo base widgets"
echo "□ Tạo main.dart"
echo "□ Test chạy app thành công"
