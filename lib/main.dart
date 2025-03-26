import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nss_app/routes.dart';
import 'package:nss_app/screens/auth/login_screen.dart';
import 'package:nss_app/services/ApprovalService.dart';
import 'package:nss_app/services/admin_manage_service.dart';
import 'package:nss_app/services/admin_profile_service.dart';
import 'package:nss_app/services/attendance_service.dart';
import 'package:nss_app/services/event_service.dart';
import 'package:nss_app/services/feedback_service.dart';
import 'package:nss_app/services/point_service.dart';
import 'package:nss_app/services/profile_service.dart';
import 'package:nss_app/services/signup_service.dart';
import 'package:nss_app/services/volunteer_manage_service.dart';
import 'package:nss_app/theme.dart';
import 'package:provider/provider.dart';
import 'package:nss_app/services/auth_service.dart'; 
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
        ChangeNotifierProvider(create: (_) => StudentService()), 
        ChangeNotifierProvider(create: (_) => ApprovalService()),
        ChangeNotifierProvider(create: (_) => ProfileService()), 
        ChangeNotifierProvider(create: (_) => AdminProfileService()),
        ChangeNotifierProvider(create: (_) => EventService()),
        ChangeNotifierProvider(create: (_) => AdminManageService()),
        ChangeNotifierProvider(create: (_) => VolunteerManageService()),
        ChangeNotifierProvider(create: (_) => AttendanceService()),
        ChangeNotifierProvider(create: (_) => FeedbackService()),
        ChangeNotifierProvider(create: (_) => PointService()),
      ],
      child: MaterialApp(
        title: 'NSS App',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        routes: routes,
        home: const AppEntryPoint(),
      ),
    );
  }
}

// Entry point widget to handle authentication state and redirects
class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // Listen to auth state changes
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading state while connection is in progress
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If user is authenticated
        if (snapshot.hasData && snapshot.data != null) {
          // Return a FutureBuilder to check user role and approval status
          return FutureBuilder<Map<String, dynamic>>(
            future: authService.getUserData(),
            builder: (context, userDataSnapshot) {
              if (userDataSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final userData = userDataSnapshot.data ?? {'isAdmin': false, 'isApproved': false};
              final isAdmin = userData['isAdmin'];
              final isApproved = userData['isApproved'];
              
              // Navigate based on role and approval
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (isAdmin) {
                  Navigator.pushReplacementNamed(context, '/admin/dashboard');
                } else if (isApproved) {
                  Navigator.pushReplacementNamed(context, '/volunteer/dashboard');
                } else {
                  Navigator.pushReplacementNamed(context, '/pending-approval');
                }
              });
              
              // Show loading while navigation is happening
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          );
        }
        
        // If not authenticated, show login screen
        return const LoginScreen();
      },
    );
  }
}







// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:nss_app/routes.dart';
// import 'package:nss_app/screens/auth/login_screen.dart';
// import 'package:nss_app/services/ApprovalService.dart';
// import 'package:nss_app/services/admin_manage_service.dart';
// import 'package:nss_app/services/admin_profile_service.dart';
// import 'package:nss_app/services/attendance_service.dart';
// import 'package:nss_app/services/event_service.dart';
// import 'package:nss_app/services/feedback_service.dart';
// import 'package:nss_app/services/profile_service.dart';
// import 'package:nss_app/services/signup_service.dart';
// import 'package:nss_app/services/volunteer_manage_service.dart';
// import 'package:nss_app/theme.dart';
// import 'package:provider/provider.dart';
// import 'package:nss_app/services/auth_service.dart'; 
// import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const NSSApp());
// }

// class NSSApp extends StatelessWidget {
//   const NSSApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthService()),
//         ChangeNotifierProvider(create: (_) => StudentService()), 
//         ChangeNotifierProvider(create: (_) => ApprovalService()),
//         ChangeNotifierProvider(create: (_) => ProfileService()), 
//         ChangeNotifierProvider(create: (_) => AdminProfileService()),
//         ChangeNotifierProvider(create: (_) => EventService()),
//         ChangeNotifierProvider(create: (_) => AdminManageService()),
//         ChangeNotifierProvider(create: (_) => VolunteerManageService()),
//         ChangeNotifierProvider(create: (_) => AttendanceService()),
//         ChangeNotifierProvider(create: (_) => FeedbackService()),
//       ],
//       child: MaterialApp(
//         title: 'NSS App',
//         debugShowCheckedModeBanner: false,
//         theme: appTheme,
//         routes: routes,
//         home: const AppEntryPoint(),
//       ),
//     );
//   }
// }

// // Entry point widget to handle authentication state and redirects
// class AppEntryPoint extends StatelessWidget {
//   const AppEntryPoint({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final authService = Provider.of<AuthService>(context);
    
//     // Listen to auth state changes
//     return StreamBuilder<User?>(
//       stream: authService.authStateChanges,
//       builder: (context, snapshot) {
//         // Show loading state while connection is in progress
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(
//               child: CircularProgressIndicator(),
//             ),
//           );
//         }
        
//         // If user is authenticated
//         if (snapshot.hasData && snapshot.data != null) {
//           // Return a FutureBuilder to check user role and approval status
//           return FutureBuilder<Map<String, dynamic>>(
//             future: authService.getUserData(),
//             builder: (context, userDataSnapshot) {
//               if (userDataSnapshot.connectionState == ConnectionState.waiting) {
//                 return const Scaffold(
//                   body: Center(
//                     child: CircularProgressIndicator(),
//                   ),
//                 );
//               }
              
//               final userData = userDataSnapshot.data ?? {'isAdmin': false, 'isApproved': false};
//               final isAdmin = userData['isAdmin'];
//               final isApproved = userData['isApproved'];
              
//               // Navigate based on role and approval
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 if (isAdmin) {
//                   Navigator.pushReplacementNamed(context, '/admin/dashboard');
//                 } else if (isApproved) {
//                   Navigator.pushReplacementNamed(context, '/volunteer/dashboard');
//                 } else {
//                   Navigator.pushReplacementNamed(context, '/pending-approval');
//                 }
//               });
              
//               // Show loading while navigation is happening
//               return const Scaffold(
//                 body: Center(
//                   child: CircularProgressIndicator(),
//                 ),
//               );
//             },
//           );
//         }
        
//         // If not authenticated, show login screen
//         return const LoginScreen();
//       },
//     );
//   }
// }







// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:nss_app/routes.dart';
// import 'package:nss_app/screens/auth/login_screen.dart';
// import 'package:nss_app/services/ApprovalService.dart';
// import 'package:nss_app/services/admin_manage_service.dart';
// import 'package:nss_app/services/admin_profile_service.dart';
// import 'package:nss_app/services/attendance_service.dart';
// import 'package:nss_app/services/event_service.dart';
// import 'package:nss_app/services/feedback_service.dart';
// import 'package:nss_app/services/profile_service.dart';
// import 'package:nss_app/services/signup_service.dart';
// import 'package:nss_app/services/volunteer_manage_service.dart';
// import 'package:nss_app/theme.dart';
// import 'package:provider/provider.dart';
// import 'package:nss_app/services/auth_service.dart'; 
// import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const NSSApp());
// }

// class NSSApp extends StatelessWidget {
//   const NSSApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthService()),
//         ChangeNotifierProvider(create: (_) => StudentService()), 
//         ChangeNotifierProvider(create: (_) => ApprovalService()),
//         ChangeNotifierProvider(create: (_) => ProfileService()), // 
//         ChangeNotifierProvider(create: (_) => AdminProfileService()),
//         ChangeNotifierProvider(create: (_) => EventService()),
//         ChangeNotifierProvider(create: (_) => AdminManageService()),
//         ChangeNotifierProvider(create: (_) => VolunteerManageService()),
//         ChangeNotifierProvider(create: (_) => AttendanceService()),
//         ChangeNotifierProvider(create: (_) => FeedbackService()),



//       ],
//       child: MaterialApp(
//         title: 'NSS App',
//         debugShowCheckedModeBanner: false,
//         theme: appTheme,
//         routes: routes,
//         home: const LoginScreen(),
//       ),
//     );
//   }
// }