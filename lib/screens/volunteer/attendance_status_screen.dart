import 'package:flutter/material.dart';
import 'package:nss_app/models/attendance_model.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nss_app/services/profile_service.dart';
import 'package:nss_app/services/event_service.dart';
import 'package:nss_app/services/attendance_service.dart';

class AttendanceStatusScreen extends StatefulWidget {
  const AttendanceStatusScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceStatusScreen> createState() => _AttendanceStatusScreenState();
}

class _AttendanceStatusScreenState extends State<AttendanceStatusScreen> {
  UserModel? _currentUser;
  List<EventModel> _registeredEvents = [];
  List<AttendanceModel> _attendanceRecords = [];
  double _attendancePercentage = 0.0;
  bool _isLoading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }
  
  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Step 1: Get current user profile
      final profileService = Provider.of<ProfileService>(context, listen: false);
      final user = await profileService.getCurrentUserProfile();
      
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not retrieve user profile';
        });
        return;
      }
      
      // Step 2: Get all events the user is registered for
      final eventService = Provider.of<EventService>(context, listen: false);
      final allEvents = await eventService.getAllEvents();
      
      final registeredEvents = allEvents
          .where((event) => event.registeredParticipants.contains(user.id))
          .toList();
      
      // Step 3: Get attendance records for the user
      final attendanceService = Provider.of<AttendanceService>(context, listen: false);
      final attendanceRecords = await attendanceService.getVolunteerAttendance(user.id);
      
      // Step 4: Calculate attendance percentage
      double percentage = 0.0;
      if (registeredEvents.isNotEmpty) {
        percentage = await attendanceService.calculateAttendancePercentage(
          user.id, 
          registeredEvents.map((e) => e.id).toList()
        );
      }
      
      // Update state with real data
      if (mounted) {
        setState(() {
          _currentUser = user;
          _registeredEvents = registeredEvents;
          _attendanceRecords = attendanceRecords;
          _attendancePercentage = percentage;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading attendance data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load attendance data: ${e.toString()}';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Status'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadAttendanceData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Status'),
        ),
        body: const Center(
          child: Text('Unable to load user profile. Please try again later.'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Status'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAttendanceData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attendance Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Attendance Percentage Circle - Now centered
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
                      
                      // Attendance Status - Also centered
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
                      const SizedBox(height: 8),
                      // Minimum required text - Centered
                      // const Center(
                      //   child: Text(
                      //     'Minimum required attendance is 75%',
                      //     style: TextStyle(
                      //       color: Colors.black54,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Statistics
              Row(
                children: [
                  _buildStatCard(
                    context,
                    icon: Icons.event_available,
                    value: _registeredEvents.length.toString(),
                    label: 'Events Registered',
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    context,
                    icon: Icons.check_circle,
                    value: _attendanceRecords.where((record) => record.isPresent).length.toString(),
                    label: 'Events Attended',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Attendance History
              const Text(
                'Attendance History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              if (_registeredEvents.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Text(
                      'No events attended yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                ..._registeredEvents.map((event) {
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
            ],
          ),
        ),
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
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:intl/intl.dart';

// class AttendanceStatusScreen extends StatefulWidget {
//   const AttendanceStatusScreen({Key? key}) : super(key: key);

//   @override
//   State<AttendanceStatusScreen> createState() => _AttendanceStatusScreenState();
// }

// class _AttendanceStatusScreenState extends State<AttendanceStatusScreen> {
//   // Mock user for UI development
//   final UserModel _currentUser = UserModel.getMockVolunteers().first;
//   bool _isLoading = false;
  
//   @override
//   void initState() {
//     super.initState();
//     _loadAttendance();
//   }
  
//   void _loadAttendance() {
//     setState(() {
//       _isLoading = true;
//     });
    
//     // Simulate API call
//     Future.delayed(const Duration(seconds: 1), () {
//       setState(() {
//         _isLoading = false;
//       });
//     });
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
    
//     // Get attendance percentage
//     final attendancePercentage = AttendanceModel.calculateAttendancePercentage(_currentUser.id);
    
//     // Get all events the volunteer registered for
//     final registeredEvents = EventModel.getMockEvents()
//         .where((event) => event.registeredParticipants.contains(_currentUser.id))
//         .toList();
    
//     // Get all attendance records for the volunteer
//     final attendanceRecords = AttendanceModel.getVolunteerAttendance(_currentUser.id);
    
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Attendance Status'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Attendance Summary Card
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     // Attendance Percentage Circle
//                     SizedBox(
//                       height: 150,
//                       width: 150,
//                       child: Stack(
//                         children: [
//                           Center(
//                             child: SizedBox(
//                               height: 120,
//                               width: 120,
//                               child: CircularProgressIndicator(
//                                 value: attendancePercentage / 100,
//                                 strokeWidth: 12,
//                                 backgroundColor: Colors.grey.shade300,
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   _getAttendanceColor(attendancePercentage),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   '${attendancePercentage.toStringAsFixed(1)}%',
//                                   style: const TextStyle(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const Text(
//                                   'Attendance',
//                                   style: TextStyle(
//                                     color: Colors.black54,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
                    
//                     // Attendance Status
//                     Text(
//                       _getAttendanceStatus(attendancePercentage),
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: _getAttendanceColor(attendancePercentage),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'Minimum required attendance is 75%',
//                       style: TextStyle(
//                         color: Colors.black54,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
            
//             // Statistics
//             Row(
//               children: [
//                 _buildStatCard(
//                   context,
//                   icon: Icons.event_available,
//                   value: registeredEvents.length.toString(),
//                   label: 'Events Registered',
//                 ),
//                 const SizedBox(width: 16),
//                 _buildStatCard(
//                   context,
//                   icon: Icons.check_circle,
//                   value: attendanceRecords.where((record) => record.isPresent).length.toString(),
//                   label: 'Events Attended',
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
            
//             // Attendance History
//             const Text(
//               'Attendance History',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             if (registeredEvents.isEmpty)
//               const Center(
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(vertical: 32.0),
//                   child: Text(
//                     'No events attended yet',
//                     style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               )
//             else
//               ...registeredEvents.map((event) {
//                 final attendance = attendanceRecords
//                     .where((record) => record.eventId == event.id)
//                     .toList();
//                 final isPresent = attendance.isNotEmpty && attendance.first.isPresent;
                
//                 return _buildAttendanceHistoryItem(
//                   context,
//                   event: event,
//                   isPresent: isPresent,
//                   attendance: attendance.isNotEmpty ? attendance.first : null,
//                 );
//               }).toList(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatCard(
//     BuildContext context, {
//     required IconData icon,
//     required String value,
//     required String label,
//   }) {
//     return Expanded(
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               Icon(
//                 icon,
//                 size: 32,
//                 color: Theme.of(context).primaryColor,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   color: Colors.black54,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAttendanceHistoryItem(
//     BuildContext context, {
//     required EventModel event,
//     required bool isPresent,
//     AttendanceModel? attendance,
//   }) {
//     final dateFormat = DateFormat('MMM dd, yyyy');
    
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: isPresent ? Colors.green : Colors.red,
//           ),
//           child: Icon(
//             isPresent ? Icons.check : Icons.close,
//             color: Colors.white,
//             size: 20,
//           ),
//         ),
//         title: Text(
//           event.title,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         subtitle: attendance != null
//             ? Text('Marked on ${dateFormat.format(attendance.markedAt)}')
//             : const Text('Not yet marked'),
//         trailing: Text(
//           isPresent ? 'Present' : attendance != null ? 'Absent' : 'Pending',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: isPresent ? Colors.green : attendance != null ? Colors.red : Colors.orange,
//           ),
//         ),
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

//   String _getAttendanceStatus(double percentage) {
//     if (percentage >= 75) {
//       return 'Good Standing';
//     } else if (percentage >= 60) {
//       return 'Needs Improvement';
//     } else {
//       return 'Attendance Deficient';
//     }
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:nss_app/models/attendance_model.dart';
// // import 'package:nss_app/models/event_model.dart';
// // import 'package:nss_app/models/user_model.dart';
// // import 'package:intl/intl.dart';

// // class AttendanceStatusScreen extends StatefulWidget {
// //   const AttendanceStatusScreen({Key? key}) : super(key: key);

// //   @override
// //   State<AttendanceStatusScreen> createState() => _AttendanceStatusScreenState();
// // }

// // class _AttendanceStatusScreenState extends State<AttendanceStatusScreen> {
// //   // Mock user for UI development
// //   final UserModel _currentUser = UserModel.getMockVolunteers().first;
// //   bool _isLoading = false;
  
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadAttendance();
// //   }
  
// //   void _loadAttendance() {
// //     setState(() {
// //       _isLoading = true;
// //     });
    
// //     // Simulate API call
// //     Future.delayed(const Duration(seconds: 1), () {
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     });
// //   }
  
// //   @override
// //   Widget build(BuildContext context) {
// //     if (_isLoading) {
// //       return const Scaffold(
// //         body: Center(child: CircularProgressIndicator()),
// //       );
// //     }
    
// //     // Get attendance percentage
// //     final attendancePercentage = AttendanceModel.calculateAttendancePercentage(_currentUser.id);
    
// //     // Get all events the volunteer was approved for
// //     final approvedEvents = EventModel.getMockEvents()
// //         .where((event) => event.approvedParticipants.contains(_currentUser.id))
// //         .toList();
    
// //     // Get all attendance records for the volunteer
// //     final attendanceRecords = AttendanceModel.getVolunteerAttendance(_currentUser.id);
    
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Attendance Status'),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // Attendance Summary Card
// //             Card(
// //               child: Padding(
// //                 padding: const EdgeInsets.all(16),
// //                 child: Column(
// //                   children: [
// //                     // Attendance Percentage Circle
// //                     SizedBox(
// //                       height: 150,
// //                       width: 150,
// //                       child: Stack(
// //                         children: [
// //                           Center(
// //                             child: SizedBox(
// //                               height: 120,
// //                               width: 120,
// //                               child: CircularProgressIndicator(
// //                                 value: attendancePercentage / 100,
// //                                 strokeWidth: 12,
// //                                 backgroundColor: Colors.grey.shade300,
// //                                 valueColor: AlwaysStoppedAnimation<Color>(
// //                                   _getAttendanceColor(attendancePercentage),
// //                                 ),
// //                               ),
// //                             ),
// //                           ),
// //                           Center(
// //                             child: Column(
// //                               mainAxisAlignment: MainAxisAlignment.center,
// //                               children: [
// //                                 Text(
// //                                   '${attendancePercentage.toStringAsFixed(1)}%',
// //                                   style: const TextStyle(
// //                                     fontSize: 24,
// //                                     fontWeight: FontWeight.bold,
// //                                   ),
// //                                 ),
// //                                 const Text(
// //                                   'Attendance',
// //                                   style: TextStyle(
// //                                     color: Colors.black54,
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                     const SizedBox(height: 16),
                    
// //                     // Attendance Status
// //                     Text(
// //                       _getAttendanceStatus(attendancePercentage),
// //                       style: TextStyle(
// //                         fontSize: 18,
// //                         fontWeight: FontWeight.bold,
// //                         color: _getAttendanceColor(attendancePercentage),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 8),
// //                     const Text(
// //                       'Minimum required attendance is 75%',
// //                       style: TextStyle(
// //                         color: Colors.black54,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //             const SizedBox(height: 24),
            
// //             // Statistics
// //             Row(
// //               children: [
// //                 _buildStatCard(
// //                   context,
// //                   icon: Icons.event_available,
// //                   value: approvedEvents.length.toString(),
// //                   label: 'Events Registered',
// //                 ),
// //                 const SizedBox(width: 16),
// //                 _buildStatCard(
// //                   context,
// //                   icon: Icons.check_circle,
// //                   value: attendanceRecords.where((record) => record.isPresent).length.toString(),
// //                   label: 'Events Attended',
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 24),
            
// //             // Attendance History
// //             const Text(
// //               'Attendance History',
// //               style: TextStyle(
// //                 fontSize: 18,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             const SizedBox(height: 16),
            
// //             if (approvedEvents.isEmpty)
// //               const Center(
// //                 child: Padding(
// //                   padding: EdgeInsets.symmetric(vertical: 32.0),
// //                   child: Text(
// //                     'No events attended yet',
// //                     style: TextStyle(
// //                       color: Colors.grey,
// //                       fontSize: 16,
// //                     ),
// //                   ),
// //                 ),
// //               )
// //             else
// //               ...approvedEvents.map((event) {
// //                 final attendance = attendanceRecords
// //                     .where((record) => record.eventId == event.id)
// //                     .toList();
// //                 final isPresent = attendance.isNotEmpty && attendance.first.isPresent;
                
// //                 return _buildAttendanceHistoryItem(
// //                   context,
// //                   event: event,
// //                   isPresent: isPresent,
// //                   attendance: attendance.isNotEmpty ? attendance.first : null,
// //                 );
// //               }).toList(),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildStatCard(
// //     BuildContext context, {
// //     required IconData icon,
// //     required String value,
// //     required String label,
// //   }) {
// //     return Expanded(
// //       child: Card(
// //         child: Padding(
// //           padding: const EdgeInsets.all(16),
// //           child: Column(
// //             children: [
// //               Icon(
// //                 icon,
// //                 size: 32,
// //                 color: Theme.of(context).primaryColor,
// //               ),
// //               const SizedBox(height: 8),
// //               Text(
// //                 value,
// //                 style: const TextStyle(
// //                   fontSize: 24,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               const SizedBox(height: 4),
// //               Text(
// //                 label,
// //                 style: const TextStyle(
// //                   color: Colors.black54,
// //                 ),
// //                 textAlign: TextAlign.center,
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildAttendanceHistoryItem(
// //     BuildContext context, {
// //     required EventModel event,
// //     required bool isPresent,
// //     AttendanceModel? attendance,
// //   }) {
// //     final dateFormat = DateFormat('MMM dd, yyyy');
    
// //     return Card(
// //       margin: const EdgeInsets.only(bottom: 12),
// //       child: ListTile(
// //         leading: Container(
// //           padding: const EdgeInsets.all(8),
// //           decoration: BoxDecoration(
// //             shape: BoxShape.circle,
// //             color: isPresent ? Colors.green : Colors.red,
// //           ),
// //           child: Icon(
// //             isPresent ? Icons.check : Icons.close,
// //             color: Colors.white,
// //             size: 20,
// //           ),
// //         ),
// //         title: Text(
// //           event.title,
// //           style: const TextStyle(
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         subtitle: attendance != null
// //             ? Text('Marked on ${dateFormat.format(attendance.markedAt)}')
// //             : const Text('Not yet marked'),
// //         trailing: Text(
// //           isPresent ? 'Present' : attendance != null ? 'Absent' : 'Pending',
// //           style: TextStyle(
// //             fontWeight: FontWeight.bold,
// //             color: isPresent ? Colors.green : attendance != null ? Colors.red : Colors.orange,
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Color _getAttendanceColor(double percentage) {
// //     if (percentage >= 75) {
// //       return Colors.green;
// //     } else if (percentage >= 60) {
// //       return Colors.orange;
// //     } else {
// //       return Colors.red;
// //     }
// //   }

// //   String _getAttendanceStatus(double percentage) {
// //     if (percentage >= 75) {
// //       return 'Good Standing';
// //     } else if (percentage >= 60) {
// //       return 'Needs Improvement';
// //     } else {
// //       return 'Attendance Deficient';
// //     }
// //   }
// // }