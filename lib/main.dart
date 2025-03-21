import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nss_app/routes.dart';
import 'package:nss_app/screens/auth/login_screen.dart';
import 'package:nss_app/services/ApprovalService.dart';
import 'package:nss_app/services/admin_manage_service.dart';
import 'package:nss_app/services/admin_profile_service.dart';
import 'package:nss_app/services/event_service.dart';
import 'package:nss_app/services/profile_service.dart';
import 'package:nss_app/services/signup_service.dart';
import 'package:nss_app/services/volunteer_manage_service.dart';
import 'package:nss_app/theme.dart';
import 'package:provider/provider.dart';
import 'package:nss_app/services/auth_service.dart'; // Add this import
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NSSApp());
}

class NSSApp extends StatelessWidget {
  const NSSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => StudentService()), // Add this line
        ChangeNotifierProvider(create: (_) => ApprovalService()),
        ChangeNotifierProvider(create: (_) => ProfileService()), // 
        ChangeNotifierProvider(create: (_) => AdminProfileService()),
        ChangeNotifierProvider(create: (_) => EventService()),
        ChangeNotifierProvider(create: (_) => AdminManageService()),
        ChangeNotifierProvider(create: (_) => VolunteerManageService()), 


      ],
      child: MaterialApp(
        title: 'NSS App',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        routes: routes,
        home: const LoginScreen(),
      ),
    );
  }
}