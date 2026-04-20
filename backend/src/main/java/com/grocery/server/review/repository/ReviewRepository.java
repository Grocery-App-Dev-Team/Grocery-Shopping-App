package com.grocery.server.review.repository;

import com.grocery.server.review.entity.Review;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository: ReviewRepository
 * Mô tả: Interface truy vấn dữ liệu từ bảng reviews
 */
@Repository
public interface ReviewRepository extends JpaRepository<Review, Long> {

    /**
     * Tìm đánh giá theo ID cửa hàng
     * @param storeId ID cửa hàng
     * @return Danh sách đánh giá theo cửa hàng
     */
    List<Review> findByStoreId(Long storeId);

    Page<Review> findByStoreId(Long storeId, Pageable pageable);

    /**
     * Tìm đánh giá theo ID người đánh giá
     * @param reviewerId ID người đánh giá
     * @return Danh sách đánh giá của người dùng
     */
    List<Review> findByReviewerId(Long reviewerId);

    /**
     * Tìm đánh giá theo ID đơn hàng
     * @param orderId ID đơn hàng
     * @return Đánh giá của đơn hàng (nếu có)
     */
    Optional<Review> findByOrderId(Long orderId);

    /**
     * Kiểm tra đơn hàng đã có đánh giá chưa
     * @param orderId ID đơn hàng
     * @return true nếu đã có đánh giá
     */
    boolean existsByOrderId(Long orderId);

    /**
     * Tính điểm trung bình của cửa hàng
     * @param storeId ID cửa hàng
     * @return Điểm trung bình (null nếu chưa có đánh giá)
     */
    @Query("SELECT AVG(r.rating) FROM Review r WHERE r.store.id = :storeId")
    Double calculateAverageRating(@Param("storeId") Long storeId);

    /**
     * Đếm số lượng đánh giá của cửa hàng
     * @param storeId ID cửa hàng
     * @return Số lượng đánh giá
     */
    long countByStoreId(Long storeId);

    /**
     * Lấy rating trung bình và tổng số đánh giá của TẤT CẢ cửa hàng trong 1 query
     * Tránh N+1 khi hiển thị danh sách stores
     * @return List<Object[]> với mỗi row = [storeId, avgRating, totalReviews]
     */
    @Query("SELECT r.store.id, AVG(r.rating), COUNT(r) FROM Review r GROUP BY r.store.id")
    List<Object[]> calculateAllStoreRatings();

    /**
     * Lấy rating trung bình và tổng số đánh giá cho danh sách storeIds cụ thể
     * @param storeIds Danh sách ID cửa hàng
     * @return List<Object[]> với mỗi row = [storeId, avgRating, totalReviews]
     */
    @Query("SELECT r.store.id, AVG(r.rating), COUNT(r) FROM Review r WHERE r.store.id IN :storeIds GROUP BY r.store.id")
    List<Object[]> calculateRatingsForStores(@Param("storeIds") Collection<Long> storeIds);
}
