import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/screens/admin/admin_dashboard.dart';
import 'package:rentease/screens/landlord/landlord_dashboard.dart';
import 'package:rentease/screens/shared/splash_screen.dart';
// THIS IMPORT FIXES THE ERROR
import 'package:rentease/screens/tenant/tenant_dashboard.dart';
import 'package:rentease/services/auth_service.dart';

class RoleSelector extends StatelessWidget {
  final bool isloading;
  const RoleSelector({super.key, this.isloading = false});

  @override
  Widget build(BuildContext context) {
    if (isloading) {
      return const SplashScreen();
    }

    final user = context.watch<UserModel?>();

    if (user == null) {
      final authUser = context.read<AuthService>().currentUser;
      if (authUser != null) {
         return const SplashScreen();
      }
      // This is a safe fallback
      return const SplashScreen();
    }

    // Redirect based on role
    switch (user.role) {
      case 'landlord':
        return const LandlordDashboard();
      case 'tenant':
        // THIS NOW WORKS
        return const TenantDashboard();
      case 'admin':
        return const AdminDashboard();
      // THIS 'default' CASE FIXES THE "body might complete normally" ERROR
      default:
        // Fallback for unknown roles or while logging out
        return const SplashScreen();
    }
  }
}