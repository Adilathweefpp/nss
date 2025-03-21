import 'package:flutter/material.dart';
import 'package:nss_app/services/auth_service.dart';
import 'package:nss_app/services/signup_service.dart'; // Fixed import path
import 'package:provider/provider.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({Key? key}) : super(key: key);

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isLoading = true;
  String _status = 'pending';
  String _message = '';

  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
  }

  Future<void> _checkApprovalStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final studentService = Provider.of<StudentService>(context, listen: false);
      final result = await studentService.getApprovalStatus();

      setState(() {
        _status = result['status'];
        _message = result['message'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'error';
        _message = 'An error occurred while checking your approval status.';
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      print("Sign out error: $e"); // Add debug logging
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                final studentService = Provider.of<StudentService>(context, listen: false);
                await studentService.deleteAccount();

                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully. You can now register again.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Status'),
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Status Icon
                  Icon(
                    _status == 'pending'
                        ? Icons.hourglass_bottom
                        : _status == 'approved'
                            ? Icons.check_circle
                            : Icons.cancel,
                    size: 120,
                    color: _status == 'pending'
                        ? Colors.amber
                        : _status == 'approved'
                            ? Colors.green
                            : Colors.red,
                  ),
                  const SizedBox(height: 32),
                  
                  // Status Title
                  Text(
                    _status == 'pending'
                        ? 'Application Under Review'
                        : _status == 'approved'
                            ? 'Application Approved'
                            : 'Application Rejected',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Status Description
                  Text(
                    _status == 'pending'
                        ? 'Your application is currently being reviewed by the admin. This may take some time.'
                        : _status == 'approved'
                            ? 'Congratulations! Your application has been approved. You can now log in to the volunteer dashboard.'
                            : 'Unfortunately, your application has been rejected. ${_message.isNotEmpty ? "Reason: $_message" : "Please contact the admin for more information."}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Action Buttons
                  if (_status == 'pending' || _status == 'rejected')
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _checkApprovalStatus,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Check Status Again'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  
                  if (_status == 'approved')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Go to Login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  
                  if (_status == 'rejected')
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _deleteAccount,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete and Register Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  
                  TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
    );
  }
}

// // screens/auth/pending_approval_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:nss_app/services/auth_service.dart';

// class PendingApprovalScreen extends StatelessWidget {
//   const PendingApprovalScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pending Approval'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await Provider.of<AuthService>(context, listen: false).signOut();
//               Navigator.pushReplacementNamed(context, '/login');
//             },
//           ),
//         ],
//       ),
//       body: const Center(
//         child: Padding(
//           padding: EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.hourglass_empty,
//                 size: 80,
//                 color: Colors.orange,
//               ),
//               SizedBox(height: 24),
//               Text(
//                 'Account Pending Approval',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 16),
//               Text(
//                 'Your account is currently pending approval from an administrator. '
//                 'You will be notified once your account is approved.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// // import 'package:flutter/material.dart';
// // import 'package:nss_app/widgets/common/custom_button.dart';

// // class PendingApprovalScreen extends StatelessWidget {
// //   const PendingApprovalScreen({Key? key}) : super(key: key);

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: SafeArea(
// //         child: Padding(
// //           padding: const EdgeInsets.all(24.0),
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             crossAxisAlignment: CrossAxisAlignment.center,
// //             children: [
// //               const Icon(
// //                 Icons.hourglass_bottom,
// //                 size: 100,
// //                 color: Colors.orange,
// //               ),
// //               const SizedBox(height: 32),
// //               const Text(
// //                 'Account Pending Approval',
// //                 style: TextStyle(
// //                   fontSize: 24,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //                 textAlign: TextAlign.center,
// //               ),
// //               const SizedBox(height: 16),
// //               const Text(
// //                 'Your account registration has been received and is pending approval from an administrator. You will be notified once your account is approved.',
// //                 style: TextStyle(
// //                   fontSize: 16,
// //                   color: Colors.black54,
// //                 ),
// //                 textAlign: TextAlign.center,
// //               ),
// //               const SizedBox(height: 32),
// //               const Row(
// //                 children: [
// //                   Expanded(
// //                     child: Divider(),
// //                   ),
// //                   Padding(
// //                     padding: EdgeInsets.symmetric(horizontal: 16.0),
// //                     child: Text('What Happens Next?'),
// //                   ),
// //                   Expanded(
// //                     child: Divider(),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 24),
// //               _buildStepCard(
// //                 context,
// //                 icon: Icons.admin_panel_settings,
// //                 title: 'Admin Review',
// //                 description: 'An NSS administrator will review your application.'
// //               ),
// //               const SizedBox(height: 16),
// //               _buildStepCard(
// //                 context,
// //                 icon: Icons.email,
// //                 title: 'Email Notification',
// //                 description: 'You will receive an email when your account is approved.'
// //               ),
// //               const SizedBox(height: 16),
// //               _buildStepCard(
// //                 context,
// //                 icon: Icons.login,
// //                 title: 'Login Access',
// //                 description: 'Once approved, you can log in to access volunteer features.'
// //               ),
// //               const SizedBox(height: 40),
// //               CustomButton(
// //                 text: 'Back to Login',
// //                 onPressed: () {
// //                   Navigator.pushReplacementNamed(context, '/login');
// //                 },
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildStepCard(
// //     BuildContext context, {
// //     required IconData icon,
// //     required String title,
// //     required String description,
// //   }) {
// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.grey.withOpacity(0.1),
// //             spreadRadius: 1,
// //             blurRadius: 4,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Row(
// //         children: [
// //           Icon(
// //             icon,
// //             size: 40,
// //             color: Theme.of(context).primaryColor,
// //           ),
// //           const SizedBox(width: 16),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   title,
// //                   style: const TextStyle(
// //                     fontSize: 16,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Text(
// //                   description,
// //                   style: const TextStyle(
// //                     fontSize: 14,
// //                     color: Colors.black54,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }