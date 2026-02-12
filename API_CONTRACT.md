# 📝 API CONTRACT - Frontend & Backend Sync

## 🔗 Base Information

**Backend URL**: `http://localhost:8080/api`  
**Database**: MySQL  
**Authentication**: JWT Bearer Token  
**Response Format**: JSON with `ApiResponse<T>` wrapper

---

## 📦 Standard Response Format

All API responses follow this structure:

```json
{
  "success": true,
  "message": "Thành công",
  "data": { ... },
  "errorCode": null
}
```

### Success Response:
```json
{
  "success": true,
  "message": "Đăng nhập thành công",
  "data": {
    "token": "eyJhbGciOiJIUzUxMiJ9...",
    "userId": 1,
    "phoneNumber": "0901234567",
    "fullName": "Nguyễn Văn A",
    "role": "CUSTOMER"
  }
}
```

### Error Response:
```json
{
  "success": false,
  "message": "Số điện thoại hoặc mật khẩu không đúng",
  "data": null,
  "errorCode": "AUTH_001"
}
```

---

## ✅ AUTH MODULE (Ready)

### POST `/auth/register`
**Status**: ✅ Ready  
**Request Body**:
```json
{
  "phoneNumber": "0901234567",
  "password": "123456",
  "fullName": "Nguyễn Văn A",
  "role": "CUSTOMER",
  "address": "123 Nguyễn Huệ, Q1, TP.HCM",
  "avatarUrl": null,
  "storeName": null,
  "storeAddress": null
}
```

**Response**:
```json
{
  "success": true,
  "message": "Đăng ký thành công",
  "data": {
    "token": "eyJhbGci...",
    "type": "Bearer",
    "userId": 1,
    "phoneNumber": "0901234567",
    "fullName": "Nguyễn Văn A",
    "role": "CUSTOMER",
    "avatarUrl": null
  }
}
```

### POST `/auth/login`
**Status**: ✅ Ready  
**Request Body**:
```json
{
  "phoneNumber": "0901234567",
  "password": "123456"
}
```

**Response**: Same as register

### GET `/auth/me`
**Status**: ✅ Ready  
**Headers**: `Authorization: Bearer {token}`  
**Response**:
```json
{
  "success": true,
  "message": "Lấy thông tin user thành công",
  "data": {
    "id": 1,
    "phoneNumber": "0901234567",
    "fullName": "Nguyễn Văn A",
    "avatarUrl": null,
    "address": "123 Nguyễn Huệ",
    "role": "CUSTOMER",
    "status": "ACTIVE",
    "createdAt": "2026-02-12T10:00:00",
    "updatedAt": "2026-02-12T10:00:00"
  }
}
```

---

## ✅ USER MODULE (Ready)

### GET `/users/profile`
**Status**: ✅ Ready  
**Auth**: Required  
**Response**: Same as `/auth/me`

### PUT `/users/profile`
**Status**: ✅ Ready  
**Auth**: Required  
**Request Body**:
```json
{
  "fullName": "Nguyễn Văn B",
  "address": "456 Lê Lợi",
  "avatarUrl": "https://example.com/avatar.jpg"
}
```

### POST `/users/change-password`
**Status**: ✅ Ready  
**Auth**: Required  
**Request Body**:
```json
{
  "oldPassword": "123456",
  "newPassword": "654321",
  "confirmPassword": "654321"
}
```

### GET `/users` (Admin only)
**Status**: ✅ Ready  
**Auth**: Required (ADMIN role)  
**Response**:
```json
{
  "success": true,
  "message": "Lấy danh sách users thành công",
  "data": [
    {
      "id": 1,
      "phoneNumber": "0901234567",
      "fullName": "Nguyễn Văn A",
      "role": "CUSTOMER",
      "status": "ACTIVE"
    }
  ]
}
```

---

## ✅ STORE MODULE (90% Ready)

### GET `/stores`
**Status**: ✅ Ready  
**Auth**: Public  
**Query Params**: None  
**Response**:
```json
{
  "success": true,
  "message": "Lấy danh sách cửa hàng thành công",
  "data": [
    {
      "id": 1,
      "ownerId": 2,
      "ownerName": "Trần Thị B",
      "ownerPhone": "0902345678",
      "storeName": "Tạp hóa Cô Ba",
      "address": "456 Lê Lợi, Q1",
      "isOpen": true
    }
  ]
}
```

### GET `/stores/{id}`
**Status**: ✅ Ready  
**Auth**: Public  
**Response**: Single store object

### GET `/stores/my-store`
**Status**: ✅ Ready  
**Auth**: Required (STORE role)  
**Response**: Single store object

### PUT `/stores/{id}`
**Status**: ✅ Ready  
**Auth**: Required (STORE owner)  
**Request Body**:
```json
{
  "storeName": "Tạp hóa Cô Ba Updated",
  "address": "456 Lê Lợi, Q1, TP.HCM"
}
```

### GET `/stores/search?keyword={keyword}`
**Status**: ✅ Ready  
**Auth**: Public

---

## ⏳ PRODUCT MODULE (Pending)

### GET `/products`
**Status**: ❌ Pending  
**Priority**: HIGH  
**Auth**: Public  
**Query Params**:
- `page` (default: 0)
- `size` (default: 20)
- `category` (optional)
- `search` (optional)

**Expected Response**:
```json
{
  "success": true,
  "message": "Lấy danh sách sản phẩm thành công",
  "data": {
    "content": [
      {
        "id": 1,
        "storeId": 1,
        "storeName": "Tạp hóa Cô Ba",
        "categoryId": 1,
        "categoryName": "Thịt, Cá, Trứng",
        "name": "Thịt ba rọi heo",
        "description": "Thịt tươi ngon",
        "imageUrl": "https://...",
        "status": "AVAILABLE",
        "units": [
          {
            "id": 1,
            "unitName": "Gói 300g",
            "price": 35000.00,
            "stockQuantity": 50
          }
        ]
      }
    ],
    "totalPages": 5,
    "totalElements": 100,
    "size": 20,
    "number": 0
  }
}
```

### GET `/products/{id}`
**Status**: ❌ Pending  
**Priority**: HIGH  
**Auth**: Public

### POST `/products` (Store owner)
**Status**: ❌ Pending  
**Priority**: HIGH  
**Auth**: Required (STORE role)  
**Request Body**:
```json
{
  "categoryId": 1,
  "name": "Thịt ba rọi heo",
  "description": "Thịt tươi ngon",
  "imageUrl": "https://...",
  "units": [
    {
      "unitName": "Gói 300g",
      "price": 35000.00,
      "stockQuantity": 50
    }
  ]
}
```

### GET `/categories`
**Status**: ❌ Pending  
**Priority**: MEDIUM  
**Auth**: Public  
**Expected Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Thịt, Cá, Trứng",
      "iconUrl": "https://..."
    }
  ]
}
```

---

## ⏳ ORDER MODULE (Pending - Most Critical)

### POST `/orders`
**Status**: ❌ Pending  
**Priority**: CRITICAL  
**Auth**: Required (CUSTOMER role)  
**Request Body**:
```json
{
  "storeId": 1,
  "deliveryAddress": "123 Nguyễn Huệ, Q1",
  "shippingFee": 15000.00,
  "items": [
    {
      "productUnitId": 1,
      "quantity": 2,
      "unitPrice": 35000.00
    }
  ]
}
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Đặt hàng thành công",
  "data": {
    "id": 1,
    "customerId": 1,
    "storeId": 1,
    "status": "PENDING",
    "totalAmount": 70000.00,
    "shippingFee": 15000.00,
    "deliveryAddress": "123 Nguyễn Huệ",
    "items": [...],
    "createdAt": "2026-02-12T10:00:00"
  }
}
```

### GET `/orders/my-orders`
**Status**: ❌ Pending  
**Priority**: HIGH  
**Auth**: Required (CUSTOMER role)

### PATCH `/orders/{id}/confirm`
**Status**: ❌ Pending  
**Priority**: HIGH  
**Auth**: Required (STORE owner)

### PATCH `/orders/{id}/accept`
**Status**: ❌ Pending  
**Priority**: HIGH  
**Auth**: Required (SHIPPER role)

### POST `/orders/{id}/complete`
**Status**: ❌ Pending  
**Priority**: HIGH  
**Auth**: Required (SHIPPER role)  
**Request Body**:
```json
{
  "podImageUrl": "https://..."
}
```

---

## ⏳ PAYMENT MODULE (Pending)

### POST `/payments`
**Status**: ❌ Pending  
**Priority**: HIGH  
**Auth**: Required  
**Request Body**:
```json
{
  "orderId": 1,
  "paymentMethod": "MOMO",
  "amount": 85000.00
}
```

### GET `/payments/order/{orderId}`
**Status**: ❌ Pending  
**Priority**: MEDIUM

---

## ⏳ REVIEW MODULE (Pending)

### POST `/reviews`
**Status**: ❌ Pending  
**Priority**: MEDIUM  
**Auth**: Required (CUSTOMER role)  
**Request Body**:
```json
{
  "orderId": 1,
  "storeId": 1,
  "rating": 5,
  "comment": "Tuyệt vời!"
}
```

### GET `/reviews/store/{storeId}`
**Status**: ❌ Pending  
**Priority**: MEDIUM

---

## 🔧 ADDITIONAL SERVICES NEEDED

### File Upload Service
**Status**: ❌ Not Started  
**Priority**: HIGH  
**Endpoints Needed**:
- `POST /files/upload` - Upload single file
- `POST /files/upload-multiple` - Upload multiple files
- Use for: avatars, product images, POD images

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "url": "https://storage.example.com/images/abc123.jpg",
    "filename": "product-image.jpg",
    "size": 1024000
  }
}
```

### WebSocket for Real-time Updates
**Status**: ❌ Not Started  
**Priority**: MEDIUM  
**Endpoints Needed**:
- WebSocket connection: `ws://localhost:8080/ws`
- Topics:
  - `/topic/order/{orderId}` - Order status updates
  - `/topic/shipper/{shipperId}` - New order notifications

### Push Notifications (FCM)
**Status**: ❌ Not Started  
**Priority**: MEDIUM  
**Backend Needs**:
- Firebase Admin SDK setup
- Store FCM tokens in database
- Send notifications on order events

---

## 📋 DATA TYPES REFERENCE

### Enums

**UserRole**:
- `CUSTOMER`
- `SHIPPER`
- `STORE`
- `ADMIN`

**UserStatus**:
- `ACTIVE`
- `BANNED`

**ProductStatus**:
- `AVAILABLE`
- `OUT_OF_STOCK`
- `HIDDEN`

**OrderStatus**:
- `PENDING` - Chờ xác nhận
- `CONFIRMED` - Đã xác nhận
- `PICKING_UP` - Đang lấy hàng
- `DELIVERING` - Đang giao
- `DELIVERED` - Hoàn thành
- `CANCELLED` - Đã hủy

**PaymentMethod**:
- `COD` - Tiền mặt
- `MOMO` - Ví MoMo

**PaymentStatus**:
- `PENDING`
- `SUCCESS`
- `FAILED`
- `REFUNDED`

---

## 🔐 Authentication Headers

All protected endpoints require:

```
Authorization: Bearer eyJhbGciOiJIUzUxMiJ9...
```

Token expires after: **24 hours** (86400000ms)

---

## ❌ Error Codes Reference

| Code | Message | HTTP Status |
|------|---------|-------------|
| AUTH_001 | Số điện thoại hoặc mật khẩu không đúng | 401 |
| AUTH_002 | Token không hợp lệ hoặc đã hết hạn | 401 |
| AUTH_003 | Tài khoản đã bị khóa | 403 |
| USER_001 | Không tìm thấy user | 404 |
| STORE_001 | Không tìm thấy cửa hàng | 404 |
| PRODUCT_001 | Không tìm thấy sản phẩm | 404 |
| ORDER_001 | Không tìm thấy đơn hàng | 404 |
| VALIDATION_001 | Dữ liệu không hợp lệ | 400 |

---

## 📝 Development Notes

### For Backend Team:
1. Prioritize Product module APIs (needed for frontend product screens)
2. Order module is most critical - implement with state machine
3. Add Swagger documentation for all endpoints
4. Implement proper pagination (Spring Data Page)
5. Add CORS configuration for Flutter app

### For Frontend Team:
1. Can start with Auth & User screens immediately
2. Mock Product & Order data until APIs are ready
3. Use Dio interceptor for token management
4. Implement Hive caching for offline support
5. Prepare for real-time features (WebSocket client)

### Testing Strategy:
1. Backend: Write unit tests for services
2. Frontend: Use mock API services during development
3. Integration: Test with Postman/Insomnia first
4. E2E: Test full user flows when both teams are ready

---

**Last Updated**: 2026-02-12  
**Next Sync Meeting**: TBD  
**Status**: Auth & User modules synced ✅ | Product & Order modules pending ⏳
