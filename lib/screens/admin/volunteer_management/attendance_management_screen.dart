import 'package:flutter/material.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:nss_app/services/attendance_service.dart';
import 'package:nss_app/services/event_service.dart';
import 'package:nss_app/services/auth_service.dart';
import 'package:nss_app/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  // Variables to track loading state and data
  bool _isLoadingEvents = true;
  bool _isLoadingVolunteers = false;
  bool _isSaving = false;
  
  // Main data
  List<EventModel> _events = [];
  String? _selectedEventId;
  List<UserModel> _registeredVolunteers = [];
  Map<String, bool> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    // Delay loading events to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }
  
  // Step 1: Load available events
  Future<void> _loadEvents() async {
    setState(() {
      _isLoadingEvents = true;
    });
    
    try {
      final eventService = Provider.of<EventService>(context, listen: false);
      final eventList = await eventService.getAllEvents();
      
      setState(() {
        _events = eventList;
        _isLoadingEvents = false;
      });
      
      // Check if an event was passed as argument
      final eventArg = ModalRoute.of(context)?.settings.arguments as EventModel?;
      if (eventArg != null) {
        // Select this event and load its volunteers
        _selectEvent(eventArg.id);
      }
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _isLoadingEvents = false;
        _events = [];
      });
    }
  }
  
  // Step 2: Select an event and load its volunteers
  void _selectEvent(String eventId) {
    // Update selected event ID
    setState(() {
      _selectedEventId = eventId;
      _isLoadingVolunteers = true;
      _registeredVolunteers = []; // Clear previous data
      _attendanceStatus = {};
    });
    
    // Load volunteers after state update is complete
    _loadVolunteers(eventId);
  }
  
  // Step 3: Load volunteers for selected event
  Future<void> _loadVolunteers(String eventId) async {
    try {
      // Find the selected event
      final event = _events.firstWhere((e) => e.id == eventId);
      final eventService = Provider.of<EventService>(context, listen: false);
      final attendanceService = Provider.of<AttendanceService>(context, listen: false);
      
      // Get registered volunteers
      final volunteers = await eventService.getRegisteredUsers(event);
      
      // Get existing attendance records from Firestore
      final attendanceData = await attendanceService.getEventAttendance(eventId);
      
      // Initialize attendance status
      Map<String, bool> newAttendanceStatus = {};
      
      for (final volunteer in volunteers) {
        // Use existing attendance data if available, otherwise default to false
        newAttendanceStatus[volunteer.id] = attendanceData[volunteer.id] ?? false;
      }
      
      // Only update if still on the same event
      if (mounted && _selectedEventId == eventId) {
        setState(() {
          _registeredVolunteers = volunteers;
          _attendanceStatus = newAttendanceStatus;
          _isLoadingVolunteers = false;
        });
      }
    } catch (e) {
      print('Error loading volunteers: $e');
      if (mounted && _selectedEventId == eventId) {
        setState(() {
          _registeredVolunteers = [];
          _attendanceStatus = {};
          _isLoadingVolunteers = false;
        });
      }
    }
  }
  
  // Toggle attendance for all participants
  void _toggleAllAttendance() {
    // Check if all are already present
    bool allPresent = true;
    
    // Check if all volunteers are marked present
    for (final volunteer in _registeredVolunteers) {
      if (_attendanceStatus[volunteer.id] != true) {
        allPresent = false;
        break;
      }
    }
    
    // If all are present, mark all absent, otherwise mark all present
    final newAttendance = Map<String, bool>.from(_attendanceStatus);
    for (final volunteer in _registeredVolunteers) {
      newAttendance[volunteer.id] = !allPresent;
    }
    
    setState(() {
      _attendanceStatus = newAttendance;
    });
  }
  
  // Save attendance to Firestore
  Future<void> _saveAttendance() async {
    if (_selectedEventId == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Get current admin user
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final attendanceService = Provider.of<AttendanceService>(context, listen: false);
      
      // Save attendance data to Firestore using batch write
      await attendanceService.markBulkAttendance(
        eventId: _selectedEventId!,
        attendanceStatus: _attendanceStatus,
        adminId: currentUser.uid,
        adminName: currentUser.displayName ?? 'Admin',
      );
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.successAttendanceMarked),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving attendance: $e');
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
      ),
      body: _isLoadingEvents
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: (_selectedEventId != null && _registeredVolunteers.isNotEmpty && !_isSaving)
          ? FloatingActionButton.extended(
              onPressed: _saveAttendance,
              icon: const Icon(Icons.save),
              label: const Text('Save Attendance'),
            )
          : _isSaving
              ? const FloatingActionButton.extended(
                  onPressed: null,
                  icon: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  label: Text('Saving...'),
                )
              : null,
    );
  }
  
  Widget _buildContent() {
    if (_events.isEmpty) {
      return const Center(
        child: Text('No events available for attendance marking'),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Selector - Always visible
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Event',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedEventId,
                  isExpanded: true,
                  underline: Container(),
                  hint: const Text('Select an event'),
                  items: _events.map((event) {
                    // Format with date as requested
                    final eventDate = DateFormat('dd/MM/yy').format(event.startDate);
                    return DropdownMenuItem<String>(
                      value: event.id,
                      child: Text('${event.title} - $eventDate'),
                    );
                  }).toList(),
                  onChanged: (eventId) {
                    if (eventId != null) {
                      _selectEvent(eventId);
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Show loading indicator when loading volunteers
          if (_isLoadingVolunteers)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          // Show selected event details when an event is selected
          else if (_selectedEventId != null) ...[
            // Event Details Card
            _buildEventDetailsCard(),
            
            const SizedBox(height: 24),
            
            // Participant Attendance
            _buildParticipantAttendance(),
          ]
          // Show message if no event is selected
          else
            const Expanded(
              child: Center(
                child: Text(
                  'Please select an event to view attendance',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildEventDetailsCard() {
    // Get the selected event
    final selectedEvent = _events.firstWhere((e) => e.id == _selectedEventId);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedEvent.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(DateFormat('MMM dd, yyyy').format(selectedEvent.startDate)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(selectedEvent.location),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${selectedEvent.registeredParticipants.length} registered participants'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Build the toggle button
  Widget _buildToggleButton() {
    // Check if all volunteers are already marked present
    bool allPresent = true;
    
    // Check if all volunteers are marked present
    for (final volunteer in _registeredVolunteers) {
      if (_attendanceStatus[volunteer.id] != true) {
        allPresent = false;
        break;
      }
    }
    
    return TextButton.icon(
      onPressed: _toggleAllAttendance,
      icon: Icon(
        allPresent ? Icons.cancel : Icons.check_circle, 
        size: 16,
        color: allPresent ? Colors.red : Colors.blue,
      ),
      label: Text(
        allPresent ? 'Mark All Absent' : 'Mark All Present',
        style: TextStyle(
          color: allPresent ? Colors.red : Colors.blue,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
  
  Widget _buildParticipantAttendance() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Participant Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_registeredVolunteers.isNotEmpty) _buildToggleButton(),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // List
          Expanded(
            child: _registeredVolunteers.isEmpty
              ? const Center(
                  child: Text(
                    'No registered participants for this event',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
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
                            volunteer.name.isNotEmpty ? volunteer.name.substring(0, 1) : '?',
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
      ),
    );
  }
}













// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:nss_app/services/attendance_service.dart';
// import 'package:nss_app/services/event_service.dart';
// import 'package:nss_app/services/auth_service.dart';
// import 'package:nss_app/utils/constants.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';

// class AttendanceManagementScreen extends StatefulWidget {
//   const AttendanceManagementScreen({Key? key}) : super(key: key);

//   @override
//   State<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
// }

// class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
//   // Variables to track loading state and data
//   bool _isLoadingEvents = true;
//   bool _isLoadingVolunteers = false;
//   bool _isSaving = false;
  
//   // Main data
//   List<EventModel> _events = [];
//   String? _selectedEventId;
//   List<UserModel> _registeredVolunteers = [];
//   Map<String, bool> _attendanceStatus = {};

//   @override
//   void initState() {
//     super.initState();
//     // Delay loading events to ensure context is available
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadEvents();
//     });
//   }
  
//   // Step 1: Load available events
//   Future<void> _loadEvents() async {
//     setState(() {
//       _isLoadingEvents = true;
//     });
    
//     try {
//       final eventService = Provider.of<EventService>(context, listen: false);
//       final eventList = await eventService.getAllEvents();
      
//       setState(() {
//         _events = eventList;
//         _isLoadingEvents = false;
//       });
      
//       // Check if an event was passed as argument
//       final eventArg = ModalRoute.of(context)?.settings.arguments as EventModel?;
//       if (eventArg != null) {
//         // Select this event and load its volunteers
//         _selectEvent(eventArg.id);
//       }
//     } catch (e) {
//       print('Error loading events: $e');
//       setState(() {
//         _isLoadingEvents = false;
//         _events = [];
//       });
//     }
//   }
  
//   // Step 2: Select an event and load its volunteers
//   void _selectEvent(String eventId) {
//     // Update selected event ID
//     setState(() {
//       _selectedEventId = eventId;
//       _isLoadingVolunteers = true;
//       _registeredVolunteers = []; // Clear previous data
//       _attendanceStatus = {};
//     });
    
//     // Load volunteers after state update is complete
//     _loadVolunteers(eventId);
//   }
  
//   // Step 3: Load volunteers for selected event
//   Future<void> _loadVolunteers(String eventId) async {
//     try {
//       // Find the selected event
//       final event = _events.firstWhere((e) => e.id == eventId);
//       final eventService = Provider.of<EventService>(context, listen: false);
//       final attendanceService = Provider.of<AttendanceService>(context, listen: false);
      
//       // Get registered volunteers
//       final volunteers = await eventService.getRegisteredUsers(event);
      
//       // Get existing attendance records from Firestore
//       final attendanceData = await attendanceService.getEventAttendance(eventId);
      
//       // Initialize attendance status
//       Map<String, bool> newAttendanceStatus = {};
      
//       for (final volunteer in volunteers) {
//         // Use existing attendance data if available, otherwise default to false
//         newAttendanceStatus[volunteer.id] = attendanceData[volunteer.id] ?? false;
//       }
      
//       // Only update if still on the same event
//       if (mounted && _selectedEventId == eventId) {
//         setState(() {
//           _registeredVolunteers = volunteers;
//           _attendanceStatus = newAttendanceStatus;
//           _isLoadingVolunteers = false;
//         });
//       }
//     } catch (e) {
//       print('Error loading volunteers: $e');
//       if (mounted && _selectedEventId == eventId) {
//         setState(() {
//           _registeredVolunteers = [];
//           _attendanceStatus = {};
//           _isLoadingVolunteers = false;
//         });
//       }
//     }
//   }
  
//   // Mark all present
//   void _markAllPresent() {
//     final newAttendance = Map<String, bool>.from(_attendanceStatus);
//     for (final volunteer in _registeredVolunteers) {
//       newAttendance[volunteer.id] = true;
//     }
    
//     setState(() {
//       _attendanceStatus = newAttendance;
//     });
//   }
  
//   // Save attendance to Firestore
//   Future<void> _saveAttendance() async {
//     if (_selectedEventId == null) return;
    
//     setState(() {
//       _isSaving = true;
//     });
    
//     try {
//       // Get current admin user
//       final authService = Provider.of<AuthService>(context, listen: false);
//       final currentUser = authService.currentUser;
      
//       if (currentUser == null) {
//         throw Exception('User not authenticated');
//       }
      
//       final attendanceService = Provider.of<AttendanceService>(context, listen: false);
      
//       // Save attendance data to Firestore using batch write
//       await attendanceService.markBulkAttendance(
//         eventId: _selectedEventId!,
//         attendanceStatus: _attendanceStatus,
//         adminId: currentUser.uid,
//         adminName: currentUser.displayName ?? 'Admin',
//       );
      
//       if (mounted) {
//         setState(() {
//           _isSaving = false;
//         });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(AppConstants.successAttendanceMarked),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       print('Error saving attendance: $e');
      
//       if (mounted) {
//         setState(() {
//           _isSaving = false;
//         });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to save attendance: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Attendance Management'),
//       ),
//       body: _isLoadingEvents
//           ? const Center(child: CircularProgressIndicator())
//           : _buildContent(),
//       floatingActionButton: (_selectedEventId != null && _registeredVolunteers.isNotEmpty && !_isSaving)
//           ? FloatingActionButton.extended(
//               onPressed: _saveAttendance,
//               icon: const Icon(Icons.save),
//               label: const Text('Save Attendance'),
//             )
//           : _isSaving
//               ? const FloatingActionButton.extended(
//                   onPressed: null,
//                   icon: SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   ),
//                   label: Text('Saving...'),
//                 )
//               : null,
//     );
//   }
  
//   Widget _buildContent() {
//     if (_events.isEmpty) {
//       return const Center(
//         child: Text('No events available for attendance marking'),
//       );
//     }
    
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Event Selector - Always visible
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Select Event',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: DropdownButton<String>(
//                   value: _selectedEventId,
//                   isExpanded: true,
//                   underline: Container(),
//                   hint: const Text('Select an event'),
//                   items: _events.map((event) {
//                     // Format with date as requested
//                     final eventDate = DateFormat('dd/MM/yy').format(event.startDate);
//                     return DropdownMenuItem<String>(
//                       value: event.id,
//                       child: Text('${event.title} - $eventDate'),
//                     );
//                   }).toList(),
//                   onChanged: (eventId) {
//                     if (eventId != null) {
//                       _selectEvent(eventId);
//                     }
//                   },
//                 ),
//               ),
//             ],
//           ),
          
//           const SizedBox(height: 24),
          
//           // Show loading indicator when loading volunteers
//           if (_isLoadingVolunteers)
//             const Expanded(
//               child: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             )
//           // Show selected event details when an event is selected
//           else if (_selectedEventId != null) ...[
//             // Event Details Card
//             _buildEventDetailsCard(),
            
//             const SizedBox(height: 24),
            
//             // Participant Attendance
//             _buildParticipantAttendance(),
//           ]
//           // Show message if no event is selected
//           else
//             const Expanded(
//               child: Center(
//                 child: Text(
//                   'Please select an event to view attendance',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildEventDetailsCard() {
//     // Get the selected event
//     final selectedEvent = _events.firstWhere((e) => e.id == _selectedEventId);
    
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               selectedEvent.title,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Text(DateFormat('MMM dd, yyyy').format(selectedEvent.startDate)),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 const Icon(Icons.location_on, size: 16, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Text(selectedEvent.location),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 const Icon(Icons.people, size: 16, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Text('${selectedEvent.registeredParticipants.length} registered participants'),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildParticipantAttendance() {
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Participant Attendance',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               if (_registeredVolunteers.isNotEmpty)
//                 TextButton.icon(
//                   onPressed: _markAllPresent,
//                   icon: const Icon(Icons.check_circle, size: 16),
//                   label: const Text('Mark All Present'),
//                   style: TextButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   ),
//                 ),
//             ],
//           ),
          
//           const SizedBox(height: 12),
          
//           // List
//           Expanded(
//             child: _registeredVolunteers.isEmpty
//               ? const Center(
//                   child: Text(
//                     'No registered participants for this event',
//                     style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 16,
//                     ),
//                   ),
//                 )
//               : ListView.builder(
//                   itemCount: _registeredVolunteers.length,
//                   itemBuilder: (context, index) {
//                     final volunteer = _registeredVolunteers[index];
//                     final isPresent = _attendanceStatus[volunteer.id] ?? false;
                    
//                     return Card(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: Theme.of(context).primaryColor,
//                           child: Text(
//                             volunteer.name.isNotEmpty ? volunteer.name.substring(0, 1) : '?',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         title: Text(
//                           volunteer.name,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         subtitle: Text('ID: ${volunteer.volunteerId}'),
//                         trailing: Switch(
//                           value: isPresent,
//                           activeColor: Colors.green,
//                           onChanged: (value) {
//                             setState(() {
//                               _attendanceStatus[volunteer.id] = value;
//                             });
//                           },
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//           ),
//         ],
//       ),
//     );
//   }
// }











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
//   final List<UserModel> _registeredVolunteers = [];
  
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
//         // Get all volunteers registered for this event
//         final registeredVolunteerIds = _selectedEvent!.registeredParticipants;
//         _registeredVolunteers.clear();
        
//         for (final volunteerId in registeredVolunteerIds) {
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
//             _registeredVolunteers.add(volunteer);
//           }
//         }
        
//         // Initialize attendance status
//         _attendanceStatus.clear();
//         final attendances = AttendanceModel.getEventAttendance(_selectedEvent!.id);
        
//         for (final volunteer in _registeredVolunteers) {
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
//       floatingActionButton: _registeredVolunteers.isNotEmpty
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
//                         Text('${_selectedEvent!.registeredParticipants.length} registered participants'),
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
//               if (_registeredVolunteers.isNotEmpty) 
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton.icon(
//                     onPressed: () {
//                       setState(() {
//                         for (final volunteer in _registeredVolunteers) {
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
        
//         if (_registeredVolunteers.isEmpty)
//           const Expanded(
//             child: Center(
//               child: Text(
//                 'No registered participants for this event',
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
//               itemCount: _registeredVolunteers.length,
//               itemBuilder: (context, index) {
//                 final volunteer = _registeredVolunteers[index];
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