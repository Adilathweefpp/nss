import 'package:flutter/material.dart';
import 'package:nss_app/models/attendance_model.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:nss_app/services/volunteer_manage_service.dart';
import 'package:nss_app/widgets/common/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VolunteerDetailsScreen extends StatefulWidget {
  const VolunteerDetailsScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerDetailsScreen> createState() => _VolunteerDetailsScreenState();
}

class _VolunteerDetailsScreenState extends State<VolunteerDetailsScreen> {
  bool _isLoading = false;

  Future<void> _removeVolunteer(UserModel volunteer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Volunteer'),
        content:
            Text('Are you sure you want to remove ${volunteer.name} from NSS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final volunteerService = Provider.of<VolunteerManageService>(context, listen: false);
        final success = await volunteerService.removeVolunteer(volunteer.volunteerId);
        
        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Volunteer removed successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Go back to volunteer list
          Navigator.pop(context);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove volunteer'),
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
  }

  @override
  Widget build(BuildContext context) {
    // Get volunteer from arguments or use a mock volunteer for UI development
    final volunteer =
        ModalRoute.of(context)?.settings.arguments as UserModel? ??
            UserModel.getMockVolunteers().first;

    // Calculate attendance percentage
    final attendancePercentage =
        AttendanceModel.calculateAttendancePercentage(volunteer.id);

    // Get events count the volunteer has participated in
    final eventsParticipatedCount = volunteer.eventsParticipated.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'remove') {
                _removeVolunteer(volunteer);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Remove Volunteer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            volunteer.name.isNotEmpty ? volunteer.name.substring(0, 1) : 'V',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                volunteer.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Volunteer ID: ${volunteer.volunteerId}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                volunteer.email,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${volunteer.isApproved ? 'Approved' : 'Pending'}',
                                style: TextStyle(
                                  color: volunteer.isApproved ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Volunteer Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Department', volunteer.department),
                          const Divider(),
                          _buildDetailRow(
                              'Blood Group', volunteer.bloodGroup),
                          const Divider(),
                          _buildDetailRow('Place', volunteer.place),
                          const Divider(),
                          _buildDetailRow(
                            'Joined On',
                            DateFormat('MMM dd, yyyy')
                                .format(volunteer.createdAt),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Show attendance stats only for approved volunteers
                    if (volunteer.isApproved) ...[
                      // Attendance Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              value:
                                  '${attendancePercentage.toStringAsFixed(1)}%',
                              label: 'Attendance',
                              color: _getAttendanceColor(attendancePercentage),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              value: eventsParticipatedCount.toString(),
                              label: 'Events Participated',
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: volunteer.isApproved
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButton(
                text: 'Mark Attendance',
                onPressed: () {
                  Navigator.pushNamed(context, '/admin/attendance-management');
                },
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green;
    } else if (percentage >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}


















// import 'package:flutter/material.dart';
// import 'package:nss_app/models/attendance_model.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:nss_app/utils/constants.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:intl/intl.dart';

// class VolunteerDetailsScreen extends StatefulWidget {
//   const VolunteerDetailsScreen({Key? key}) : super(key: key);

//   @override
//   State<VolunteerDetailsScreen> createState() => _VolunteerDetailsScreenState();
// }

// class _VolunteerDetailsScreenState extends State<VolunteerDetailsScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   Future<void> _removeVolunteer(UserModel volunteer) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Remove Volunteer'),
//         content:
//             Text('Are you sure you want to remove ${volunteer.name} from NSS?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(
//               foregroundColor: Colors.red,
//             ),
//             child: const Text('Remove'),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       setState(() {
//         _isLoading = true;
//       });

//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 1));

//       setState(() {
//         _isLoading = false;
//       });

//       if (!mounted) return;

//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Volunteer removed successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );

//       // Go back to volunteer list
//       Navigator.pop(context);
//     }
//   }

//   Future<void> _makeAdmin(UserModel volunteer) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Make Admin'),
//         content:
//             Text('Are you sure you want to make ${volunteer.name} an admin?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Confirm'),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       setState(() {
//         _isLoading = true;
//       });

//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 1));

//       setState(() {
//         _isLoading = false;
//       });

//       if (!mounted) return;

//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(AppConstants.successAdminAdded),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Get volunteer from arguments or use a mock volunteer for UI development
//     final volunteer =
//         ModalRoute.of(context)?.settings.arguments as UserModel? ??
//             UserModel.getMockVolunteers().first;

//     // Calculate attendance percentage
//     final attendancePercentage =
//         AttendanceModel.calculateAttendancePercentage(volunteer.id);

//     // Get events the volunteer has participated in
//     final participatedEvents = EventModel.getMockEvents()
//         .where((event) => event.registeredParticipants.contains(volunteer.id))
//         .toList();

//     // Get all past events the volunteer participated in
//     final pastEvents =
//         participatedEvents.where((event) => event.isPast).toList();

//     // Get upcoming events the volunteer has registered for
//     final upcomingEvents =
//         participatedEvents.where((event) => !event.isPast).toList();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Volunteer Details'),
//         actions: [
//           PopupMenuButton<String>(
//             onSelected: (value) {
//               if (value == 'make_admin') {
//                 _makeAdmin(volunteer);
//               } else if (value == 'remove') {
//                 _removeVolunteer(volunteer);
//               }
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem<String>(
//                 value: 'make_admin',
//                 child: Row(
//                   children: [
//                     Icon(Icons.admin_panel_settings, color: Colors.blue),
//                     SizedBox(width: 8),
//                     Text('Make Admin'),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem<String>(
//                 value: 'remove',
//                 child: Row(
//                   children: [
//                     Icon(Icons.delete, color: Colors.red),
//                     SizedBox(width: 8),
//                     Text('Remove Volunteer'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 // Volunteer Profile
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     children: [
//                       // Profile Header
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           CircleAvatar(
//                             radius: 40,
//                             backgroundColor: Theme.of(context).primaryColor,
//                             child: Text(
//                               volunteer.name.substring(0, 1),
//                               style: const TextStyle(
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   volunteer.name,
//                                   style: const TextStyle(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'Volunteer ID: ${volunteer.volunteerId}',
//                                   style: const TextStyle(
//                                     color: Colors.black54,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   volunteer.email,
//                                   style: const TextStyle(
//                                     color: Colors.black54,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 24),

//                       // Volunteer Details
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade100,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           children: [
//                             _buildDetailRow('Department', volunteer.department),
//                             const Divider(),
//                             _buildDetailRow(
//                                 'Blood Group', volunteer.bloodGroup),
//                             const Divider(),
//                             _buildDetailRow('Place', volunteer.place),
//                             const Divider(),
//                             _buildDetailRow(
//                               'Joined On',
//                               DateFormat('MMM dd, yyyy')
//                                   .format(volunteer.createdAt),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 24),

//                       // Attendance Stats
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _buildStatCard(
//                               context,
//                               value:
//                                   '${attendancePercentage.toStringAsFixed(1)}%',
//                               label: 'Attendance',
//                               color: _getAttendanceColor(attendancePercentage),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: _buildStatCard(
//                               context,
//                               value: participatedEvents.length.toString(),
//                               label: 'Events Participated',
//                               color: Theme.of(context).primaryColor,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Events Tab
//                 TabBar(
//                   controller: _tabController,
//                   labelColor: Theme.of(context).primaryColor,
//                   tabs: const [
//                     Tab(
//                       text: 'Upcoming Events',
//                     ),
//                     Tab(
//                       text: 'Past Events',
//                     ),
//                   ],
//                 ),

//                 // Events TabView
//                 Expanded(
//                   child: TabBarView(
//                     controller: _tabController,
//                     children: [
//                       // Upcoming Events Tab
//                       _buildEventList(
//                         upcomingEvents,
//                         'No upcoming events',
//                       ),

//                       // Past Events Tab
//                       _buildEventList(
//                         pastEvents,
//                         'No past events',
//                         isPast: true,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16),
//         child: CustomButton(
//           text: 'Mark Attendance',
//           onPressed: () {
//             Navigator.pushNamed(context, '/admin/attendance-management');
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.black54,
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(
//     BuildContext context, {
//     required String value,
//     required String label,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.5)),
//       ),
//       child: Column(
//         children: [
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.black54,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEventList(List<EventModel> events, String emptyMessage,
//       {bool isPast = false}) {
//     if (events.isEmpty) {
//       return Center(
//         child: Text(
//           emptyMessage,
//           style: const TextStyle(
//             color: Colors.grey,
//           ),
//         ),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: events.length,
//       itemBuilder: (context, index) {
//         final event = events[index];
//         final dateFormat = DateFormat('MMM dd, yyyy');

//         return Card(
//           margin: const EdgeInsets.only(bottom: 8),
//           child: ListTile(
//             title: Text(
//               event.title,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.calendar_today,
//                         size: 16, color: Colors.grey),
//                     const SizedBox(width: 8),
//                     Text(dateFormat.format(event.startDate)),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.location_on, size: 16, color: Colors.grey),
//                     const SizedBox(width: 8),
//                     Text(event.location),
//                   ],
//                 ),
//               ],
//             ),
//             isThreeLine: true,
//             trailing: isPast
//                 ? _buildAttendanceIndicator(event.id, event)
//                 : _getEventStatusIndicator(event),
//             onTap: () {
//               Navigator.pushNamed(
//                 context,
//                 '/admin/event-details',
//                 arguments: event,
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildAttendanceIndicator(String volunteerId, EventModel event) {
//     final isPresent =
//         AttendanceModel.wasVolunteerPresent(volunteerId, event.id);

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: isPresent
//             ? Colors.green.withOpacity(0.1)
//             : Colors.red.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(4),
//         border: Border.all(
//           color: isPresent ? Colors.green : Colors.red,
//         ),
//       ),
//       child: Text(
//         isPresent ? 'Present' : 'Absent',
//         style: TextStyle(
//           color: isPresent ? Colors.green : Colors.red,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _getEventStatusIndicator(EventModel event) {
//     if (event.isOngoing) {
//       return Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.orange.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(color: Colors.orange),
//         ),
//         child: const Text(
//           'Ongoing',
//           style: TextStyle(
//             color: Colors.orange,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       );
//     } else {
//       return Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.blue.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(color: Colors.blue),
//         ),
//         child: const Text(
//           'Upcoming',
//           style: TextStyle(
//             color: Colors.blue,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       );
//     }
//   }

//   Color _getAttendanceColor(double percentage) {
//     if (percentage >= 75) {
//       return Colors.green;
//     } else if (percentage >= 60) {
//       return Colors.orange;
//     } else {
//       return Colors.red;
//     }
//   }
// }







// import 'package:flutter/material.dart';
// import 'package:nss_app/models/attendance_model.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:nss_app/utils/constants.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:intl/intl.dart';

// class VolunteerDetailsScreen extends StatefulWidget {
//   const VolunteerDetailsScreen({Key? key}) : super(key: key);

//   @override
//   State<VolunteerDetailsScreen> createState() => _VolunteerDetailsScreenState();
// }

// class _VolunteerDetailsScreenState extends State<VolunteerDetailsScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   Future<void> _removeVolunteer(UserModel volunteer) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Remove Volunteer'),
//         content: Text('Are you sure you want to remove ${volunteer.name} from NSS?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(
//               foregroundColor: Colors.red,
//             ),
//             child: const Text('Remove'),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       setState(() {
//         _isLoading = true;
//       });
      
//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 1));
      
//       setState(() {
//         _isLoading = false;
//       });
      
//       if (!mounted) return;
      
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Volunteer removed successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );
      
//       // Go back to volunteer list
//       Navigator.pop(context);
//     }
//   }

//   Future<void> _makeAdmin(UserModel volunteer) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Make Admin'),
//         content: Text('Are you sure you want to make ${volunteer.name} an admin?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Confirm'),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       setState(() {
//         _isLoading = true;
//       });
      
//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 1));
      
//       setState(() {
//         _isLoading = false;
//       });
      
//       if (!mounted) return;
      
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(AppConstants.successAdminAdded),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Get volunteer from arguments or use a mock volunteer for UI development
//     final volunteer = ModalRoute.of(context)?.settings.arguments as UserModel? ??
//         UserModel.getMockVolunteers().first;

//     // Calculate attendance percentage
//     final attendancePercentage = AttendanceModel.calculateAttendancePercentage(volunteer.id);
    
//     // Get events the volunteer has participated in
//     final participatedEvents = EventModel.getMockEvents()
//         .where((event) => event.approvedParticipants.contains(volunteer.id))
//         .toList();
    
//     // Get events the volunteer has registered for but not approved yet
//     final pendingEvents = EventModel.getMockEvents()
//         .where((event) => 
//             event.registeredParticipants.contains(volunteer.id) &&
//             !event.approvedParticipants.contains(volunteer.id) &&
//             !event.isPast)
//         .toList();
    
//     // Get all past events the volunteer participated in
//     final pastEvents = participatedEvents
//         .where((event) => event.isPast)
//         .toList();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Volunteer Details'),
//         actions: [
//           PopupMenuButton<String>(
//             onSelected: (value) {
//               if (value == 'make_admin') {
//                 _makeAdmin(volunteer);
//               } else if (value == 'remove') {
//                 _removeVolunteer(volunteer);
//               }
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem<String>(
//                 value: 'make_admin',
//                 child: Row(
//                   children: [
//                     Icon(Icons.admin_panel_settings, color: Colors.blue),
//                     SizedBox(width: 8),
//                     Text('Make Admin'),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem<String>(
//                 value: 'remove',
//                 child: Row(
//                   children: [
//                     Icon(Icons.delete, color: Colors.red),
//                     SizedBox(width: 8),
//                     Text('Remove Volunteer'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 // Volunteer Profile
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     children: [
//                       // Profile Header
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           CircleAvatar(
//                             radius: 40,
//                             backgroundColor: Theme.of(context).primaryColor,
//                             child: Text(
//                               volunteer.name.substring(0, 1),
//                               style: const TextStyle(
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   volunteer.name,
//                                   style: const TextStyle(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'Volunteer ID: ${volunteer.volunteerId}',
//                                   style: const TextStyle(
//                                     color: Colors.black54,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   volunteer.email,
//                                   style: const TextStyle(
//                                     color: Colors.black54,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 24),
                      
//                       // Volunteer Details
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade100,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           children: [
//                             _buildDetailRow('Department', volunteer.department),
//                             const Divider(),
//                             _buildDetailRow('Blood Group', volunteer.bloodGroup),
//                             const Divider(),
//                             _buildDetailRow('Place', volunteer.place),
//                             const Divider(),
//                             _buildDetailRow(
//                               'Joined On',
//                               DateFormat('MMM dd, yyyy').format(volunteer.createdAt),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 24),
                      
//                       // Attendance Stats
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _buildStatCard(
//                               context,
//                               value: '${attendancePercentage.toStringAsFixed(1)}%',
//                               label: 'Attendance',
//                               color: _getAttendanceColor(attendancePercentage),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: _buildStatCard(
//                               context,
//                               value: participatedEvents.length.toString(),
//                               label: 'Events Participated',
//                               color: Theme.of(context).primaryColor,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 // Events Tab
//                 TabBar(
//                   controller: _tabController,
//                   labelColor: Theme.of(context).primaryColor,
//                   tabs: const [
//                     Tab(
//                       text: 'Upcoming Events',
//                     ),
//                     Tab(
//                       text: 'Pending Approval',
//                     ),
//                     Tab(
//                       text: 'Past Events',
//                     ),
//                   ],
//                 ),
                
//                 // Events TabView
//                 Expanded(
//                   child: TabBarView(
//                     controller: _tabController,
//                     children: [
//                       // Upcoming Events Tab
//                       _buildEventList(
//                         participatedEvents.where((event) => event.isUpcoming || event.isOngoing).toList(),
//                         'No upcoming events',
//                       ),
                      
//                       // Pending Events Tab
//                       _buildEventList(
//                         pendingEvents,
//                         'No pending approvals',
//                       ),
                      
//                       // Past Events Tab
//                       _buildEventList(
//                         pastEvents,
//                         'No past events',
//                         isPast: true,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16),
//         child: CustomButton(
//           text: 'Mark Attendance',
//           onPressed: () {
//             Navigator.pushNamed(context, '/admin/attendance-management');
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.black54,
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(
//     BuildContext context, {
//     required String value,
//     required String label,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.5)),
//       ),
//       child: Column(
//         children: [
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.black54,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEventList(List<EventModel> events, String emptyMessage, {bool isPast = false}) {
//     if (events.isEmpty) {
//       return Center(
//         child: Text(
//           emptyMessage,
//           style: const TextStyle(
//             color: Colors.grey,
//           ),
//         ),
//       );
//     }
    
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: events.length,
//       itemBuilder: (context, index) {
//         final event = events[index];
//         final dateFormat = DateFormat('MMM dd, yyyy');
        
//         return Card(
//           margin: const EdgeInsets.only(bottom: 8),
//           child: ListTile(
//             title: Text(
//               event.title,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
//                     const SizedBox(width: 8),
//                     Text(dateFormat.format(event.startDate)),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.location_on, size: 16, color: Colors.grey),
//                     const SizedBox(width: 8),
//                     Text(event.location),
//                   ],
//                 ),
//               ],
//             ),
//             isThreeLine: true,
//             trailing: isPast
//                 ? _buildAttendanceIndicator(event.id, event)
//                 : _getEventStatusIndicator(event),
//             onTap: () {
//               Navigator.pushNamed(
//                 context,
//                 '/admin/event-details',
//                 arguments: event,
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildAttendanceIndicator(String volunteerId, EventModel event) {
//     final isPresent = AttendanceModel.wasVolunteerPresent(volunteerId, event.id);
    
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(4),
//         border: Border.all(
//           color: isPresent ? Colors.green : Colors.red,
//         ),
//       ),
//       child: Text(
//         isPresent ? 'Present' : 'Absent',
//         style: TextStyle(
//           color: isPresent ? Colors.green : Colors.red,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _getEventStatusIndicator(EventModel event) {
//     if (event.isOngoing) {
//       return Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.orange.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(color: Colors.orange),
//         ),
//         child: const Text(
//           'Ongoing',
//           style: TextStyle(
//             color: Colors.orange,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       );
//     } else {
//       return Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.blue.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(color: Colors.blue),
//         ),
//         child: const Text(
//           'Upcoming',
//           style: TextStyle(
//             color: Colors.blue,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       );
//     }
//   }

//   Color _getAttendanceColor(double percentage) {
//     if (percentage >= 75) {
//       return Colors.green;
//     } else if (percentage >= 60) {
//       return Colors.orange;
//     } else {
//       return Colors.red;
//     }
//   }
//}