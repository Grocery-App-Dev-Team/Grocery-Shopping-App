# 📋 BACKEND DEVELOPMENT PLAN - Grocery Shopping App

## ✅ ĐÃ HOÀN THÀNH (Completed)

### Module 1: Authentication & Authorization ✅
- [x] User Entity với roles (CUSTOMER, SHIPPER, STORE, ADMIN)
- [x] JWT Token Provider
- [x] Security Configuration (Spring Security)
- [x] Authentication Filter
- [x] Custom UserDetailsService
- [x] Register API
- [x] Login API
- [x] Get Current User API (/auth/me)
- [x] Logout API
- [x] Refresh Token API
- [x] DTOs: LoginRequest, RegisterRequest, AuthResponse
- [x] Custom Exceptions: ResourceNotFoundException, BadRequestException, UnauthorizedException
- [x] GlobalExceptionHandler với exception handling đầy đủ

### Module 2: User Management ✅
- [x] UserRepository với custom queries
- [x] UserService với business logic
- [x] UserController với REST APIs
- [x] DTOs: UpdateProfileRequest, ChangePasswordRequest, UserProfileResponse, UserListResponse
- [x] Get Profile API
- [x] Update Profile API
- [x] Change Password API
- [x] Admin: Get All Users
- [x] Admin: Get Users by Role
- [x] Admin: Toggle User Status (Ban/Unban)
- [x] Admin: Delete User

### Module 3: Store Management ✅ (90% HOÀN THÀNH)
- [x] Store Entity
- [x] StoreRepository với custom queries
- [x] Store DTOs (CreateStoreRequest, UpdateStoreRequest, StoreResponse)
- [x] StoreService với business logic
- [x] StoreController với REST APIs
- [x] APIs: GET /stores, GET /stores/{id}, GET /stores/my-store, PUT /stores/{id}, PATCH /stores/{id}/toggle-status, GET /stores/search
- [ ] Một số tối ưu hóa query còn thiếu

### Module 4: Product Management ✅ (100% HOÀN THÀNH)
- [x] **Category Entity** 
  - [x] Review relationships
- [x] **Product Entity** 
  - [x] Review relationships
- [x] **ProductUnit Entity** 
  - [x] Review relationships với OrderItem
- [x] **CategoryRepository**
  - [x] findAll (list categories)
  - [x] findByName
  - [x] existsByName
- [x] **ProductRepository**
  - [x] findByStoreId
  - [x] findByCategoryId ✅ MỚI
  - [x] findByStatus
  - [x] searchByKeyword
  - [x] findByStoreIdAndStatus
  - [x] findAvailableProductsByStore
  - [x] countByCategoryId
- [x] **Category DTOs**
  - [x] CreateCategoryRequest
  - [x] UpdateCategoryRequest
  - [x] CategoryResponse
- [x] **Product DTOs**
  - [x] CreateProductRequest
  - [x] UpdateProductRequest
  - [x] ProductResponse (với units)
  - [x] ProductUnitRequest
- [x] **CategoryService**
  - [x] getAllCategories
  - [x] getCategoryById
  - [x] createCategory (admin)
  - [x] updateCategory (admin)
  - [x] deleteCategory (admin)
- [x] **ProductService**
  - [x] createProduct (store owner)
  - [x] updateProduct (store owner)
  - [x] deleteProduct (store owner)
  - [x] getProductById
  - [x] getAllProducts
  - [x] getProductsByStore
  - [x] getProductsByCategory ✅ MỚI
  - [x] getAvailableProductsByStore
  - [x] searchProducts
  - [x] toggleProductStatus
- [x] **CategoryController** - `/api/categories`
  - [x] GET /api/categories (all categories - public)
  - [x] GET /api/categories/{id} (public)
  - [x] POST /api/categories (admin only - @PreAuthorize)
  - [x] PUT /api/categories/{id} (admin only - @PreAuthorize)
  - [x] DELETE /api/categories/{id} (admin only - @PreAuthorize)
- [x] **ProductController** - `/api/products`
  - [x] POST /api/products (store owner - @PreAuthorize)
  - [x] PUT /api/products/{id} (store owner - @PreAuthorize)
  - [x] DELETE /api/products/{id} (store owner - @PreAuthorize)
  - [x] PATCH /api/products/{id}/toggle-status (store owner - @PreAuthorize)
  - [x] GET /api/products (all products - public)
  - [x] GET /api/products/{id} (public)
  - [x] GET /api/products/store/{storeId} (public)
  - [x] GET /api/products/store/{storeId}/available (public)
  - [x] GET /api/products/category/{categoryId} ✅ MỚI (public)
  - [x] GET /api/products/search?keyword=... (public)

---

## 📝 CẦN LÀM (To Do)

### Module 5: Order Management ⏳ (Phức tạp nhất)
- [ ] **Order Entity** (đã có base)
  - [ ] Review relationships
- [ ] **OrderItem Entity** (đã có base)
  - [ ] Review relationships
- [ ] **OrderRepository**
  - [ ] findByCustomerId
  - [ ] findByStoreId
  - [ ] findByShipperId
  - [ ] findByStatus
  - [ ] findByCustomerIdAndStatus
  - [ ] findPendingOrders (for shippers)
- [ ] **OrderItemRepository**
  - [ ] findByOrderId
- [ ] **Order DTOs**
  - [ ] CreateOrderRequest
  - [ ] UpdateOrderRequest
  - [ ] OrderResponse
  - [ ] OrderListResponse
  - [ ] OrderDetailResponse (với OrderItems)
  - [ ] OrderItemRequest
  - [ ] OrderItemResponse
- [ ] **OrderService**
  - [ ] createOrder (customer)
  - [ ] getMyOrders (customer)
  - [ ] getOrderById
  - [ ] getStoreOrders (store owner)
  - [ ] confirmOrder (store owner)
  - [ ] cancelOrder (customer/store)
  - [ ] getPendingOrders (for shippers)
  - [ ] acceptOrder (shipper)
  - [ ] updateOrderStatus (shipper)
  - [ ] completeOrder (shipper - upload POD)
  - [ ] getAllOrders (admin)
  - [ ] calculateTotalAmount
- [ ] **OrderController**
  - [ ] POST /api/orders (create order - customer)
  - [ ] GET /api/orders/my-orders (customer orders)
  - [ ] GET /api/orders/{id} (order detail)
  - [ ] GET /api/orders/store (store orders)
  - [ ] PATCH /api/orders/{id}/confirm (store confirm)
  - [ ] PATCH /api/orders/{id}/cancel (cancel order)
  - [ ] GET /api/orders/pending (pending orders for shippers)
  - [ ] PATCH /api/orders/{id}/accept (shipper accept)
  - [ ] PATCH /api/orders/{id}/status (update status)
  - [ ] POST /api/orders/{id}/complete (complete with POD)
  - [ ] GET /api/admin/orders (all orders - admin)

### Module 6: Payment Management ⏳
- [ ] **Payment Entity** (đã có base)
  - [ ] Review relationships
- [ ] **PaymentRepository**
  - [ ] findByOrderId
  - [ ] findByCustomerId
  - [ ] findByStatus
- [ ] **Payment DTOs**
  - [ ] CreatePaymentRequest
  - [ ] PaymentResponse
  - [ ] PaymentListResponse
- [ ] **PaymentService**
  - [ ] createPayment
  - [ ] getPaymentByOrderId
  - [ ] updatePaymentStatus
  - [ ] processPayment (integration với payment gateway)
  - [ ] refundPayment
- [ ] **PaymentController**
  - [ ] POST /api/payments (create payment)
  - [ ] GET /api/payments/order/{orderId}
  - [ ] GET /api/payments/{id}
  - [ ] PATCH /api/payments/{id}/status
  - [ ] POST /api/payments/{id}/refund (admin)

### Module 7: Review & Rating ⏳
- [ ] **Review Entity** (đã có base)
  - [ ] Review relationships
- [ ] **ReviewRepository**
  - [ ] findByStoreId
  - [ ] findByReviewerId
  - [ ] findByOrderId
  - [ ] calculateAverageRating (custom query)
- [ ] **Review DTOs**
  - [ ] CreateReviewRequest
  - [ ] UpdateReviewRequest
  - [ ] ReviewResponse
  - [ ] ReviewListResponse
- [ ] **ReviewService**
  - [ ] createReview (customer only after order delivered)
  - [ ] updateReview
  - [ ] deleteReview
  - [ ] getReviewsByStore
  - [ ] getMyReviews
  - [ ] getStoreAverageRating
- [ ] **ReviewController**
  - [ ] POST /api/reviews (create review)
  - [ ] PUT /api/reviews/{id}
  - [ ] DELETE /api/reviews/{id}
  - [ ] GET /api/reviews/store/{storeId}
  - [ ] GET /api/reviews/my-reviews
  - [ ] GET /api/reviews/store/{storeId}/rating

---

## 🚀 TÍNH NĂNG BỔ SUNG (Additional Features)

### Phase 1: Core Enhancements
- [ ] **File Upload Service**
  - [ ] Upload avatar
  - [ ] Upload product images
  - [ ] Upload POD images
  - [ ] Integration với cloud storage (AWS S3, Cloudinary, etc.)
- [ ] **Validation & Error Handling**
  - [ ] Custom validators cho phone number
  - [ ] Custom validators cho business rules
  - [ ] Cải thiện error messages
- [ ] **Logging & Monitoring**
  - [ ] Implement proper logging strategy
  - [ ] Add request/response logging
  - [ ] Performance monitoring

### Phase 2: Advanced Features
- [ ] **Search & Filter**
  - [ ] Full-text search cho products
  - [ ] Advanced filtering (price range, category, etc.)
  - [ ] Sorting options
- [ ] **Pagination**
  - [ ] Implement pagination cho all list APIs
  - [ ] Custom PageResponse DTO
- [ ] **Caching**
  - [ ] Redis integration
  - [ ] Cache frequently accessed data (products, stores)
- [ ] **Real-time Features**
  - [ ] WebSocket cho order tracking
  - [ ] Real-time notifications
- [ ] **Statistics & Reports**
  - [ ] Sales statistics (store owner)
  - [ ] Order statistics (admin)
  - [ ] Revenue reports
  - [ ] User activity reports

### Phase 3: Security & Performance
- [ ] **Security Enhancements**
  - [ ] Rate limiting
  - [ ] JWT token blacklist (Redis)
  - [ ] OTP verification cho forgot password
  - [ ] 2FA authentication
- [ ] **Performance Optimization**
  - [ ] Database indexing
  - [ ] Query optimization
  - [ ] Lazy loading vs Eager loading
  - [ ] N+1 query problem solving
- [ ] **Testing**
  - [ ] Unit tests cho Services
  - [ ] Integration tests cho Controllers
  - [ ] Test coverage > 80%

### Phase 4: DevOps & Documentation
- [ ] **API Documentation**
  - [ ] Swagger/OpenAPI integration
  - [ ] API documentation generation
  - [ ] Postman collection
- [ ] **Deployment**
  - [ ] Docker containerization
  - [ ] Docker Compose setup
  - [ ] CI/CD pipeline
  - [ ] Environment configuration (dev/staging/prod)
- [ ] **Database**
  - [ ] Database migration scripts
  - [ ] Seed data cho development
  - [ ] Backup & recovery strategy

---

## 📊 PRIORITY & TIMELINE

### Week 1-2: Core Modules
- [x] Auth Module ✅
- [x] User Module ✅
- [ ] Store Module (3-4 days)
- [ ] Product Module (3-4 days)

### Week 3-4: Business Logic
- [ ] Order Module (5-6 days) - Most complex
- [ ] Payment Module (2-3 days)
- [ ] Review Module (2-3 days)

### Week 5: Testing & Polish
- [ ] Unit tests
- [ ] Integration tests
- [ ] Bug fixes
- [ ] Code refactoring

### Week 6+: Advanced Features
- [ ] File upload
- [ ] Search & pagination
- [ ] Caching
- [ ] Real-time features
- [ ] Statistics & reports

---

## 🎯 NEXT IMMEDIATE TASKS (Prioritized)

1. **Store Module** - Bắt đầu ngay
   - Create StoreRepository với custom queries
   - Create Store DTOs
   - Implement StoreService
   - Implement StoreController
   - Test APIs

2. **Product Module** - Sau Store
   - Create Category system
   - Create ProductRepository
   - Create Product DTOs với ProductUnits
   - Implement ProductService
   - Implement ProductController
   - Test APIs

3. **Order Module** - Core business logic
   - Design order workflow carefully
   - Create OrderRepository với complex queries
   - Create Order DTOs
   - Implement OrderService với state machine
   - Implement OrderController
   - Test order flow end-to-end

---

## 📝 NOTES

- **Code Quality**: Follow SOLID principles, clean code practices
- **Security**: Always validate user permissions for each action
- **Performance**: Consider pagination for all list endpoints
- **Documentation**: Add Javadoc comments for public methods
- **Testing**: Write tests as you develop, not after
- **Git**: Commit frequently with meaningful messages

---

## 🔗 DEPENDENCIES TO ADD (If needed)

```xml
<!-- File Upload -->
<dependency>
    <groupId>commons-io</groupId>
    <artifactId>commons-io</artifactId>
    <version>2.11.0</version>
</dependency>

<!-- Caching (Redis) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>

<!-- WebSocket -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-websocket</artifactId>
</dependency>

<!-- API Documentation (Swagger) -->
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.2.0</version>
</dependency>

<!-- MapStruct for DTO mapping -->
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
    <version>1.5.5.Final</version>
</dependency>
```

---

## 📱 FRONTEND SYNC NOTES

### ✅ APIs Ready for Frontend:
- **Auth APIs** - Frontend có thể bắt đầu code Auth screens
- **User APIs** - Frontend có thể code Profile/Settings screens  
- **Store APIs** - Frontend có thể code Store list/detail screens (90%)

### ⏳ APIs Cần Hoàn Thành Trước:
- **Product APIs** - Cần xong trước khi Frontend code Product screens
- **Order APIs** - Cần xong trước khi Frontend code Shopping cart & checkout
- **Payment APIs** - Cần xong trước khi Frontend integrate MoMo
- **File Upload APIs** - Cần cho avatar, product images, POD photos

### 🔔 Backend Cần Bổ Sung:
- [ ] WebSocket configuration (cho real-time order tracking)
- [ ] Firebase Admin SDK setup (cho push notifications)  
- [ ] File upload service (images to cloud storage)
- [ ] API documentation với Swagger/OpenAPI
- [ ] CORS configuration cho Flutter app

---

**Last Updated**: 2026-02-12
**Progress**: 2/7 modules completed (28%)
**Next Focus**: Product Module → Order Module → Payment Module
**Frontend Status**: Synced with MySQL backend, waiting for Product & Order APIs