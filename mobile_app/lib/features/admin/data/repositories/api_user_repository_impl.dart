import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/enums/app_type.dart';
import '../../../auth/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';

class ApiUserRepositoryImpl implements UserRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<UserModel>> getUsers({AppType? appType, UserRole? role}) async {
    try {
      final response = await _apiClient.get('/users');
      final List data = response.data['data'] as List;
      return data.map((json) => UserModel.fromJson(json)).toList();
    } on DioException catch (e) {
      // 403: token chưa có quyền ADMIN -> trả rỗng thay vì crash
      final status = e.response?.statusCode;
      if (status == 403 || status == 401) {
        return [];
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  @override
  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _apiClient.get('/users/$id');
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to fetch user by ID: $e');
    }
  }

  @override
  Future<void> updateUserStatus(String id, UserStatus status) async {
    try {
      final bool isActive = status == UserStatus.active;
      await _apiClient.patch('/users/$id/status/$isActive');
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _apiClient.delete('/users/$id');
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  @override
  Future<UserModel> createUser(UserModel user, {required String password}) async {
    try {
      final json = user.toJson();
      json['password'] = password;
      final response = await _apiClient.post('/auth/register', data: json);
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await _apiClient.put('/users/profile', data: user.toJson());
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }
}
