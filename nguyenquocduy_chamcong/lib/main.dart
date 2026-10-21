import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api.dart';
import 'screens/admin/admin_home.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_home.dart';
import 'screens/employee/employee_home.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Session.load();
  runApp(const ChamCongApp());
}

class ChamCongApp extends StatelessWidget {
  const ChamCongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chấm Công - Nguyễn Quốc Duy',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
    );
  }
}

/// Phân quyền: Admin -> trang quản trị, NhanVien -> Dashboard nhân viên, còn lại -> trang khách hàng.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Session.changes,
      builder: (context, _, __) {
        if (!Session.loggedIn) return const LoginScreen();
        switch (Session.role) {
          case 'Admin':
            return const AdminHome();
          case 'NhanVien':
            return const EmployeeHome();
          default:
            return const CustomerHome();
        }
      },
    );
  }
}
