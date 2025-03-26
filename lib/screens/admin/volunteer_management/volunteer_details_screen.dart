import 'package:flutter/material.dart';
import 'package:nss_app/models/attendance_model.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:nss_app/services/volunteer_manage_service.dart';
import 'package:nss_app/services/event_service.dart';
import 'package:nss_app/services/attendance_service.dart';
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
  bool _isLoadingStats = true;
  double _attendancePercentage = 0.0;
  int _eventsAttended = 0;
  int _eventsRegistered = 0;
  List<EventModel> _registeredEvents = [];
  List<AttendanceModel> _attendanceRecords = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // We'll load the volunteer data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVolunteerData();
    });
  }

  Future<void> _loadVolunteerData() async {
    final volunteer = ModalRoute.of(context)?.settings.arguments as UserModel?;
    if (volunteer == null) return;

    setState(() {
      _isLoadingStats = true;
      _errorMessage = '';
    });

    try {
      // Get services
      final eventService = Provider.of<EventService>(context, listen: false);
      final attendanceService = Provider.of<AttendanceService>(context, listen: false);

      // Step 1: Get all events the volunteer is registered for
      final allEvents = await eventService.getAllEvents();
      final registeredEvents = allEvents
          .where((event) => event.registeredParticipants.contains(volunteer.id))
          .toList();

      // Step 2: Get attendance records for the volunteer
      final attendanceRecords = await attendanceService.getVolunteerAttendance(volunteer.id);

      // Step 3: Calculate attendance percentage
      double percentage = 0.0;
      if (registeredEvents.isNotEmpty) {
        percentage = await attendanceService.calculateAttendancePercentage(
          volunteer.id,
          registeredEvents.map((e) => e.id).toList()
        );
      }

      // Count events attended
      final eventsAttended = attendanceRecords.where((record) => record.isPresent).length;

      if (mounted) {
        setState(() {
          _registeredEvents = registeredEvents;
          _attendanceRecords = attendanceRecords;
          _attendancePercentage = percentage;
          _eventsRegistered = registeredEvents.length;
          _eventsAttended = eventsAttended;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading volunteer stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          _errorMessage = 'Failed to load attendance data: ${e.toString()}';
        });
      }
    }
  }

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
          : RefreshIndicator(
              onRefresh: _loadVolunteerData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        const Text(
                          'Attendance Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (_isLoadingStats)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_errorMessage.isNotEmpty)
                          Center(
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadVolunteerData,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: [
                              // Attendance card with circular progress
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      // Attendance Percentage Circle
                                      Center(
                                        child: SizedBox(
                                          height: 150,
                                          width: 150,
                                          child: Stack(
                                            children: [
                                              Center(
                                                child: SizedBox(
                                                  height: 120,
                                                  width: 120,
                                                  child: CircularProgressIndicator(
                                                    value: _attendancePercentage / 100,
                                                    strokeWidth: 12,
                                                    backgroundColor: Colors.grey.shade300,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      _getAttendanceColor(_attendancePercentage),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '${_attendancePercentage.toStringAsFixed(1)}%',
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const Text(
                                                      'Attendance',
                                                      style: TextStyle(
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Attendance Status
                                      Center(
                                        child: Text(
                                          _getAttendanceStatus(_attendancePercentage),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _getAttendanceColor(_attendancePercentage),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Statistics Cards
                              Row(
                                children: [
                                  _buildStatCard(
                                    context,
                                    icon: Icons.event_available,
                                    value: _eventsRegistered.toString(),
                                    label: 'Events Registered',
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatCard(
                                    context,
                                    icon: Icons.check_circle,
                                    value: _eventsAttended.toString(),
                                    label: 'Events Attended',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                        const SizedBox(height: 24),
                        
                        // Recent Attendance History (if we have data)
                        if (!_isLoadingStats && _errorMessage.isEmpty && _registeredEvents.isNotEmpty) ...[
                          const Text(
                            'Recent Attendance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          ..._registeredEvents.take(3).map((event) {
                            final attendance = _attendanceRecords
                                .where((record) => record.eventId == event.id)
                                .toList();
                            final isPresent = attendance.isNotEmpty && attendance.first.isPresent;
                            
                            return _buildAttendanceHistoryItem(
                              context,
                              event: event,
                              isPresent: isPresent,
                              attendance: attendance.isNotEmpty ? attendance.first : null,
                            );
                          }).toList(),
                          
                          if (_registeredEvents.length > 3) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  // Navigate to detailed attendance history
                                  // Navigator.pushNamed(context, '/admin/volunteer-attendance-history', arguments: volunteer);
                                },
                                icon: const Icon(Icons.history),
                                label: const Text('View Full History'),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ],
                  ),
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
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
  
  Widget _buildAttendanceHistoryItem(
    BuildContext context, {
    required EventModel event,
    required bool isPresent,
    AttendanceModel? attendance,
  }) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPresent ? Colors.green : Colors.red,
          ),
          child: Icon(
            isPresent ? Icons.check : Icons.close,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          event.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: attendance != null
            ? Text('Marked on ${dateFormat.format(attendance.markedAt)}')
            : const Text('Not yet marked'),
        trailing: Text(
          isPresent ? 'Present' : attendance != null ? 'Absent' : 'Pending',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPresent ? Colors.green : attendance != null ? Colors.red : Colors.orange,
          ),
        ),
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
  
  String _getAttendanceStatus(double percentage) {
    if (percentage >= 75) {
      return 'Good Standing';
    } else if (percentage >= 60) {
      return 'Needs Improvement';
    } else {
      return 'Attendance Deficient';
    }
  }
}














// import 'package:flutter/material.dart';
// import 'package:nss_app/models/attendance_model.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:nss_app/services/volunteer_manage_service.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';

// class VolunteerDetailsScreen extends StatefulWidget {
//   const VolunteerDetailsScreen({Key? key}) : super(key: key);

//   @override
//   State<VolunteerDetailsScreen> createState() => _VolunteerDetailsScreenState();
// }

// class _VolunteerDetailsScreenState extends State<VolunteerDetailsScreen> {
//   bool _isLoading = false;

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

//       try {
//         final volunteerService = Provider.of<VolunteerManageService>(context, listen: false);
//         final success = await volunteerService.removeVolunteer(volunteer.volunteerId);
        
//         setState(() {
//           _isLoading = false;
//         });

//         if (!mounted) return;

//         if (success) {
//           // Show success message
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Volunteer removed successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );

//           // Go back to volunteer list
//           Navigator.pop(context);
//         } else {
//           // Show error message
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Failed to remove volunteer'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       } catch (e) {
//         setState(() {
//           _isLoading = false;
//         });
        
//         if (!mounted) return;
        
//         // Show error message
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
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

//     // Get events count the volunteer has participated in
//     final eventsParticipatedCount = volunteer.eventsParticipated.length;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Volunteer Details'),
//         actions: [
//           PopupMenuButton<String>(
//             onSelected: (value) {
//               if (value == 'remove') {
//                 _removeVolunteer(volunteer);
//               }
//             },
//             itemBuilder: (context) => [
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
//           : SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     // Profile Header
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         CircleAvatar(
//                           radius: 40,
//                           backgroundColor: Theme.of(context).primaryColor,
//                           child: Text(
//                             volunteer.name.isNotEmpty ? volunteer.name.substring(0, 1) : 'V',
//                             style: const TextStyle(
//                               fontSize: 32,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 volunteer.name,
//                                 style: const TextStyle(
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 'Volunteer ID: ${volunteer.volunteerId}',
//                                 style: const TextStyle(
//                                   color: Colors.black54,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 volunteer.email,
//                                 style: const TextStyle(
//                                   color: Colors.black54,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 'Status: ${volunteer.isApproved ? 'Approved' : 'Pending'}',
//                                 style: TextStyle(
//                                   color: volunteer.isApproved ? Colors.green : Colors.orange,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 24),

//                     // Volunteer Details
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade100,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Column(
//                         children: [
//                           _buildDetailRow('Department', volunteer.department),
//                           const Divider(),
//                           _buildDetailRow(
//                               'Blood Group', volunteer.bloodGroup),
//                           const Divider(),
//                           _buildDetailRow('Place', volunteer.place),
//                           const Divider(),
//                           _buildDetailRow(
//                             'Joined On',
//                             DateFormat('MMM dd, yyyy')
//                                 .format(volunteer.createdAt),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // Show attendance stats only for approved volunteers
//                     if (volunteer.isApproved) ...[
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
//                               value: eventsParticipatedCount.toString(),
//                               label: 'Events Participated',
//                               color: Theme.of(context).primaryColor,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//       bottomNavigationBar: volunteer.isApproved
//           ? Padding(
//               padding: const EdgeInsets.all(16),
//               child: CustomButton(
//                 text: 'Mark Attendance',
//                 onPressed: () {
//                   Navigator.pushNamed(context, '/admin/attendance-management');
//                 },
//               ),
//             )
//           : null,
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