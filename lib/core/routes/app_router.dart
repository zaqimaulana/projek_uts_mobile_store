import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/payment_result_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

import 'auth_guard.dart';

class AppRouter {
  static const String splash      = '/';
  static const String login       = '/login';
  static const String register    = '/register';
  static const String verifyEmail = '/verify-email';
  static const String dashboard   = '/dashboard';
  static const String checkout      = '/checkout';
  static const String paymentResult = '/payment-result';

  static Map<String, WidgetBuilder> get routes => {
    splash:         (_) => const SplashPage(),
    login:          (_) => const LoginPage(),
    register:       (_) => const RegisterPage(),
    verifyEmail:    (_) => const VerifyEmailPage(),
    dashboard:      (_) => const AuthGuard(child: DashboardPage()),
    checkout:       (_) => const CheckoutPage(),
    paymentResult:  (_) => const PaymentResultPage(),
  };
}