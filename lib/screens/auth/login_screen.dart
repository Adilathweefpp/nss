import 'package:flutter/material.dart';
import 'package:nss_app/widgets/common/custom_button.dart';
import 'package:nss_app/widgets/common/custom_text_field.dart';
import 'package:nss_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    // Check for redirect result on web platform
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkRedirectResult();
      });
    }
  }

  Future<void> _checkRedirectResult() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      debugPrint('Checking for redirect result on initial load');
      final result = await authService.checkRedirectResult();
      if (result != null && result.user != null) {
        // User successfully signed in via redirect
        debugPrint('User signed in via redirect, navigating...');
        _handleSuccessfulSignIn();
      }
    } catch (e) {
      debugPrint('Error checking redirect result: $e');
      setState(() {
        _errorMessage = 'Failed to complete sign-in process.';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        debugPrint('Attempting email/password login');
        final authService = Provider.of<AuthService>(context, listen: false);

        // Sign in with email and password as student (default role)
        await authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: 'student', // Explicitly set role as student
        );

        debugPrint('Email/password login successful');
        // Navigate based on role and approval
        _handleSuccessfulSignIn();
      } on FirebaseAuthException catch (e) {
        String message = 'An error occurred. Please try again.';

        if (e.code == 'user-not-found') {
          message = 'No user found with this email.';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password.';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email address.';
        } else if (e.code == 'user-disabled') {
          message = 'This account has been disabled.';
        } else {
          // Log other error codes for debugging
          debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
        }

        setState(() {
          _errorMessage = message;
        });
      } catch (e) {
        debugPrint('Unexpected error during login: $e');
        setState(() {
          _errorMessage = 'An unexpected error occurred.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      debugPrint('Attempting Google Sign-In');
      final authService = Provider.of<AuthService>(context, listen: false);
      final credential = await authService.signInWithGoogle();

      // If user cancelled Google Sign-in or redirect is in progress
      if (credential == null) {
        debugPrint('Google Sign-In returned null (user cancelled or redirect in progress)');
        // For web redirect, this is normal - the page will reload
        if (!kIsWeb) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      debugPrint('Google Sign-In successful');
      // Handle successful sign-in
      _handleSuccessfulSignIn();
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error during Google Sign-In: ${e.code} - ${e.message}');
      setState(() {
        _errorMessage = 'Failed to sign in with Google: ${e.message}';
      });
    } catch (e) {
      debugPrint('Unexpected error during Google Sign-In: $e');
      setState(() {
        _errorMessage = 'Failed to sign in with Google.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _handleSuccessfulSignIn() async {
    if (!mounted) return;
    
    try {
      debugPrint('Handling successful sign-in, checking user data');
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Check user role and approval status
      final userData = await authService.getUserData();
      final isAdmin = userData['isAdmin'];
      final isApproved = userData['isApproved'];

      debugPrint('User data: isAdmin=$isAdmin, isApproved=$isApproved');
      
      // Navigate based on role and approval
      if (!mounted) return;
      
      if (isAdmin) {
        debugPrint('Navigating to admin dashboard');
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      } else if (isApproved) {
        debugPrint('Navigating to volunteer dashboard');
        Navigator.pushReplacementNamed(context, '/volunteer/dashboard');
      } else {
        debugPrint('Navigating to pending approval screen');
        // User is not approved yet
        Navigator.pushReplacementNamed(context, '/pending-approval');
      }
    } catch (e) {
      debugPrint('Error handling successful sign-in: $e');
      // If something went wrong with navigation, let's at least clear the loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error completing the sign-in process. Please try again.';
        });
      }
    }
  }
  
  // Navigate to admin login screen
  void _navigateToAdminLogin() {
    Navigator.pushNamed(context, '/admin-login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Header
                  Image.asset(
                    'assets/images/nss-logo2-national-service-scheme.png',
                    height: 190,
                    width: 190,
                    fit: BoxFit.contain, // This ensures the image keeps its aspect ratio
                  ),
                  // const Icon(
                  //   Icons.volunteer_activism,
                  //   size: 80,
                  //   color: Colors.blue,
                  // ),
                  const SizedBox(height: 16),
                  const Text(
                    'NSS App',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'National Service Scheme',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Error Message (if any)
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: Icons.lock,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Buttons row for Forgot Password and Admin Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Admin Login Button
                      TextButton(
                        onPressed: _navigateToAdminLogin,
                        child: const Text(
                          'Login as Admin',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Forgot Password Button
                      TextButton(
                        onPressed: () {
                          // Navigate to forgot password screen or show dialog
                          if (_emailController.text.isNotEmpty &&
                              _emailController.text.contains('@')) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Reset Password'),
                                content: Text(
                                  'Send password reset email to ${_emailController.text}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      try {
                                        await Provider.of<AuthService>(context,
                                                listen: false)
                                            .resetPassword(
                                                _emailController.text.trim());

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Password reset email sent!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Failed to send reset email.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('Send'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please enter a valid email address first.'),
                              ),
                            );
                          }
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  CustomButton(
                    text: 'Login',
                    isLoading: _isLoading,
                    onPressed: () {
                      if (!_isLoading) _login();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Google Sign In Button
                  CustomButton(
                    text: 'Sign in with Google',
                    icon: Icons.g_mobiledata,
                    color: Colors.white,
                    textColor: Colors.black87,
                    isLoading: _isLoading,
                    onPressed: () {
                      if (!_isLoading) _googleSignIn();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}








// import 'package:flutter/material.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:nss_app/widgets/common/custom_text_field.dart';
// import 'package:nss_app/services/auth_service.dart';
// import 'package:provider/provider.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({Key? key}) : super(key: key);

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   String _errorMessage = '';

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _login() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = '';
//       });

//       try {
//         final authService = Provider.of<AuthService>(context, listen: false);

//         // Sign in with email and password as student (default role)
//         await authService.signInWithEmailAndPassword(
//           email: _emailController.text.trim(),
//           password: _passwordController.text,
//           role: 'student', // Explicitly set role as student
//         );

//         // Check user role and approval status
//         final userData = await authService.getUserData();
//         final isAdmin = userData['isAdmin'];
//         final isApproved = userData['isApproved'];

//         // Navigate based on role and approval
//         if (mounted) {
//           if (isAdmin) {
//             Navigator.pushReplacementNamed(context, '/admin/dashboard');
//           } else if (isApproved) {
//             Navigator.pushReplacementNamed(context, '/volunteer/dashboard');
//           } else {
//             // User is not approved yet
//             Navigator.pushReplacementNamed(context, '/pending-approval');
//           }
//         }
//       } on FirebaseAuthException catch (e) {
//         String message = 'An error occurred. Please try again.';

//         if (e.code == 'user-not-found') {
//           message = 'No user found with this email.';
//         } else if (e.code == 'wrong-password') {
//           message = 'Incorrect password.';
//         } else if (e.code == 'invalid-email') {
//           message = 'Invalid email address.';
//         } else if (e.code == 'user-disabled') {
//           message = 'This account has been disabled.';
//         }

//         setState(() {
//           _errorMessage = message;
//         });
//       } catch (e) {
//         setState(() {
//           _errorMessage = 'An unexpected error occurred.';
//         });
//       } finally {
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     }
//   }

//   Future<void> _googleSignIn() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       final authService = Provider.of<AuthService>(context, listen: false);
//       final credential = await authService.signInWithGoogle();

//       // If user cancelled Google Sign-in
//       if (credential == null) {
//         setState(() {
//           _isLoading = false;
//         });
//         return;
//       }

//       // Check user role and approval status
//       final userData = await authService.getUserData();
//       final isAdmin = userData['isAdmin'];
//       final isApproved = userData['isApproved'];

//       // Navigate based on role and approval
//       if (mounted) {
//         if (isAdmin) {
//           Navigator.pushReplacementNamed(context, '/admin/dashboard');
//         } else if (isApproved) {
//           Navigator.pushReplacementNamed(context, '/volunteer/dashboard');
//         } else {
//           // User is not approved yet
//           Navigator.pushReplacementNamed(context, '/pending-approval');
//         }
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Failed to sign in with Google.';
//       });
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
  
//   // Navigate to admin login screen
//   void _navigateToAdminLogin() {
//     Navigator.pushNamed(context, '/admin-login');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // Logo and Header
//                   // Image.asset(
//                   //   'assets/images/nss_logo.png',
//                   //   height: 80,
//                   //   width: 80,
//                   //   fit: BoxFit.contain,
//                   // ),
                  
//                   // Logo and Header
//                   const Icon(
//                     Icons.volunteer_activism,
//                     size: 80,
//                     color: Colors.blue,
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'NSS App',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'National Service Scheme',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.black54,
//                     ),
//                   ),
//                   const SizedBox(height: 40),

//                   // Error Message (if any)
//                   if (_errorMessage.isNotEmpty)
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       margin: const EdgeInsets.only(bottom: 16),
//                       decoration: BoxDecoration(
//                         color: Colors.red.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.red.shade200),
//                       ),
//                       child: Text(
//                         _errorMessage,
//                         style: TextStyle(color: Colors.red.shade800),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),

//                   // Email Field
//                   CustomTextField(
//                     controller: _emailController,
//                     hintText: 'Email',
//                     prefixIcon: Icons.email,
//                     keyboardType: TextInputType.emailAddress,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your email';
//                       }
//                       if (!value.contains('@')) {
//                         return 'Please enter a valid email';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),

//                   // Password Field
//                   CustomTextField(
//                     controller: _passwordController,
//                     hintText: 'Password',
//                     prefixIcon: Icons.lock,
//                     isPassword: true,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your password';
//                       }
//                       if (value.length < 6) {
//                         return 'Password must be at least 6 characters';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 8),

//                   // Buttons row for Forgot Password and Admin Login
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       // Admin Login Button
//                       TextButton(
//                         onPressed: _navigateToAdminLogin,
//                         child: const Text(
//                           'Login as Admin',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
                      
//                       // Forgot Password Button
//                       TextButton(
//                         onPressed: () {
//                           // Navigate to forgot password screen or show dialog
//                           if (_emailController.text.isNotEmpty &&
//                               _emailController.text.contains('@')) {
//                             showDialog(
//                               context: context,
//                               builder: (context) => AlertDialog(
//                                 title: const Text('Reset Password'),
//                                 content: Text(
//                                   'Send password reset email to ${_emailController.text}?',
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(context),
//                                     child: const Text('Cancel'),
//                                   ),
//                                   TextButton(
//                                     onPressed: () async {
//                                       Navigator.pop(context);
//                                       try {
//                                         await Provider.of<AuthService>(context,
//                                                 listen: false)
//                                             .resetPassword(
//                                                 _emailController.text.trim());

//                                         ScaffoldMessenger.of(context)
//                                             .showSnackBar(
//                                           const SnackBar(
//                                             content: Text(
//                                                 'Password reset email sent!'),
//                                             backgroundColor: Colors.green,
//                                           ),
//                                         );
//                                       } catch (e) {
//                                         ScaffoldMessenger.of(context)
//                                             .showSnackBar(
//                                           const SnackBar(
//                                             content: Text(
//                                                 'Failed to send reset email.'),
//                                             backgroundColor: Colors.red,
//                                           ),
//                                         );
//                                       }
//                                     },
//                                     child: const Text('Send'),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           } else {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text(
//                                     'Please enter a valid email address first.'),
//                               ),
//                             );
//                           }
//                         },
//                         child: const Text('Forgot Password?'),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),

//                   // Login Button
//                   CustomButton(
//                     text: 'Login',
//                     isLoading: _isLoading,
//                     onPressed: () {
//                       if (!_isLoading) _login();
//                     },
//                   ),
//                   const SizedBox(height: 16),

//                   // Google Sign In Button
//                   CustomButton(
//                     text: 'Sign in with Google',
//                     icon: Icons.g_mobiledata,
//                     color: Colors.white,
//                     textColor: Colors.black87,
//                     isLoading: _isLoading,
//                     onPressed: () {
//                       if (!_isLoading) _googleSignIn();
//                     },
//                   ),
//                   const SizedBox(height: 24),

//                   // Sign Up Link
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Text("Don't have an account?"),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pushNamed(context, '/signup');
//                         },
//                         child: const Text('Sign Up'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }