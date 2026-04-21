import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

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
  
  /// Variants/Units list from backend
  final List<ProductUnitMapping>? units;

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
    this.units,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    debugPrint('DEBUG: ProductModel.fromJson - id: ${json['id']}, name: ${json['name']}');
    
    // Fallback basic values
    final double? topLevelPrice = (json['price'] ?? json['unitPrice'] as num?)?.toDouble();
    final int? topLevelStock = (json['stock'] ?? json['stockQuantity'] ?? json['quantity'] as num?)?.toInt();
    final String? topLevelUnit = json['unit'] as String?;

    // Parse units list if present
    List<ProductUnitMapping>? unitsList;
    final unitsJson = json['units'] ?? json['productUnits'] ?? json['productUnitMappings'];

    if (unitsJson is List && unitsJson.isNotEmpty) {
      try {
        unitsList = unitsJson
            .where((u) => u is Map<String, dynamic>)
            .map((u) => ProductUnitMapping.fromJson(u as Map<String, dynamic>))
            .toList();

        // Filter active units
        final activeUnits = unitsList.where((u) => u.isActive).toList();

        if (activeUnits.isNotEmpty) {
          final defaultUnit = activeUnits.firstWhere(
            (u) => u.isDefault,
            orElse: () => activeUnits.first,
          );
          
          final bool? isActiveRaw = json['isActive'] as bool?;
          final String? statusRaw = json['status'] as String?;
          
          return ProductModel(
            id: json['id']?.toString(),
            name: json['name'] as String?,
            description: json['description'] as String?,
            price: topLevelPrice ?? defaultUnit.price,
            imageUrl: json['imageUrl'] as String?,
            category: json['categoryName'] ?? json['category'] as String?,
            stock: topLevelStock ?? defaultUnit.stockQuantity,
            unit: topLevelUnit ?? defaultUnit.displayName,
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
      }
    }

    // Fallback to flat structure
    final statusStr = json['status'] as String?;
    return ProductModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: topLevelPrice,
      imageUrl: json['imageUrl'] as String?,
      category: json['categoryName'] ?? json['category'] as String?,
      stock: topLevelStock,
      unit: topLevelUnit,
      storeId: (json['storeId'] ?? json['store_id'])?.toString(),
      storeName: json['storeName'] ?? json['store_name'],
      isActive: (json['isActive'] as bool?) ?? (statusStr != 'HIDDEN'),
      status: statusStr,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      units: unitsList,
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
    'units': units?.map((e) => e.toJson()).toList(),
  };
}

@JsonSerializable()
class ProductUnitMapping {
  final String? id;
  @JsonKey(name: 'unitName')
  final String? unitLabel;
  final double? price;
  final int? stockQuantity;
  final bool isActive;
  final bool isDefault;
  final String? unitCode;
  final double? baseQuantity;
  final String? baseUnit;

  ProductUnitMapping({
    this.id,
    this.unitLabel,
    this.price,
    this.stockQuantity,
    this.isActive = true,
    this.isDefault = false,
    this.unitCode,
    this.baseQuantity,
    this.baseUnit,
  });

  factory ProductUnitMapping.fromJson(Map<String, dynamic> json) =>
      _$ProductUnitMappingFromJson(json);

  Map<String, dynamic> toJson() => _$ProductUnitMappingToJson(this);

  String get displayName => unitLabel ?? '';
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
