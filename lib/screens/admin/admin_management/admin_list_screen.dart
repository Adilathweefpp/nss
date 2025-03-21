import 'package:flutter/material.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:nss_app/services/admin_manage_service.dart';
import 'package:nss_app/utils/constants.dart';
import 'package:provider/provider.dart';

class AdminListScreen extends StatefulWidget {
  const AdminListScreen({Key? key}) : super(key: key);

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  List<UserModel> _admins = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }
  
  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final adminManageService = Provider.of<AdminManageService>(context, listen: false);
      final admins = await adminManageService.getAdmins();
      
      setState(() {
        _admins = admins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showRemoveConfirmation(UserModel admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin'),
        content: Text('Are you sure you want to remove ${admin.name} as an admin?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeAdmin(admin);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _removeAdmin(UserModel admin) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final adminManageService = Provider.of<AdminManageService>(context, listen: false);
      final success = await adminManageService.removeAdmin(admin.adminId);
      
      if (success) {
        setState(() {
          _admins.removeWhere((a) => a.id == admin.id);
          _isLoading = false;
        });
        
        if (!mounted) return;
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.successAdminRemoved),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        
        if (!mounted) return;
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove admin'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/admin/add-admin').then((_) {
            // Refresh admin list when returning from add admin screen
            _loadAdmins();
          });
        },
        tooltip: 'Add Admin',
        child: const Icon(Icons.person_add),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_admins.isEmpty) {
      return const Center(
        child: Text('No admins found'),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadAdmins,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _admins.length,
        itemBuilder: (context, index) {
          final admin = _admins[index];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  admin.name.isNotEmpty ? admin.name.substring(0, 1) : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                admin.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(admin.email),
                  Text('Admin ID: ${admin.adminId}'),
                  Text('Department: ${admin.department}'),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showRemoveConfirmation(admin),
              ),
            ),
          );
        },
      ),
    );
  }
}











// import 'package:flutter/material.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:nss_app/utils/constants.dart';

// class AdminListScreen extends StatefulWidget {
//   const AdminListScreen({Key? key}) : super(key: key);

//   @override
//   State<AdminListScreen> createState() => _AdminListScreenState();
// }

// class _AdminListScreenState extends State<AdminListScreen> {
//   List<UserModel> _admins = [];
//   bool _isLoading = false;
  
//   @override
//   void initState() {
//     super.initState();
//     _loadAdmins();
//   }
  
//   void _loadAdmins() {
//     setState(() {
//       _isLoading = true;
//     });
    
//     // Simulate API call
//     Future.delayed(const Duration(seconds: 1), () {
//       setState(() {
//         _admins = UserModel.getMockAdmins();
//         _isLoading = false;
//       });
//     });
//   }
  
//   void _showRemoveConfirmation(UserModel admin) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Remove Admin'),
//         content: Text('Are you sure you want to remove ${admin.name} as an admin?'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _removeAdmin(admin);
//             },
//             style: TextButton.styleFrom(
//               foregroundColor: Colors.red,
//             ),
//             child: const Text('Remove'),
//           ),
//         ],
//       ),
//     );
//   }
  
//   void _removeAdmin(UserModel admin) {
//     setState(() {
//       _isLoading = true;
//     });
    
//     // Simulate API call
//     Future.delayed(const Duration(seconds: 1), () {
//       setState(() {
//         _admins.removeWhere((a) => a.id == admin.id);
//         _isLoading = false;
//       });
      
//       if (!mounted) return;
      
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(AppConstants.successAdminRemoved),
//           backgroundColor: Colors.green,
//         ),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Management'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _buildBody(),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.pushNamed(context, '/admin/add-admin');
//         },
//         tooltip: 'Add Admin',
//         child: const Icon(Icons.person_add),
//       ),
//     );
//   }
  
//   Widget _buildBody() {
//     if (_admins.isEmpty) {
//       return const Center(
//         child: Text('No admins found'),
//       );
//     }
    
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: _admins.length,
//       itemBuilder: (context, index) {
//         final admin = _admins[index];
        
//         return Card(
//           margin: const EdgeInsets.only(bottom: 12),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Theme.of(context).primaryColor,
//               child: Text(
//                 admin.name.substring(0, 1),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             title: Text(
//               admin.name,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 4),
//                 Text(admin.email),
//                 Text('Department: ${admin.department}'),
//               ],
//             ),
//             isThreeLine: true,
//             trailing: IconButton(
//               icon: const Icon(Icons.delete, color: Colors.red),
//               onPressed: () => _showRemoveConfirmation(admin),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }