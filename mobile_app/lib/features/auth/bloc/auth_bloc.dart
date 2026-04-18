import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../core/config/app_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../core/enums/app_type.dart';
import '../../../core/api/api_client.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  Timer? _tokenRefreshTimer;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    // Register event handlers
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
    on<CheckStatusRequested>(_onCheckStatusRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<OtpVerificationRequested>(_onOtpVerificationRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ChangePasswordRequested>(_onChangePasswordRequested);

    // Check authentication status on bloc initialization
    add(const CheckStatusRequested());

    // Register global 401 interceptor callback
    ApiClient.onUnauthorized = () {
      if (state is AuthAuthenticated) {
        AppLogger.warning('Global 401 detected, logging out user.');
        add(const LogoutRequested(reason: 'Phiên đăng nhập hết hạn'));
      }
    };
  }

  @override
  Future<void> close() {
    _tokenRefreshTimer?.cancel();
    return super.close();
  }

  /// Handle login request
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      AppLogger.info('🔐 Login attempt started');

      final authResponse = await _authRepository.login(
        identifier: event.identifier,
        password: event.password,
        appType: event.appType,
        rememberMe: event.rememberMe,
      );

      if (authResponse.isAuthenticated) {
        final user = authResponse.user!;
        final token = authResponse.data?.token ?? '';

        // Enforce Admin role for Admin App
        if (event.appType == AppType.admin && user.role != UserRole.admin) {
          emit(const AuthError(
            message: 'Bạn không có quyền truy cập vào ứng dụng Admin.',
            errorCode: 'insufficient_permissions',
          ));
          return;
        }

        emit(AuthAuthenticated(user: user, token: token));
        _startTokenRefreshTimer();
      } else {
        emit(
          AuthError(message: authResponse.message, errorCode: 'login_failed'),
        );
      }
    } on ServerException catch (e) {
      emit(AuthError(message: e.message, errorCode: 'server_error'));
    } catch (e) {
      emit(
        const AuthError(
          message: 'Đã xảy ra lỗi khi đăng nhập',
          errorCode: 'unknown_error',
        ),
      );
    }
  }

  /// Handle register request
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthRegistering());

      final authResponse = await _authRepository.register(
        userData: event.userData,
        appType: event.appType,
      );

<<<<<<< Updated upstream
      if (authResponse.isAuthenticated) {
        AppLogger.info('✅ Registration successful');
=======
      if (authResponse.success) {
>>>>>>> Stashed changes
        emit(
          const AuthRegistrationSuccess(
            message: 'Đăng ký thành công! Vui lòng đăng nhập.',
          ),
        );
      } else {
        emit(AuthRegistrationError(message: authResponse.message));
      }
    } on ServerException catch (e) {
      emit(
        AuthRegistrationError(
          message: e.message,
          validationErrors: e.statusCode == 400 ? {'general': e.message} : null,
        ),
      );
    } catch (e) {
      emit(
        const AuthRegistrationError(message: 'Đã xảy ra lỗi đăng ký'),
      );
    }
  }

  /// Handle logout request
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _tokenRefreshTimer?.cancel();
      await _authRepository.logout();
      emit(AuthUnauthenticated(reason: event.reason ?? 'User logged out'));
    } catch (e) {
      emit(AuthUnauthenticated(reason: event.reason ?? 'Logout with error'));
    }
  }

  /// Handle token refresh request
  Future<void> _onTokenRefreshRequested(
    TokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      emit(AuthTokenRefreshing(user: currentState.user));

      final authResponse = await _authRepository.refreshToken(
        refreshToken: event.refreshToken ?? currentState.token,
      );

      if (authResponse.isAuthenticated) {
        final user = authResponse.user ?? currentState.user;
        final token = authResponse.data?.token ?? currentState.token;
        emit(AuthAuthenticated(user: user, token: token));
        _startTokenRefreshTimer();
      } else {
        emit(const AuthSessionExpired());
      }
    } catch (e) {
      emit(const AuthSessionExpired());
    }
  }

  /// Handle check status request
  Future<void> _onCheckStatusRequested(
    CheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      AppLogger.debug('🔍 Checking authentication status');

      final isAuthenticated = await _authRepository.isAuthenticated();

      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        final token = await _authRepository.getAuthToken();

        if (user != null && token != null) {
          emit(AuthAuthenticated(user: user, token: token));
          _startTokenRefreshTimer();
        } else {
          await _authRepository.clearAuthData();
          emit(const AuthUnauthenticated());
        }
      } else {
        AppLogger.debug('🚫 User not authenticated');
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated(reason: 'Status check failed'));
    }
  }

  /// Handle forgot password request
  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthPasswordResetLoading());

      final response = await _authRepository.forgotPassword(
        identifier: event.identifier,
        appType: AppType.customer,
      );

      emit(AuthPasswordResetSent(message: response.message));
    } on UnimplementedError catch (e) {
      emit(
        const AuthPasswordResetError(
          message: 'Tính năng quên mật khẩu chưa được hỗ trợ',
        ),
      );
    } catch (e) {
      emit(
        const AuthPasswordResetError(
          message: 'Không thể gửi mã xác nhận',
        ),
      );
    }
  }

  /// Handle OTP verification request
  Future<void> _onOtpVerificationRequested(
    OtpVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthOtpVerifying());

      final response = await _authRepository.verifyOtp(
        otp: event.otp,
        identifier: event.identifier,
        resetToken: event.resetToken,
      );

      if (response.isAuthenticated) {
        emit(AuthOtpVerified(message: response.message));
      } else {
        emit(AuthOtpError(message: response.message));
      }
    } on UnimplementedError catch (e) {
      emit(
        const AuthOtpError(message: 'Tính năng xác nhận OTP chưa được hỗ trợ'),
      );
    } catch (e) {
      emit(AuthOtpError(message: 'Không thể xác nhận OTP'));
    }
  }

  /// Handle password reset request
  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthPasswordResetLoading());

      final response = await _authRepository.resetPassword(
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
        resetToken: event.resetToken,
      );

      if (response.isAuthenticated) {
        emit(
          const AuthPasswordResetSent(message: 'Đặt lại mật khẩu thành công'),
        );
      } else {
        emit(AuthPasswordResetError(message: response.message));
      }
    } on UnimplementedError catch (e) {
      emit(
        const AuthPasswordResetError(
          message: 'Tính năng đặt lại mật khẩu chưa được hỗ trợ',
        ),
      );
    } catch (e) {
      emit(
        const AuthPasswordResetError(
          message: 'Không thể đặt lại mật khẩu',
        ),
      );
    }
  }

  /// Handle profile update request
  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      emit(const AuthProfileUpdating());

      final updatedUser = await _authRepository.updateProfile(
        userData: event.userData,
      );

      emit(AuthProfileUpdated(updatedUser: updatedUser));
      emit(AuthAuthenticated(
        user: updatedUser,
        token: currentState.token,
      ));
    } catch (e) {
      emit(AuthProfileUpdateError(
        message: e is ServerException ? e.message : 'Không thể cập nhật thông tin',
      ));
      emit(currentState);
    }
  }

  /// Handle change password request
  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      emit(const AuthPasswordResetLoading());

      await _authRepository.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );

      emit(const AuthPasswordResetSent(
        message: 'Đổi mật khẩu thành công',
      ));
      emit(currentState);
      
    } catch (e) {
      emit(AuthPasswordResetError(
        message: e is ServerException ? e.message : 'Không thể đổi mật khẩu',
      ));
      emit(currentState);
    }
  }

  /// Start token refresh timer (15 minutes before expiry)
  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();

    // Refresh token every 45 minutes (assuming 60 min expiry)
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 45), (timer) {
      AppLogger.debug('🕐 Auto token refresh triggered');
      add(const TokenRefreshRequested());
    });

    AppLogger.debug('🕐 Token refresh timer started');
  }

  /// Helper method to check if user has permission
  bool hasPermission(String permission) {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.hasPermission(permission);
    }
    return false;
  }

  /// Helper method to get current user
  UserModel? get currentUser {
    return state.currentUser;
  }

  /// Helper method to get current token
  String? get currentToken {
    return state.currentToken;
  }

  /// Helper method to check authentication status
  bool get isAuthenticated {
    return state.isAuthenticated;
  }
}
