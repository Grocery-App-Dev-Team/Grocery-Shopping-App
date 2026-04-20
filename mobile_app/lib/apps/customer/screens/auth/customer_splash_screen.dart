import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/customer_current_location_service.dart';
import '../../repository/customer_auth_repository.dart';
import '../../utils/customer_l10n.dart';
import '../home/customer_home_screen.dart';
import 'customer_login_screen.dart';

class CustomerSplashScreen extends StatefulWidget {
  const CustomerSplashScreen({super.key});

  @override
  State<CustomerSplashScreen> createState() => _CustomerSplashScreenState();
}

class _CustomerSplashScreenState extends State<CustomerSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _bootstrapSession();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  Future<void> _bootstrapSession() async {
    await Future.delayed(const Duration(seconds: 2));
    final locationResult =
        await CustomerCurrentLocationService.instance.initializeCurrentLocation();

    if (locationResult == CustomerLocationStatus.serviceDisabled) {
      await _showLocationServiceDialog();
    } else if (locationResult == CustomerLocationStatus.permissionDeniedForever) {
      await _showAppSettingsDialog();
    }

    final authRepository = context.read<CustomerAuthRepository>();
    final isLoggedIn = await authRepository.tryRestoreSession();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => isLoggedIn
            ? const CustomerHomeScreen()
            : const CustomerLoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/images/splash_logo.png',
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 50,
                        color: scheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showLocationServiceDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr(vi: 'Vị trí cần được bật', en: 'Location service needed')),
          content: Text(
            context.tr(
              vi: 'Ứng dụng cần bật dịch vụ vị trí để xác định vị trí hiện tại. Vui lòng bật định vị và thử lại.',
              en: 'The app needs location services to determine your current position. Please enable location and try again.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              child: Text(context.tr(vi: 'Mở cài đặt', en: 'Open settings')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr(vi: 'Đóng', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAppSettingsDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr(vi: 'Quyền vị trí bị chặn', en: 'Location permission denied')),
          content: Text(
            context.tr(
              vi: 'Quyền truy cập vị trí đã bị từ chối vĩnh viễn. Vui lòng mở cài đặt app và bật lại.',
              en: 'Location access has been permanently denied. Please open app settings and enable it.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              child: Text(context.tr(vi: 'Mở cài đặt', en: 'Open settings')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr(vi: 'Đóng', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
