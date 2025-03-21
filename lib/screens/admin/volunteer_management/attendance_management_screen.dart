import 'package:flutter/material.dart';
import 'package:nss_app/models/attendance_model.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:nss_app/utils/constants.dart';
import 'package:intl/intl.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  EventModel? _selectedEvent;
  bool _isLoading = false;
  final Map<String, bool> _attendanceStatus = {};
  final List<UserModel> _registeredVolunteers = [];
  
  @override
  void initState() {
    super.initState();
    // We'll load events in didChangeDependencies to ensure context is available
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEvents();
  }
  
  void _loadEvents() {
    // Check if we have an event passed as an argument
    final eventArg = ModalRoute.of(context)?.settings.arguments as EventModel?;
    if (eventArg != null) {
      _selectedEvent = eventArg;
      _loadVolunteers();
      return;
    }
    
    // Get all events
    final events = EventModel.getMockEvents();
    
    // Set the first event as selected by default (if any)
    if (events.isNotEmpty) {
      _selectedEvent = events.first;
      _loadVolunteers();
    }
  }
  
  void _loadVolunteers() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      if (_selectedEvent != null) {
        // Get all volunteers registered for this event
        final registeredVolunteerIds = _selectedEvent!.registeredParticipants;
        _registeredVolunteers.clear();
        
        for (final volunteerId in registeredVolunteerIds) {
          final volunteer = UserModel.getMockVolunteers()
              .firstWhere((v) => v.id == volunteerId, orElse: () => UserModel(
                id: '',
                name: 'Unknown Volunteer',
                email: '',
                volunteerId: '',
                bloodGroup: '',
                place: '',
                department: '',
                role: 'volunteer',
                createdAt: DateTime.now(),
              ));
          
          if (volunteer.id.isNotEmpty) {
            _registeredVolunteers.add(volunteer);
          }
        }
        
        // Initialize attendance status
        _attendanceStatus.clear();
        final attendances = AttendanceModel.getEventAttendance(_selectedEvent!.id);
        
        for (final volunteer in _registeredVolunteers) {
          final attendance = attendances
              .where((a) => a.volunteerId == volunteer.id)
              .toList();
          
          if (attendance.isNotEmpty) {
            _attendanceStatus[volunteer.id] = attendance.first.isPresent;
          } else {
            _attendanceStatus[volunteer.id] = false; // Default to absent
          }
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    });
  }
  
  void _saveAttendance() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.successAttendanceMarked),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: _registeredVolunteers.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _saveAttendance,
              icon: const Icon(Icons.save),
              label: const Text('Save Attendance'),
            )
          : null,
    );
  }
  
  Widget _buildBody() {
    if (_selectedEvent == null) {
      return const Center(
        child: Text('No events available for attendance marking'),
      );
    }
    
    // Get all events for the dropdown
    final events = EventModel.getMockEvents().toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event Selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Event',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedEvent!.id,
                  isExpanded: true,
                  underline: Container(),
                  hint: const Text('Select an event'),
                  items: events.map((event) {
                    return DropdownMenuItem<String>(
                      value: event.id,
                      child: Text(event.title),
                    );
                  }).toList(),
                  onChanged: (eventId) {
                    if (eventId != null) {
                      setState(() {
                        _selectedEvent = events.firstWhere((e) => e.id == eventId);
                      });
                      _loadVolunteers();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Event Details
        if (_selectedEvent != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedEvent!.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(DateFormat('MMM dd, yyyy').format(_selectedEvent!.startDate)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(_selectedEvent!.location),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('${_selectedEvent!.registeredParticipants.length} registered participants'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Attendance List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Participant Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_registeredVolunteers.isNotEmpty) 
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        for (final volunteer in _registeredVolunteers) {
                          _attendanceStatus[volunteer.id] = true;
                        }
                      });
                    },
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Mark All Present'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        if (_registeredVolunteers.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'No registered participants for this event',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _registeredVolunteers.length,
              itemBuilder: (context, index) {
                final volunteer = _registeredVolunteers[index];
                final isPresent = _attendanceStatus[volunteer.id] ?? false;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        volunteer.name.substring(0, 1),
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
                    subtitle: Text('ID: ${volunteer.volunteerId}'),
                    trailing: Switch(
                      value: isPresent,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setState(() {
                          _attendanceStatus[volunteer.id] = value;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}










// import 'package:flutter/material.dart';
// import 'package:nss_app/models/attendance_model.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:nss_app/utils/constants.dart';
// import 'package:intl/intl.dart';

// class AttendanceManagementScreen extends StatefulWidget {
//   const AttendanceManagementScreen({Key? key}) : super(key: key);

//   @override
//   State<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
// }

// class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
//   EventModel? _selectedEvent;
//   bool _isLoading = false;
//   final Map<String, bool> _attendanceStatus = {};
//   final List<UserModel> _approvedVolunteers = [];
  
//   @override
//   void initState() {
//     super.initState();
//     // We'll load events in didChangeDependencies to ensure context is available
//   }
  
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _loadEvents();
//   }
  
//   void _loadEvents() {
//     // Check if we have an event passed as an argument
//     final eventArg = ModalRoute.of(context)?.settings.arguments as EventModel?;
//     if (eventArg != null) {
//       _selectedEvent = eventArg;
//       _loadVolunteers();
//       return;
//     }
    
//     // Get all events
//     final events = EventModel.getMockEvents();
    
//     // Set the first event as selected by default (if any)
//     if (events.isNotEmpty) {
//       _selectedEvent = events.first;
//       _loadVolunteers();
//     }
//   }
  
//   void _loadVolunteers() {
//     setState(() {
//       _isLoading = true;
//     });
    
//     // Simulate API call
//     Future.delayed(const Duration(seconds: 1), () {
//       if (_selectedEvent != null) {
//         // Get all volunteers approved for this event
//         final approvedVolunteerIds = _selectedEvent!.approvedParticipants;
//         _approvedVolunteers.clear();
        
//         for (final volunteerId in approvedVolunteerIds) {
//           final volunteer = UserModel.getMockVolunteers()
//               .firstWhere((v) => v.id == volunteerId, orElse: () => UserModel(
//                 id: '',
//                 name: 'Unknown Volunteer',
//                 email: '',
//                 volunteerId: '',
//                 bloodGroup: '',
//                 place: '',
//                 department: '',
//                 role: 'volunteer',
//                 createdAt: DateTime.now(),
//               ));
          
//           if (volunteer.id.isNotEmpty) {
//             _approvedVolunteers.add(volunteer);
//           }
//         }
        
//         // Initialize attendance status
//         _attendanceStatus.clear();
//         final attendances = AttendanceModel.getEventAttendance(_selectedEvent!.id);
        
//         for (final volunteer in _approvedVolunteers) {
//           final attendance = attendances
//               .where((a) => a.volunteerId == volunteer.id)
//               .toList();
          
//           if (attendance.isNotEmpty) {
//             _attendanceStatus[volunteer.id] = attendance.first.isPresent;
//           } else {
//             _attendanceStatus[volunteer.id] = false; // Default to absent
//           }
//         }
//       }
      
//       setState(() {
//         _isLoading = false;
//       });
//     });
//   }
  
//   void _saveAttendance() {
//     setState(() {
//       _isLoading = true;
//     });
    
//     // Simulate API call
//     Future.delayed(const Duration(seconds: 2), () {
//       setState(() {
//         _isLoading = false;
//       });
      
//       if (!mounted) return;
      
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(AppConstants.successAttendanceMarked),
//           backgroundColor: Colors.green,
//         ),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Attendance Management'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _buildBody(),
//       floatingActionButton: _approvedVolunteers.isNotEmpty
//           ? FloatingActionButton.extended(
//               onPressed: _saveAttendance,
//               icon: const Icon(Icons.save),
//               label: const Text('Save Attendance'),
//             )
//           : null,
//     );
//   }
  
//   Widget _buildBody() {
//     if (_selectedEvent == null) {
//       return const Center(
//         child: Text('No events available for attendance marking'),
//       );
//     }
    
//     // Get all events for the dropdown
//     final events = EventModel.getMockEvents().toList();
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Event Selector
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Select Event',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: DropdownButton<String>(
//                   value: _selectedEvent!.id,
//                   isExpanded: true,
//                   underline: Container(),
//                   hint: const Text('Select an event'),
//                   items: events.map((event) {
//                     return DropdownMenuItem<String>(
//                       value: event.id,
//                       child: Text(event.title),
//                     );
//                   }).toList(),
//                   onChanged: (eventId) {
//                     if (eventId != null) {
//                       setState(() {
//                         _selectedEvent = events.firstWhere((e) => e.id == eventId);
//                       });
//                       _loadVolunteers();
//                     }
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
        
//         // Event Details
//         if (_selectedEvent != null)
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _selectedEvent!.title,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
//                         const SizedBox(width: 8),
//                         Text(DateFormat('MMM dd, yyyy').format(_selectedEvent!.startDate)),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         const Icon(Icons.location_on, size: 16, color: Colors.grey),
//                         const SizedBox(width: 8),
//                         Text(_selectedEvent!.location),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         const Icon(Icons.people, size: 16, color: Colors.grey),
//                         const SizedBox(width: 8),
//                         Text('${_selectedEvent!.approvedParticipants.length} approved participants'),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
        
//         const SizedBox(height: 16),
        
//         // Attendance List Header
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Column(
//             children: [
//               const Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Participant Attendance',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               if (_approvedVolunteers.isNotEmpty) 
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton.icon(
//                     onPressed: () {
//                       setState(() {
//                         for (final volunteer in _approvedVolunteers) {
//                           _attendanceStatus[volunteer.id] = true;
//                         }
//                       });
//                     },
//                     icon: const Icon(Icons.check_circle, size: 16),
//                     label: const Text('Mark All Present'),
//                     style: TextButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),
        
//         if (_approvedVolunteers.isEmpty)
//           const Expanded(
//             child: Center(
//               child: Text(
//                 'No approved participants for this event',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           )
//         else
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _approvedVolunteers.length,
//               itemBuilder: (context, index) {
//                 final volunteer = _approvedVolunteers[index];
//                 final isPresent = _attendanceStatus[volunteer.id] ?? false;
                
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 8),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: Theme.of(context).primaryColor,
//                       child: Text(
//                         volunteer.name.substring(0, 1),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     title: Text(
//                       volunteer.name,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     subtitle: Text('ID: ${volunteer.volunteerId}'),
//                     trailing: Switch(
//                       value: isPresent,
//                       activeColor: Colors.green,
//                       onChanged: (value) {
//                         setState(() {
//                           _attendanceStatus[volunteer.id] = value;
//                         });
//                       },
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//       ],
//     );
//   }
// }