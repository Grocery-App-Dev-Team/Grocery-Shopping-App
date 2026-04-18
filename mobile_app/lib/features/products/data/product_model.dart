import 'package:json_annotation/json_annotation.dart';
<<<<<<< Updated upstream
=======
import 'package:flutter/foundation.dart';
import 'unit_model.dart';
>>>>>>> Stashed changes

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final String? id;
  final String? name;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String? category;
  final int? stock;
  final String? unit;
  final String? storeId;
  final String? storeName;
  final bool? isActive;
  /// Backend: AVAILABLE | OUT_OF_STOCK | HIDDEN (ProductResponse.status)
  final String? status;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const ProductModel({
    this.id,
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.category,
    this.stock,
    this.unit,
    this.storeId,
    this.storeName,
    this.isActive,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
<<<<<<< Updated upstream
    // Handle nested units structure from backend if present
    double? price;
    int? stock;
    String? unit;
    
    final units = json['units'];
    if (units is List && units.isNotEmpty) {
      final firstUnit = units.first;
      if (firstUnit is Map<String, dynamic>) {
        price = (firstUnit['price'] as num?)?.toDouble();
        stock = firstUnit['stockQuantity'] as int?;
        unit = firstUnit['unitName'] as String?;
=======
    debugPrint('DEBUG: ProductModel.fromJson - id: ${json['id']}, name: ${json['name']}');
    // Lấy giá trị cơ bản trước (fallback)
    final double? price = (json['price'] ?? json['unitPrice'] as num?)?.toDouble();
    int? stock = (json['stock'] ?? json['stockQuantity'] ?? json['quantity'] as num?)?.toInt();
    String? unit = json['unit'] as String?;

    debugPrint('DEBUG: Fallback price: $price, stock: $stock');

    // Parse units list nếu có
    List<ProductUnitMapping>? unitsList;
    final unitsJson =
        json['units'] ?? json['productUnits'] ?? json['productUnitMappings'];

    debugPrint('DEBUG: unitsJson is List: ${unitsJson is List}, length: ${unitsJson is List ? unitsJson.length : 0}');

    if (unitsJson is List && unitsJson.isNotEmpty) {
      try {
        unitsList = [];
        for (final u in unitsJson) {
           if (u is Map<String, dynamic>) {
             unitsList.add(ProductUnitMapping.fromJson(u));
           }
        }

        // Nếu có units, lọc ra đơn vị active
        final activeUnits = unitsList.where((u) => u.isActive).toList();
        debugPrint('DEBUG: activeUnits length: ${activeUnits.length}');

        // Nếu có units, lấy giá/tồn từ đơn vị mặc định hoặc đơn vị đầu tiên.
        if (activeUnits.isNotEmpty) {
          final defaultUnit = activeUnits.firstWhere(
            (u) => u.isDefault,
            orElse: () => activeUnits.first,
          );
          
          debugPrint('DEBUG: defaultUnit found - price: ${defaultUnit.price}, stock: ${defaultUnit.stockQuantity}');

          // Only override if top-level fields were null
          final bool? isActiveRaw = json['isActive'] as bool?;
          final String? statusRaw = json['status'] as String?;
          
          return ProductModel(
            id: json['id']?.toString(),
            name: json['name'] as String?,
            description: json['description'] as String?,
            price: price ?? defaultUnit.price,
            imageUrl: json['imageUrl'] as String?,
            category: json['categoryName'] ?? json['category'] as String?,
            stock: stock ?? defaultUnit.stockQuantity,
            unit: unit ?? defaultUnit.displayName,
            storeId: (json['storeId'] ?? json['store_id'])?.toString(),
            storeName: json['storeName'] ?? json['store_name'],
            isActive: isActiveRaw ?? (statusRaw != 'HIDDEN'),
            status: statusRaw,
            createdAt: json['created_at'] as String?,
            updatedAt: json['updated_at'] as String?,
            units: activeUnits,
          );
        }
      } catch (e) {
        debugPrint('DEBUG: Error parsing units: $e');
>>>>>>> Stashed changes
      }
    } else {
      // Fallback to flat structure
      price = (json['price'] as num?)?.toDouble();
      stock = (json['stock'] ?? json['stockQuantity']) as int?;
      unit = json['unit'] as String?;
    }

    debugPrint('DEBUG: Returning fallback ProductModel');
    final statusStr = json['status'] as String?;
    return ProductModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: price,
      imageUrl: json['imageUrl'] as String?,
      category: json['categoryName'] ?? json['category'] as String?,
      stock: stock,
      unit: unit,
      storeId: (json['storeId'] ?? json['store_id'])?.toString(),
      storeName: json['storeName'] ?? json['store_name'],
      isActive: (json['isActive'] as bool?) ?? (statusStr != 'HIDDEN'),
      status: statusStr,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'category': category,
    'stock': stock,
    'unit': unit,
    'storeId': storeId,
    'storeName': storeName,
    'isActive': isActive,
    'status': status,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

@JsonSerializable()
class CreateProductRequest {
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? category;
  final int? stock;
  final String? unit;
  final bool? isActive;

  const CreateProductRequest({
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category,
    this.stock,
    this.unit,
    this.isActive,
  });

  factory CreateProductRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateProductRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateProductRequestToJson(this);
}

@JsonSerializable()
class UpdateProductRequest {
  final String? name;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String? category;
  final int? stock;
  final String? unit;
  final bool? isActive;

  const UpdateProductRequest({
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.category,
    this.stock,
    this.unit,
    this.isActive,
  });

  factory UpdateProductRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProductRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateProductRequestToJson(this);
}
