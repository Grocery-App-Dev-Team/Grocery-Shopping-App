// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String?,
      stock: (json['stock'] as num?)?.toInt(),
      unit: json['unit'] as String?,
      storeId: json['storeId'] as String?,
      storeName: json['storeName'] as String?,
      isActive: json['isActive'] as bool?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      units: (json['units'] as List<dynamic>?)
          ?.map((e) => ProductUnitMapping.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'imageUrl': instance.imageUrl,
      'category': instance.category,
      'stock': instance.stock,
      'unit': instance.unit,
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'isActive': instance.isActive,
      'status': instance.status,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'units': instance.units,
    };

ProductUnitMapping _$ProductUnitMappingFromJson(Map<String, dynamic> json) =>
    ProductUnitMapping(
      id: json['id'] as String?,
      unitLabel: json['unitName'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      stockQuantity: (json['stockQuantity'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      unitCode: json['unitCode'] as String?,
      baseQuantity: (json['baseQuantity'] as num?)?.toDouble(),
      baseUnit: json['baseUnit'] as String?,
    );

Map<String, dynamic> _$ProductUnitMappingToJson(ProductUnitMapping instance) =>
    <String, dynamic>{
      'id': instance.id,
      'unitName': instance.unitLabel,
      'price': instance.price,
      'stockQuantity': instance.stockQuantity,
      'isActive': instance.isActive,
      'isDefault': instance.isDefault,
      'unitCode': instance.unitCode,
      'baseQuantity': instance.baseQuantity,
      'baseUnit': instance.baseUnit,
    };

CreateProductRequest _$CreateProductRequestFromJson(
        Map<String, dynamic> json) =>
    CreateProductRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String?,
      stock: (json['stock'] as num?)?.toInt(),
      unit: json['unit'] as String?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$CreateProductRequestToJson(
        CreateProductRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'imageUrl': instance.imageUrl,
      'category': instance.category,
      'stock': instance.stock,
      'unit': instance.unit,
      'isActive': instance.isActive,
    };

UpdateProductRequest _$UpdateProductRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateProductRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String?,
      stock: (json['stock'] as num?)?.toInt(),
      unit: json['unit'] as String?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$UpdateProductRequestToJson(
        UpdateProductRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'imageUrl': instance.imageUrl,
      'category': instance.category,
      'stock': instance.stock,
      'unit': instance.unit,
      'isActive': instance.isActive,
    };
