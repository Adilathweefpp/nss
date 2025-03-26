import 'package:flutter/material.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:nss_app/services/admin_profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final List<String> _titles = [
    'Dashboard', 
    'Volunteers', 
    'Events', 
    'Admins',
    'Feedback', // Added Feedback option
    'Profile'
  ];
  
  // Real data variables
  UserModel? _currentAdmin;
  int _totalVolunteers = 0;
  int _approvedVolunteers = 0;
  int _pendingVolunteers = 0;
  int _totalEvents = 0;
  int _upcomingEvents = 0;
  int _ongoingEvents = 0;
  int _pastEvents = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Get admin profile
      final adminService = Provider.of<AdminProfileService>(context, listen: false);
      final admin = await adminService.getCurrentAdminProfile();
      
      if (admin == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not retrieve admin profile';
        });
        return;
      }
      
      // Get Firestore instance
      final firestore = FirebaseFirestore.instance;
      
      // Get volunteer counts
      final volunteersSnapshot = await firestore.collection('users').where('role', isEqualTo: 'volunteer').get();
      final totalVolunteers = volunteersSnapshot.docs.length;
      final approvedVolunteers = volunteersSnapshot.docs.where((doc) => doc.data()['isApproved'] == true).length;
      final pendingVolunteers = totalVolunteers - approvedVolunteers;
      
      // Get event counts
      final now = DateTime.now();
      final eventsSnapshot = await firestore.collection('events').get();
      final totalEvents = eventsSnapshot.docs.length;
      
      int upcomingCount = 0;
      int ongoingCount = 0;
      int pastCount = 0;
      
      for (var doc in eventsSnapshot.docs) {
        final data = doc.data();
        final startDate = (data['startDate'] as Timestamp).toDate();
        final endDate = (data['endDate'] as Timestamp).toDate();
        
        if (startDate.isAfter(now)) {
          upcomingCount++;
        } else if (endDate.isBefore(now)) {
          pastCount++;
        } else {
          ongoingCount++;
        }
      }
      
      // Update state with real data
      if (mounted) {
        setState(() {
          _currentAdmin = admin;
          _totalVolunteers = totalVolunteers;
          _approvedVolunteers = approvedVolunteers;
          _pendingVolunteers = pendingVolunteers;
          _totalEvents = totalEvents;
          _upcomingEvents = upcomingCount;
          _ongoingEvents = ongoingCount;
          _pastEvents = pastCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data: ${e.toString()}';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Show notifications
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildBody(),
    );
  }

  Widget _buildErrorView() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 150,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDashboardData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    if (_currentAdmin == null) {
      return const Drawer(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    _currentAdmin!.name.isNotEmpty ? _currentAdmin!.name.substring(0, 1) : 'A',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentAdmin!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentAdmin!.email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            index: 0,
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Volunteer Management',
            index: 1,
          ),
          _buildDrawerItem(
            icon: Icons.event,
            title: 'Event Management',
            index: 2,
          ),
          _buildDrawerItem(
            icon: Icons.admin_panel_settings,
            title: 'Admin Management',
            index: 3,
          ),
          _buildDrawerItem(
            icon: Icons.feedback,
            title: 'Feedback',
            index: 4,
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            index: 5,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final adminService = Provider.of<AdminProfileService>(context, listen: false);
              await adminService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? Theme.of(context).primaryColor : null,
          fontWeight: _selectedIndex == index ? FontWeight.bold : null,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        // Navigate to Volunteer Management
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, '/admin/volunteers');
        });
        return Container();
      case 2:
        // Navigate to Event Management
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, '/admin/events');
        });
        return Container();
      case 3:
        // Navigate to Admin Management
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, '/admin/admins');
        });
        return Container();
      case 4:
        // Navigate to Feedback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, '/admin/feedback');
        });
        return Container();
      case 5:
        // Navigate to Profile
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, '/admin/profile');
        });
        return Container();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    if (_currentAdmin == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome ${_currentAdmin!.name}!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You have $_pendingVolunteers pending approvals',
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Quick Actions Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildQuickActionCard(
                  context,
                  icon: Icons.how_to_reg,
                  title: 'Approve Volunteers',
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/pending-approvals');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.event_available,
                  title: 'Create Event',
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/create-event');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.fact_check,
                  title: 'Mark Attendance',
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/attendance-management');
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.person_add,
                  title: 'Add Admin',
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/add-admin');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Statistics Section
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Volunteers Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Volunteers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          value: _totalVolunteers.toString(),
                          label: 'Total',
                          color: Colors.blue,
                        ),
                        _buildStatColumn(
                          value: _approvedVolunteers.toString(),
                          label: 'Approved',
                          color: Colors.green,
                        ),
                        _buildStatColumn(
                          value: _pendingVolunteers.toString(),
                          label: 'Pending',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Events Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Events',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          value: _totalEvents.toString(),
                          label: 'Total',
                          color: Colors.blue,
                        ),
                        _buildStatColumn(
                          value: _upcomingEvents.toString(),
                          label: 'Upcoming',
                          color: Colors.green,
                        ),
                        _buildStatColumn(
                          value: _ongoingEvents.toString(),
                          label: 'Ongoing',
                          color: Colors.orange,
                        ),
                        _buildStatColumn(
                          value: _pastEvents.toString(),
                          label: 'Past',
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}














// import 'package:flutter/material.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:provider/provider.dart';
// import 'package:nss_app/services/admin_profile_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AdminDashboard extends StatefulWidget {
//   const AdminDashboard({Key? key}) : super(key: key);

//   @override
//   State<AdminDashboard> createState() => _AdminDashboardState();
// }

// class _AdminDashboardState extends State<AdminDashboard> {
//   int _selectedIndex = 0;
//   final List<String> _titles = [
//     'Dashboard', 
//     'Volunteers', 
//     'Events', 
//     'Admins', 
//     'Profile'
//   ];
  
//   // Real data variables
//   UserModel? _currentAdmin;
//   int _totalVolunteers = 0;
//   int _approvedVolunteers = 0;
//   int _pendingVolunteers = 0;
//   int _totalEvents = 0;
//   int _upcomingEvents = 0;
//   int _ongoingEvents = 0;
//   int _pastEvents = 0;
//   bool _isLoading = true;
//   String _errorMessage = '';
  
//   @override
//   void initState() {
//     super.initState();
//     _loadDashboardData();
//   }
  
//   Future<void> _loadDashboardData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });
    
//     try {
//       // Get admin profile
//       final adminService = Provider.of<AdminProfileService>(context, listen: false);
//       final admin = await adminService.getCurrentAdminProfile();
      
//       if (admin == null) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'Could not retrieve admin profile';
//         });
//         return;
//       }
      
//       // Get Firestore instance
//       final firestore = FirebaseFirestore.instance;
      
//       // Get volunteer counts
//       final volunteersSnapshot = await firestore.collection('users').where('role', isEqualTo: 'volunteer').get();
//       final totalVolunteers = volunteersSnapshot.docs.length;
//       final approvedVolunteers = volunteersSnapshot.docs.where((doc) => doc.data()['isApproved'] == true).length;
//       final pendingVolunteers = totalVolunteers - approvedVolunteers;
      
//       // Get event counts
//       final now = DateTime.now();
//       final eventsSnapshot = await firestore.collection('events').get();
//       final totalEvents = eventsSnapshot.docs.length;
      
//       int upcomingCount = 0;
//       int ongoingCount = 0;
//       int pastCount = 0;
      
//       for (var doc in eventsSnapshot.docs) {
//         final data = doc.data();
//         final startDate = (data['startDate'] as Timestamp).toDate();
//         final endDate = (data['endDate'] as Timestamp).toDate();
        
//         if (startDate.isAfter(now)) {
//           upcomingCount++;
//         } else if (endDate.isBefore(now)) {
//           pastCount++;
//         } else {
//           ongoingCount++;
//         }
//       }
      
//       // Update state with real data
//       if (mounted) {
//         setState(() {
//           _currentAdmin = admin;
//           _totalVolunteers = totalVolunteers;
//           _approvedVolunteers = approvedVolunteers;
//           _pendingVolunteers = pendingVolunteers;
//           _totalEvents = totalEvents;
//           _upcomingEvents = upcomingCount;
//           _ongoingEvents = ongoingCount;
//           _pastEvents = pastCount;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error loading dashboard data: $e');
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'Failed to load data: ${e.toString()}';
//         });
//       }
//     }
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_titles[_selectedIndex]),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: () {
//               // Show notifications
//             },
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(),
//       body: _isLoading 
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage.isNotEmpty
//               ? _buildErrorView()
//               : _buildBody(),
//     );
//   }

//   Widget _buildErrorView() {
//     return RefreshIndicator(
//       onRefresh: _loadDashboardData,
//       child: SingleChildScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         child: SizedBox(
//           height: MediaQuery.of(context).size.height - 150,
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.error_outline, size: 64, color: Colors.red),
//                 const SizedBox(height: 16),
//                 Text(
//                   _errorMessage,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(color: Colors.red),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: _loadDashboardData,
//                   child: const Text('Retry'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Drawer _buildDrawer() {
//     if (_currentAdmin == null) {
//       return const Drawer(
//         child: Center(child: CircularProgressIndicator()),
//       );
//     }
    
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(
//               color: Theme.of(context).primaryColor,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.white,
//                   child: Text(
//                     _currentAdmin!.name.isNotEmpty ? _currentAdmin!.name.substring(0, 1) : 'A',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).primaryColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   _currentAdmin!.name,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   _currentAdmin!.email,
//                   style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _buildDrawerItem(
//             icon: Icons.dashboard,
//             title: 'Dashboard',
//             index: 0,
//           ),
//           _buildDrawerItem(
//             icon: Icons.people,
//             title: 'Volunteer Management',
//             index: 1,
//           ),
//           _buildDrawerItem(
//             icon: Icons.event,
//             title: 'Event Management',
//             index: 2,
//           ),
//           _buildDrawerItem(
//             icon: Icons.admin_panel_settings,
//             title: 'Admin Management',
//             index: 3,
//           ),
//           _buildDrawerItem(
//             icon: Icons.person,
//             title: 'Profile',
//             index: 4,
//           ),
//           const Divider(),
//           ListTile(
//             leading: const Icon(Icons.logout),
//             title: const Text('Logout'),
//             onTap: () async {
//               final adminService = Provider.of<AdminProfileService>(context, listen: false);
//               await adminService.signOut();
//               if (mounted) {
//                 Navigator.pushReplacementNamed(context, '/login');
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String title,
//     required int index,
//   }) {
//     return ListTile(
//       leading: Icon(
//         icon,
//         color: _selectedIndex == index ? Theme.of(context).primaryColor : null,
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: _selectedIndex == index ? Theme.of(context).primaryColor : null,
//           fontWeight: _selectedIndex == index ? FontWeight.bold : null,
//         ),
//       ),
//       selected: _selectedIndex == index,
//       onTap: () {
//         setState(() {
//           _selectedIndex = index;
//         });
//         Navigator.pop(context);
//       },
//     );
//   }

//   Widget _buildBody() {
//     switch (_selectedIndex) {
//       case 0:
//         return _buildDashboardTab();
//       case 1:
//         // Navigate to Volunteer Management
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushNamed(context, '/admin/volunteers');
//         });
//         return Container();
//       case 2:
//         // Navigate to Event Management
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushNamed(context, '/admin/events');
//         });
//         return Container();
//       case 3:
//         // Navigate to Admin Management
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushNamed(context, '/admin/admins');
//         });
//         return Container();
//       case 4:
//         // Navigate to Profile
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushNamed(context, '/admin/profile');
//         });
//         return Container();
//       default:
//         return _buildDashboardTab();
//     }
//   }

//   Widget _buildDashboardTab() {
//     if (_currentAdmin == null) {
//       return const Center(child: CircularProgressIndicator());
//     }
    
//     return RefreshIndicator(
//       onRefresh: _loadDashboardData,
//       child: SingleChildScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Card
//             Card(
//               color: Theme.of(context).primaryColor,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     const CircleAvatar(
//                       radius: 30,
//                       backgroundColor: Colors.white,
//                       child: Icon(
//                         Icons.admin_panel_settings,
//                         color: Colors.blue,
//                         size: 30,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Welcome ${_currentAdmin!.name}!',
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'You have $_pendingVolunteers pending approvals',
//                             style: const TextStyle(
//                               color: Colors.white70,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
            
//             // Quick Actions
//             const Text(
//               'Quick Actions',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             // Quick Actions Grid
//             GridView.count(
//               crossAxisCount: 2,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               children: [
//                 _buildQuickActionCard(
//                   context,
//                   icon: Icons.how_to_reg,
//                   title: 'Approve Volunteers',
//                   onTap: () {
//                     Navigator.pushNamed(context, '/admin/pending-approvals');
//                   },
//                 ),
//                 _buildQuickActionCard(
//                   context,
//                   icon: Icons.event_available,
//                   title: 'Create Event',
//                   onTap: () {
//                     Navigator.pushNamed(context, '/admin/create-event');
//                   },
//                 ),
//                 _buildQuickActionCard(
//                   context,
//                   icon: Icons.fact_check,
//                   title: 'Mark Attendance',
//                   onTap: () {
//                     Navigator.pushNamed(context, '/admin/attendance-management');
//                   },
//                 ),
//                 _buildQuickActionCard(
//                   context,
//                   icon: Icons.person_add,
//                   title: 'Add Admin',
//                   onTap: () {
//                     Navigator.pushNamed(context, '/admin/add-admin');
//                   },
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
            
//             // Statistics Section
//             const Text(
//               'Overview',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             // Volunteers Statistics
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.people,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text(
//                           'Volunteers',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         _buildStatColumn(
//                           value: _totalVolunteers.toString(),
//                           label: 'Total',
//                           color: Colors.blue,
//                         ),
//                         _buildStatColumn(
//                           value: _approvedVolunteers.toString(),
//                           label: 'Approved',
//                           color: Colors.green,
//                         ),
//                         _buildStatColumn(
//                           value: _pendingVolunteers.toString(),
//                           label: 'Pending',
//                           color: Colors.orange,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Events Statistics
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.event,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text(
//                           'Events',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         _buildStatColumn(
//                           value: _totalEvents.toString(),
//                           label: 'Total',
//                           color: Colors.blue,
//                         ),
//                         _buildStatColumn(
//                           value: _upcomingEvents.toString(),
//                           label: 'Upcoming',
//                           color: Colors.green,
//                         ),
//                         _buildStatColumn(
//                           value: _ongoingEvents.toString(),
//                           label: 'Ongoing',
//                           color: Colors.orange,
//                         ),
//                         _buildStatColumn(
//                           value: _pastEvents.toString(),
//                           label: 'Past',
//                           color: Colors.grey,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickActionCard(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       child: InkWell(
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 size: 40,
//                 color: Theme.of(context).primaryColor,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatColumn({
//     required String value,
//     required String label,
//     required Color color,
//   }) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: const TextStyle(
//             color: Colors.black54,
//           ),
//         ),
//       ],
//     );
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';

// class AdminDashboard extends StatefulWidget {
//   const AdminDashboard({Key? key}) : super(key: key);

//   @override
//   State<AdminDashboard> createState() => _AdminDashboardState();
// }

// class _AdminDashboardState extends State<AdminDashboard> {
//   int _selectedIndex = 0;
//   final List<String> _titles = [
//     'Dashboard', 
//     'Volunteers', 
//     'Events', 
//     'Admins', 
//     'Profile'
//   ];
  
//   // Mock admin for UI development
//   final UserModel _currentAdmin = UserModel.getMockAdmins().first;
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_titles[_selectedIndex]),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications),
//             onPressed: () {
//               // Show notifications
//             },
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(),
//       body: _buildBody(),
//     );
//   }

//   Drawer _buildDrawer() {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(
//               color: Theme.of(context).primaryColor,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.white,
//                   child: Text(
//                     _currentAdmin.name.substring(0, 1),
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).primaryColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   _currentAdmin.name,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   _currentAdmin.email,
//                   style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _buildDrawerItem(
//             icon: Icons.dashboard,
//             title: 'Dashboard',
//             index: 0,
//           ),
//           _buildDrawerItem(
//             icon: Icons.people,
//             title: 'Volunteer Management',
//             index: 1,
//           ),
//           _buildDrawerItem(
//             icon: Icons.event,
//             title: 'Event Management',
//             index: 2,
//           ),
//           _buildDrawerItem(
//             icon: Icons.admin_panel_settings,
//             title: 'Admin Management',
//             index: 3,
//           ),
//           _buildDrawerItem(
//             icon: Icons.person,
//             title: 'Profile',
//             index: 4,
//           ),
//           const Divider(),
//           ListTile(
//             leading: const Icon(Icons.logout),
//             title: const Text('Logout'),
//             onTap: () {
//               Navigator.pushReplacementNamed(context, '/login');
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String title,
//     required int index,
//   }) {
//     return ListTile(
//       leading: Icon(
//         icon,
//         color: _selectedIndex == index ? Theme.of(context).primaryColor : null,
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: _selectedIndex == index ? Theme.of(context).primaryColor : null,
//           fontWeight: _selectedIndex == index ? FontWeight.bold : null,
//         ),
//       ),
//       selected: _selectedIndex == index,
//       onTap: () {
//         setState(() {
//           _selectedIndex = index;
//         });
//         Navigator.pop(context);
//       },
//     );
//   }

//   Widget _buildBody() {
//     switch (_selectedIndex) {
//       case 0:
//         return _buildDashboardTab();
//       case 1:
//         // Navigate to Volunteer Management
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushNamed(context, '/admin/volunteers');
//         });
//         return Container();
//       case 2:
//         // Navigate to Event Management
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushNamed(context, '/admin/events');
//         });
//         return Container();
//       case 3:
//         // Navigate to Admin Management
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushNamed(context, '/admin/admins');
//         });
//         return Container();
//       case 4:
//         // Navigate to Profile
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Navigator.pushNamed(context, '/admin/profile');
//         });
//         return Container();
//       default:
//         return _buildDashboardTab();
//     }
//   }

//   Widget _buildDashboardTab() {
//     // Get statistics for dashboard
//     final volunteers = UserModel.getMockVolunteers();
//     final approvedVolunteers = volunteers.where((user) => user.isApproved).length;
//     final pendingVolunteers = volunteers.where((user) => !user.isApproved).length;
    
//     final events = EventModel.getMockEvents();
//     final upcomingEvents = events.where((event) => event.isUpcoming).length;
//     final ongoingEvents = events.where((event) => event.isOngoing).length;
//     final pastEvents = events.where((event) => event.isPast).length;
    
//     return RefreshIndicator(
//       onRefresh: () async {
//         // Simulate refreshing data
//         await Future.delayed(const Duration(seconds: 1));
//         setState(() {
//           // Refresh data
//         });
//       },
//       child: SingleChildScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Card
//             Card(
//               color: Theme.of(context).primaryColor,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     const CircleAvatar(
//                       radius: 30,
//                       backgroundColor: Colors.white,
//                       child: Icon(
//                         Icons.admin_panel_settings,
//                         color: Colors.blue,
//                         size: 30,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Welcome Admin!',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'You have $pendingVolunteers pending approvals',
//                             style: const TextStyle(
//                               color: Colors.white70,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
            
//             // Quick Actions
//             const Text(
//               'Quick Actions',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             // Quick Actions Grid
//             GridView.count(
//               crossAxisCount: 2,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               children: [
//                 _buildQuickActionCard(
//                   context,
//                   icon: Icons.how_to_reg,
//                   title: 'Approve Volunteers',
//                   onTap: () {
//                     Navigator.pushNamed(context, '/admin/pending-approvals');
//                   },
//                 ),
//                 _buildQuickActionCard(
//                   context,
//                   icon: Icons.event_available,
//                   title: 'Create Event',
//                   onTap: () {
//                     Navigator.pushNamed(context, '/admin/create-event');
//                   },
//                 ),
//                 _buildQuickActionCard(
//                   context,
//                   icon: Icons.fact_check,
//                   title: 'Mark Attendance',
//                   onTap: () {
//                     Navigator.pushNamed(context, '/admin/attendance-management');
//                   },
//                 ),
//                 _buildQuickActionCard(
//                   context,
//                   icon: Icons.person_add,
//                   title: 'Add Admin',
//                   onTap: () {
//                     Navigator.pushNamed(context, '/admin/add-admin');
//                   },
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
            
//             // Statistics Section
//             const Text(
//               'Overview',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             // Volunteers Statistics
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.people,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text(
//                           'Volunteers',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         _buildStatColumn(
//                           value: volunteers.length.toString(),
//                           label: 'Total',
//                           color: Colors.blue,
//                         ),
//                         _buildStatColumn(
//                           value: approvedVolunteers.toString(),
//                           label: 'Approved',
//                           color: Colors.green,
//                         ),
//                         _buildStatColumn(
//                           value: pendingVolunteers.toString(),
//                           label: 'Pending',
//                           color: Colors.orange,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Events Statistics
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.event,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text(
//                           'Events',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         _buildStatColumn(
//                           value: events.length.toString(),
//                           label: 'Total',
//                           color: Colors.blue,
//                         ),
//                         _buildStatColumn(
//                           value: upcomingEvents.toString(),
//                           label: 'Upcoming',
//                           color: Colors.green,
//                         ),
//                         _buildStatColumn(
//                           value: ongoingEvents.toString(),
//                           label: 'Ongoing',
//                           color: Colors.orange,
//                         ),
//                         _buildStatColumn(
//                           value: pastEvents.toString(),
//                           label: 'Past',
//                           color: Colors.grey,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
            
//             // Recent Pending Approvals
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Recent Pending Approvals',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 if (pendingVolunteers > 0)
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pushNamed(context, '/admin/pending-approvals');
//                     },
//                     child: const Text('View All'),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 12),
            
//             if (pendingVolunteers > 0)
//               ...UserModel.getMockPendingVolunteers().take(3).map((volunteer) => 
//                 Card(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       child: Text(volunteer.name.substring(0, 1)),
//                     ),
//                     title: Text(volunteer.name),
//                     subtitle: Text(volunteer.department),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.check, color: Colors.green),
//                           onPressed: () {
//                             // Approve volunteer
//                           },
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.close, color: Colors.red),
//                           onPressed: () {
//                             // Reject volunteer
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ).toList()
//             else
//               const Card(
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Center(
//                     child: Text(
//                       'No pending approvals',
//                       style: TextStyle(
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickActionCard(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       child: InkWell(
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 size: 40,
//                 color: Theme.of(context).primaryColor,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatColumn({
//     required String value,
//     required String label,
//     required Color color,
//   }) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: const TextStyle(
//             color: Colors.black54,
//           ),
//         ),
//       ],
//     );
//   }
// }