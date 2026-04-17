import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_session.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: AppConstants.baseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              String? token = AuthSession.token;
              if (token == null || token.isEmpty) {
                final prefs = await SharedPreferences.getInstance();
                token = prefs.getString(AppConstants.accessTokenKey);
                if (token != null && token.isNotEmpty) {
                  AuthSession.token = token;
                }
              }

              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              return handler.next(options);
            },
          ),
        );
}
