import 'package:flutter/material.dart';
import 'package:nss_app/services/signup_service.dart';
import 'package:nss_app/utils/constants.dart';
import 'package:nss_app/widgets/common/custom_button.dart';
import 'package:nss_app/widgets/common/custom_text_field.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _volunteerIdController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _placeController = TextEditingController();
  final _departmentController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Available blood groups
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  // Available departments
  final List<String> _departments = [
    'Computer Science', 'Electronics', 'Mechanical', 'Civil', 
    'Electrical', 'Information Technology', 'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _volunteerIdController.dispose();
    _bloodGroupController.dispose();
    _placeController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _showBloodGroupPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: _bloodGroups.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_bloodGroups[index]),
                onTap: () {
                  setState(() {
                    _bloodGroupController.text = _bloodGroups[index];
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showDepartmentPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: _departments.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_departments[index]),
                onTap: () {
                  setState(() {
                    _departmentController.text = _departments[index];
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final studentService = Provider.of<StudentService>(context, listen: false);
        
        // Register the student
        await studentService.registerStudent(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          volunteerId: _volunteerIdController.text.trim(),
          bloodGroup: _bloodGroupController.text.trim(),
          place: _placeController.text.trim(),
          department: _departmentController.text.trim(),
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.successSignUp),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to pending approval screen
          Navigator.pushReplacementNamed(context, '/pending-approval');
        }
      } on FirebaseAuthException catch (e) {
        String message = 'An error occurred during registration.';
        
        if (e.code == 'email-already-in-use') {
          message = 'The email address is already in use.';
        } else if (e.code == 'weak-password') {
          message = 'The password is too weak.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is invalid.';
        }
        
        setState(() {
          _errorMessage = message;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please fill in all the required details',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),
                
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
                
                // Name Field
                CustomTextField(
                  controller: _nameController,
                  hintText: 'Full Name',
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
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
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Volunteer ID Field
                CustomTextField(
                  controller: _volunteerIdController,
                  hintText: 'Volunteer ID',
                  prefixIcon: Icons.badge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your volunteer ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Blood Group Field
                CustomTextField(
                  controller: _bloodGroupController,
                  hintText: 'Blood Group',
                  prefixIcon: Icons.bloodtype,
                  readOnly: true,
                  onTap: _showBloodGroupPicker,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your blood group';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Place Field
                CustomTextField(
                  controller: _placeController,
                  hintText: 'Place',
                  prefixIcon: Icons.location_on,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your place';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Department Field
                CustomTextField(
                  controller: _departmentController,
                  hintText: 'Department',
                  prefixIcon: Icons.school,
                  readOnly: true,
                  onTap: _showDepartmentPicker,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your department';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Sign Up Button
                CustomButton(
                  text: 'Sign Up',
                  isLoading: _isLoading,
                  onPressed: _signUp,
                ),
                const SizedBox(height: 24),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}








// import 'package:flutter/material.dart';
// import 'package:nss_app/utils/constants.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:nss_app/widgets/common/custom_text_field.dart';

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({Key? key}) : super(key: key);

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _volunteerIdController = TextEditingController();
//   final _bloodGroupController = TextEditingController();
//   final _placeController = TextEditingController();
//   final _departmentController = TextEditingController();
  
//   bool _isLoading = false;
  
//   // Available blood groups
//   final List<String> _bloodGroups = [
//     'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
//   ];

//   // Available departments
//   final List<String> _departments = [
//     'Computer Science', 'Electronics', 'Mechanical', 'Civil', 
//     'Electrical', 'Information Technology', 'Other'
//   ];

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _volunteerIdController.dispose();
//     _bloodGroupController.dispose();
//     _placeController.dispose();
//     _departmentController.dispose();
//     super.dispose();
//   }

//   void _showBloodGroupPicker() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return SizedBox(
//           height: 300,
//           child: ListView.builder(
//             itemCount: _bloodGroups.length,
//             itemBuilder: (context, index) {
//               return ListTile(
//                 title: Text(_bloodGroups[index]),
//                 onTap: () {
//                   setState(() {
//                     _bloodGroupController.text = _bloodGroups[index];
//                   });
//                   Navigator.pop(context);
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   void _showDepartmentPicker() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return SizedBox(
//           height: 300,
//           child: ListView.builder(
//             itemCount: _departments.length,
//             itemBuilder: (context, index) {
//               return ListTile(
//                 title: Text(_departments[index]),
//                 onTap: () {
//                   setState(() {
//                     _departmentController.text = _departments[index];
//                   });
//                   Navigator.pop(context);
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   void _signUp() {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });

//       // Simulate signup process - would be replaced with Firebase auth and Firestore
//       Future.delayed(const Duration(seconds: 2), () {
//         setState(() {
//           _isLoading = false;
//         });

//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(AppConstants.successSignUp),
//             backgroundColor: Colors.green,
//           ),
//         );

//         // Navigate to pending approval screen
//         Navigator.pushReplacementNamed(context, '/pending-approval');
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sign Up'),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Create an Account',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Please fill in all the required details',
//                   style: TextStyle(
//                     color: Colors.black54,
//                   ),
//                 ),
//                 const SizedBox(height: 32),
                
//                 // Name Field
//                 CustomTextField(
//                   controller: _nameController,
//                   hintText: 'Full Name',
//                   prefixIcon: Icons.person,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your name';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Email Field
//                 CustomTextField(
//                   controller: _emailController,
//                   hintText: 'Email',
//                   prefixIcon: Icons.email,
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your email';
//                     }
//                     if (!value.contains('@')) {
//                       return 'Please enter a valid email';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Password Field
//                 CustomTextField(
//                   controller: _passwordController,
//                   hintText: 'Password',
//                   prefixIcon: Icons.lock,
//                   isPassword: true,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a password';
//                     }
//                     if (value.length < 6) {
//                       return 'Password must be at least 6 characters';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Volunteer ID Field
//                 CustomTextField(
//                   controller: _volunteerIdController,
//                   hintText: 'Volunteer ID',
//                   prefixIcon: Icons.badge,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your volunteer ID';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Blood Group Field
//                 CustomTextField(
//                   controller: _bloodGroupController,
//                   hintText: 'Blood Group',
//                   prefixIcon: Icons.bloodtype,
//                   readOnly: true,
//                   onTap: _showBloodGroupPicker,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please select your blood group';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Place Field
//                 CustomTextField(
//                   controller: _placeController,
//                   hintText: 'Place',
//                   prefixIcon: Icons.location_on,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter your place';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Department Field
//                 CustomTextField(
//                   controller: _departmentController,
//                   hintText: 'Department',
//                   prefixIcon: Icons.school,
//                   readOnly: true,
//                   onTap: _showDepartmentPicker,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please select your department';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 32),
                
//                 // Sign Up Button
//                 CustomButton(
//                   text: 'Sign Up',
//                   isLoading: _isLoading,
//                   onPressed: _signUp,
//                 ),
//                 const SizedBox(height: 24),
                
//                 // Login Link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('Already have an account?'),
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                       child: const Text('Login'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }