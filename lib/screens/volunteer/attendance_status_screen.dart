import 'package:flutter/material.dart';
import 'package:nss_app/models/attendance_model.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:intl/intl.dart';

class AttendanceStatusScreen extends StatefulWidget {
  const AttendanceStatusScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceStatusScreen> createState() => _AttendanceStatusScreenState();
}

class _AttendanceStatusScreenState extends State<AttendanceStatusScreen> {
  // Mock user for UI development
  final UserModel _currentUser = UserModel.getMockVolunteers().first;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }
  
  void _loadAttendance() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Get attendance percentage
    final attendancePercentage = AttendanceModel.calculateAttendancePercentage(_currentUser.id);
    
    // Get all events the volunteer registered for
    final registeredEvents = EventModel.getMockEvents()
        .where((event) => event.registeredParticipants.contains(_currentUser.id))
        .toList();
    
    // Get all attendance records for the volunteer
    final attendanceRecords = AttendanceModel.getVolunteerAttendance(_currentUser.id);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Status'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attendance Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Attendance Percentage Circle
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: Stack(
                        children: [
                          Center(
                            child: SizedBox(
                              height: 120,
                              width: 120,
                              child: CircularProgressIndicator(
                                value: attendancePercentage / 100,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getAttendanceColor(attendancePercentage),
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${attendancePercentage.toStringAsFixed(1)}%',
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
                    const SizedBox(height: 16),
                    
                    // Attendance Status
                    Text(
                      _getAttendanceStatus(attendancePercentage),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getAttendanceColor(attendancePercentage),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Minimum required attendance is 75%',
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
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
                  value: registeredEvents.length.toString(),
                  label: 'Events Registered',
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  icon: Icons.check_circle,
                  value: attendanceRecords.where((record) => record.isPresent).length.toString(),
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
            
            if (registeredEvents.isEmpty)
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
              ...registeredEvents.map((event) {
                final attendance = attendanceRecords
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
    
//     // Get all events the volunteer was approved for
//     final approvedEvents = EventModel.getMockEvents()
//         .where((event) => event.approvedParticipants.contains(_currentUser.id))
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
//                   value: approvedEvents.length.toString(),
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
            
//             if (approvedEvents.isEmpty)
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
//               ...approvedEvents.map((event) {
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