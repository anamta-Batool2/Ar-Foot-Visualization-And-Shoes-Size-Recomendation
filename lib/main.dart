import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/customer_dashboard_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/virtual_tryon_screen.dart';
List<CameraDescription> cameras = [];
Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();
cameras = await availableCameras();
runApp(const MyApp());
}
class MyApp extends StatelessWidget {
const MyApp({super.key});
@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'StepFit',
debugShowCheckedModeBanner: false,
initialRoute: '/',
routes: {
  '/': (context) => const SplashScreen(),
'/role': (context) => const RoleSelectionScreen(),
'/login': (context) => const LoginScreen(),
'/register': (context) => const RegisterScreen(),
'/dashboard': (context) => const CustomerDashboardScreen(),
'/scan': (context) => const ScanScreen(),
'/virtual-tryon': (context) => VirtualTryOnScreen(),
'/virtual-tryon': (context) => VirtualTryOnScreen(cameras: cameras),
},
);
}
}