import 'package:flutter/material.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:nss_app/services/volunteer_manage_service.dart';
import 'package:provider/provider.dart';

class VolunteerListScreen extends StatefulWidget {
  const VolunteerListScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerListScreen> createState() => _VolunteerListScreenState();
}

class _VolunteerListScreenState extends State<VolunteerListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _approvedVolunteers = [];
  List<UserModel> _pendingVolunteers = [];
  List<UserModel> _filteredApprovedVolunteers = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadVolunteers();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVolunteers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final volunteerService = Provider.of<VolunteerManageService>(context, listen: false);
      
      final approvedVolunteers = await volunteerService.getApprovedVolunteers();
      final pendingVolunteers = await volunteerService.getPendingVolunteers();
      
      setState(() {
        _approvedVolunteers = approvedVolunteers;
        _pendingVolunteers = pendingVolunteers;
        _filteredApprovedVolunteers = approvedVolunteers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading volunteers: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApprovedVolunteers = _approvedVolunteers.where((volunteer) {
        return volunteer.name.toLowerCase().contains(query) ||
            volunteer.volunteerId.toLowerCase().contains(query) ||
            volunteer.department.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Approved'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search volunteers...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                
                // Volunteer Tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Approved Volunteers Tab
                      _buildVolunteerList(
                        _filteredApprovedVolunteers,
                        'No approved volunteers found',
                      ),
                      
                      // Pending Volunteers Tab
                      _buildVolunteerList(
                        _pendingVolunteers,
                        'No pending volunteer approvals',
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to adding a new volunteer (manual registration)
          Navigator.pushNamed(context, '/signup').then((_) {
            // Refresh volunteer list when returning from add volunteer screen
            _loadVolunteers();
          });
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildVolunteerList(List<UserModel> volunteers, String emptyMessage) {
    if (volunteers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVolunteers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: volunteers.length,
        itemBuilder: (context, index) {
          final volunteer = volunteers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  volunteer.name.isNotEmpty ? volunteer.name.substring(0, 1) : 'V',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                volunteer.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('ID: ${volunteer.volunteerId}'),
                  Text('Dept: ${volunteer.department}'),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {
                  // Navigate to volunteer details
                  Navigator.pushNamed(
                    context, 
                    '/admin/volunteer-details',
                    arguments: volunteer,
                  ).then((_) {
                    // Refresh volunteer list when returning from details
                    _loadVolunteers();
                  });
                },
              ),
              onTap: () {
                // Navigate to volunteer details
                Navigator.pushNamed(
                  context, 
                  '/admin/volunteer-details',
                  arguments: volunteer,
                ).then((_) {
                  // Refresh volunteer list when returning from details
                  _loadVolunteers();
                });
              },
            ),
          );
        },
      ),
    );
  }
}















// import 'package:flutter/material.dart';
// import 'package:nss_app/models/user_model.dart';

// class VolunteerListScreen extends StatefulWidget {
//   const VolunteerListScreen({Key? key}) : super(key: key);

//   @override
//   State<VolunteerListScreen> createState() => _VolunteerListScreenState();
// }

// class _VolunteerListScreenState extends State<VolunteerListScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final TextEditingController _searchController = TextEditingController();
//   List<UserModel> _filteredVolunteers = [];
  
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _filteredVolunteers = UserModel.getMockVolunteers();
    
//     _searchController.addListener(_onSearchChanged);
//   }
  
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _onSearchChanged() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredVolunteers = UserModel.getMockVolunteers().where((volunteer) {
//         return volunteer.name.toLowerCase().contains(query) ||
//             volunteer.volunteerId.toLowerCase().contains(query) ||
//             volunteer.department.toLowerCase().contains(query);
//       }).toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Volunteer Management'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Approved'),
//             Tab(text: 'Pending'),
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           // Search Bar
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search volunteers...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
//               ),
//             ),
//           ),
          
//           // Volunteer Tabs
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 // Approved Volunteers Tab
//                 _buildVolunteerList(
//                   _filteredVolunteers.where((volunteer) => volunteer.isApproved).toList(),
//                   'No approved volunteers found',
//                 ),
                
//                 // Pending Volunteers Tab
//                 _buildVolunteerList(
//                   UserModel.getMockPendingVolunteers(),
//                   'No pending volunteer approvals',
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Navigate to adding a new volunteer (manual registration)
//           Navigator.pushNamed(context, '/signup');
//         },
//         child: const Icon(Icons.person_add),
//       ),
//     );
//   }

//   Widget _buildVolunteerList(List<UserModel> volunteers, String emptyMessage) {
//     if (volunteers.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.people_outline,
//               size: 64,
//               color: Colors.grey,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               emptyMessage,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: volunteers.length,
//       itemBuilder: (context, index) {
//         final volunteer = volunteers[index];
//         return Card(
//           margin: const EdgeInsets.only(bottom: 12),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Theme.of(context).primaryColor,
//               child: Text(
//                 volunteer.name.substring(0, 1),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             title: Text(
//               volunteer.name,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 4),
//                 Text('ID: ${volunteer.volunteerId}'),
//                 Text('Dept: ${volunteer.department}'),
//               ],
//             ),
//             isThreeLine: true,
//             trailing: IconButton(
//               icon: const Icon(Icons.arrow_forward_ios, size: 16),
//               onPressed: () {
//                 // Navigate to volunteer details
//                 Navigator.pushNamed(
//                   context, 
//                   '/admin/volunteer-details',
//                   arguments: volunteer,
//                 );
//               },
//             ),
//             onTap: () {
//               // Navigate to volunteer details
//               Navigator.pushNamed(
//                 context, 
//                 '/admin/volunteer-details',
//                 arguments: volunteer,
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }