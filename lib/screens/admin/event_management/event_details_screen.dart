import 'package:flutter/material.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:nss_app/utils/constants.dart';
import 'package:nss_app/widgets/common/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nss_app/services/event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEventDetailsScreen extends StatefulWidget {
  const AdminEventDetailsScreen({Key? key}) : super(key: key);

  @override
  State<AdminEventDetailsScreen> createState() => _AdminEventDetailsScreenState();
}

class _AdminEventDetailsScreenState extends State<AdminEventDetailsScreen> {
  bool _isLoading = false;
  
  // Lists to store real data from Firebase
  List<UserModel> _registeredVolunteers = [];
  bool _loadingVolunteers = true;
  String _errorMessage = '';
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get event from arguments
    final event = ModalRoute.of(context)?.settings.arguments as EventModel?;
    
    if (event != null) {
      _loadVolunteers(event);
    }
  }

  Future<void> _loadVolunteers(EventModel event) async {
    if (!mounted) return;
    
    setState(() {
      _loadingVolunteers = true;
      _errorMessage = '';
    });
    
    try {
      print('Loading volunteers for event ${event.id}');
      print('Registered participants: ${event.registeredParticipants}');
      
      // First, get latest event data to ensure we have current registrations
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .get();
          
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }
      
      // Get the updated list of registered participant IDs
      final data = eventDoc.data() as Map<String, dynamic>;
      final List<String> registeredIds = List<String>.from(data['registeredParticipants'] ?? []);
      
      print('Updated registered IDs: $registeredIds');
      
      List<UserModel> participants = [];
      
      // For each registered ID, try to get the user
      for (String userId in registeredIds) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
              
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            participants.add(UserModel(
              id: userDoc.id,
              name: userData['name'] ?? 'User $userId',
              email: userData['email'] ?? '',
              volunteerId: userData['volunteerId'] ?? '',
              bloodGroup: userData['bloodGroup'] ?? '',
              place: userData['place'] ?? '',
              department: userData['department'] ?? '',
              role: userData['role'] ?? 'volunteer',
              isApproved: userData['isApproved'] ?? false,
              eventsParticipated: [],
              createdAt: DateTime.now(),
            ));
          } else {
            // User document doesn't exist, create a placeholder
            participants.add(UserModel(
              id: userId,
              name: 'Volunteer #$userId',
              email: 'volunteer$userId@example.com',
              volunteerId: 'NSS$userId',
              bloodGroup: 'Unknown',
              place: 'Unknown',
              department: 'Unknown',
              role: 'volunteer',
              isApproved: true,
              eventsParticipated: [],
              createdAt: DateTime.now(),
            ));
          }
        } catch (e) {
          print('Error fetching user $userId: $e');
        }
      }
      
      if (!mounted) return;
      
      setState(() {
        _registeredVolunteers = participants;
        _loadingVolunteers = false;
      });
      
      print('Loaded ${_registeredVolunteers.length} volunteers');
    } catch (e) {
      print('Error loading volunteers: $e');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to load volunteers: ${e.toString()}';
        _loadingVolunteers = false;
        
        // Create some dummy data for testing
        _registeredVolunteers = event.registeredParticipants.map((id) {
          return UserModel(
            id: id,
            name: 'Test User $id',
            email: 'test$id@example.com',
            volunteerId: 'NSS$id',
            bloodGroup: 'O+',
            place: 'Test Location',
            department: 'Computer Science',
            role: 'volunteer',
            isApproved: true,
            eventsParticipated: [],
            createdAt: DateTime.now(),
          );
        }).toList();
      });
    }
  }

  void _showDeleteConfirmation(BuildContext context, EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                final eventService = Provider.of<EventService>(context, listen: false);
                await eventService.deleteEvent(event.id);
                
                if (!mounted) return;
                
                Navigator.pop(context); // Go back to events list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppConstants.successEventDeleted),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                
                setState(() {
                  _isLoading = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete event: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _removeParticipant(EventModel event, String volunteerId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final eventService = Provider.of<EventService>(context, listen: false);
      await eventService.removeRegistration(event.id, volunteerId);
      
      // Reload the event and participants
      final updatedEvent = await eventService.getEventById(event.id);
      if (updatedEvent != null) {
        await _loadVolunteers(updatedEvent);
      }
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Participant removed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove participant: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get event from arguments or use a mock event for UI development
    final event = ModalRoute.of(context)?.settings.arguments as EventModel? ??
        EventModel.getMockEvents().first;

    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    // Use real data from Firestore if available, otherwise fall back to mock data for development
    final List<UserModel> registeredVolunteers = _loadingVolunteers 
      ? [] 
      : (_errorMessage.isNotEmpty 
          ? [] 
          : _registeredVolunteers);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadVolunteers(event),
            tooltip: 'Refresh participants',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit event
              Navigator.pushNamed(
                context,
                '/admin/edit-event',
                arguments: event,
              ).then((result) {
                // Refresh data when back if edit was successful
                if (result == true && mounted) {
                  // Reload the event details
                  Provider.of<EventService>(context, listen: false)
                      .getEventById(event.id)
                      .then((updatedEvent) {
                    if (updatedEvent != null && mounted) {
                      // Refresh the page with the updated event
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminEventDetailsScreen(),
                          settings: RouteSettings(arguments: updatedEvent),
                        ),
                      );
                    }
                  });
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context, event),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Event Details
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event Status
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: _getStatusColor(event),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(event),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Event Title
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          // Event ID
                          Text(
                            'Event ID: ${event.id}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Event Date and Time
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Theme.of(context).primaryColor,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateFormat.format(event.startDate),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${timeFormat.format(event.startDate)} - ${timeFormat.format(event.endDate)}',
                                          style: const TextStyle(
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
                          const SizedBox(height: 8),
                          
                          // Event Location
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Theme.of(context).primaryColor,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Location',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          event.location,
                                          style: const TextStyle(
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
                          const SizedBox(height: 8),
                          
                          // Participants
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    color: Theme.of(context).primaryColor,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Participants',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${event.registeredParticipants.length}/${event.maxParticipants} volunteers registered',
                                          style: const TextStyle(
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
                          
                          // Event Description
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Registered Participants Section Title
                          const Text(
                            'Registered Participants',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Participants List
                          SizedBox(
                            height: 300, // Fixed height for the participant list
                            child: _loadingVolunteers
                                ? const Center(child: CircularProgressIndicator())
                                : _errorMessage.isNotEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              size: 48,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _errorMessage,
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: () => _loadVolunteers(event),
                                              child: const Text('Retry'),
                                            ),
                                          ],
                                        ),
                                      )
                                    : _buildParticipantList(
                                        registeredVolunteers,
                                        'No registered participants',
                                        event: event,
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomButton(
          text: 'Mark Attendance',
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/admin/attendance-management',
              arguments: event,
            );
          },
        ),
      ),
    );
  }

  Widget _buildParticipantList(List<UserModel> volunteers, String emptyMessage, {
    required EventModel event,
  }) {
    if (volunteers.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: volunteers.length,
      itemBuilder: (context, index) {
        final volunteer = volunteers[index];
        
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('ID: ${volunteer.volunteerId}'),
                Text('Department: ${volunteer.department}'),
              ],
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeParticipant(event, volunteer.id),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/admin/volunteer-details',
                arguments: volunteer,
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(EventModel event) {
    if (event.isPast) {
      return Colors.grey;
    } else if (event.isOngoing) {
      return Colors.orange;
    } else {
      return Theme.of(context).primaryColor;
    }
  }

  String _getStatusText(EventModel event) {
    if (event.isPast) {
      return 'Event Completed';
    } else if (event.isOngoing) {
      return 'Event Ongoing';
    } else {
      return 'Event Upcoming';
    }
  }
}







// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:nss_app/utils/constants.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:nss_app/services/event_service.dart';


// class AdminEventDetailsScreen extends StatefulWidget {
//   const AdminEventDetailsScreen({Key? key}) : super(key: key);

//   @override
//   State<AdminEventDetailsScreen> createState() => _AdminEventDetailsScreenState();
// }

// class _AdminEventDetailsScreenState extends State<AdminEventDetailsScreen> {
//   bool _isLoading = false;
  
//   // Lists to store real data from Firebase
//   List<UserModel> _registeredVolunteers = [];
//   bool _loadingVolunteers = true;
//   String _errorMessage = '';
  
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
    
//     // Get event from arguments
//     final event = ModalRoute.of(context)?.settings.arguments as EventModel?;
    
//     if (event != null) {
//       _loadVolunteers(event);
//     }
//   }

//   Future<void> _loadVolunteers(EventModel event) async {
//     if (!mounted) return;
    
//     setState(() {
//       _loadingVolunteers = true;
//       _errorMessage = '';
//     });
    
//     try {
//       final eventService = Provider.of<EventService>(context, listen: false);
      
//       // Get registered volunteers
//       final List<UserModel> registeredVolunteers = await eventService.getRegisteredUsers(event);
      
//       // If no registered users are found yet, use mock data for development
//       if (registeredVolunteers.isEmpty && event.registeredParticipants.isNotEmpty) {
//         // Add mock users based on registered IDs
//         final mockUsers = UserModel.getMockVolunteers()
//             .where((user) => event.registeredParticipants.contains(user.id))
//             .toList();
            
//         if (mockUsers.isEmpty) {
//           // If no matching mock users, create some dummy users
//           final dummyUsers = [
//             UserModel(
//               id: '1',
//               name: 'Adil Athweef P P',
//               email: 'adil@example.com',
//               volunteerId: 'NSS001',
//               bloodGroup: 'A+',
//               place: 'Malappuram',
//               department: 'Computer Science',
//               role: 'volunteer',
//               isApproved: true,
//               eventsParticipated: [event.id],
//               createdAt: DateTime.now().subtract(const Duration(days: 60)),
//             ),
//             UserModel(
//               id: '2',
//               name: 'Fuhad K',
//               email: 'fuhad@example.com',
//               volunteerId: 'NSS002',
//               bloodGroup: 'B+',
//               place: 'Malappuram',
//               department: 'Computer Application',
//               role: 'volunteer',
//               isApproved: true,
//               eventsParticipated: [event.id],
//               createdAt: DateTime.now().subtract(const Duration(days: 45)),
//             ),
//           ];
//           _registeredVolunteers = dummyUsers;
//         } else {
//           _registeredVolunteers = mockUsers;
//         }
//       } else {
//         _registeredVolunteers = registeredVolunteers;
//       }
      
//       if (!mounted) return;
      
//       setState(() {
//         _loadingVolunteers = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
      
//       setState(() {
//         // If error loading real data, fall back to mock data
//         _registeredVolunteers = UserModel.getMockVolunteers()
//             .where((user) => event.registeredParticipants.contains(user.id))
//             .toList();
            
//         if (_registeredVolunteers.isEmpty) {
//           // Add at least one dummy user if no mock data matched
//           _registeredVolunteers = [
//             UserModel(
//               id: '1',
//               name: 'Adil Athweef P P',
//               email: 'adil@example.com',
//               volunteerId: 'NSS001',
//               bloodGroup: 'A+',
//               place: 'Malappuram',
//               department: 'Computer Science',
//               role: 'volunteer',
//               isApproved: true,
//               eventsParticipated: [event.id],
//               createdAt: DateTime.now().subtract(const Duration(days: 60)),
//             ),
//           ];
//         }
        
//         _errorMessage = 'Failed to load volunteers from database: ${e.toString()}\nShowing mock data instead.';
//         _loadingVolunteers = false;
//       });
//     }
//   }

//   void _showDeleteConfirmation(BuildContext context, EventModel event) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Event'),
//         content: Text('Are you sure you want to delete "${event.title}"?'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context); // Close dialog
              
//               setState(() {
//                 _isLoading = true;
//               });
              
//               try {
//                 final eventService = Provider.of<EventService>(context, listen: false);
//                 await eventService.deleteEvent(event.id);
                
//                 if (!mounted) return;
                
//                 Navigator.pop(context); // Go back to events list
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text(AppConstants.successEventDeleted),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               } catch (e) {
//                 if (!mounted) return;
                
//                 setState(() {
//                   _isLoading = false;
//                 });
                
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Failed to delete event: ${e.toString()}'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//             style: TextButton.styleFrom(
//               foregroundColor: Colors.red,
//             ),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
  
//   Future<void> _removeParticipant(EventModel event, String volunteerId) async {
//     setState(() {
//       _isLoading = true;
//     });
    
//     try {
//       final eventService = Provider.of<EventService>(context, listen: false);
//       await eventService.removeRegistration(event.id, volunteerId);
      
//       // Reload the event and participants
//       final updatedEvent = await eventService.getEventById(event.id);
//       if (updatedEvent != null) {
//         await _loadVolunteers(updatedEvent);
//       }
      
//       if (!mounted) return;
      
//       setState(() {
//         _isLoading = false;
//       });
      
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Participant removed successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
      
//       setState(() {
//         _isLoading = false;
//       });
      
//       // Show error message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to remove participant: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Get event from arguments or use a mock event for UI development
//     final event = ModalRoute.of(context)?.settings.arguments as EventModel? ??
//         EventModel.getMockEvents().first;

//     final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
//     final timeFormat = DateFormat('hh:mm a');
    
//     // Use real data from Firestore if available, otherwise fall back to mock data for development
//     final List<UserModel> registeredVolunteers = _loadingVolunteers 
//       ? [] 
//       : (_errorMessage.isNotEmpty 
//           ? [] 
//           : _registeredVolunteers);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Event Details'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit),
//             onPressed: () {
//               // Navigate to edit event
//               Navigator.pushNamed(
//                 context,
//                 '/admin/edit-event',
//                 arguments: event,
//               ).then((result) {
//                 // Refresh data when back if edit was successful
//                 if (result == true && mounted) {
//                   // Reload the event details
//                   Provider.of<EventService>(context, listen: false)
//                       .getEventById(event.id)
//                       .then((updatedEvent) {
//                     if (updatedEvent != null && mounted) {
//                       // Refresh the page with the updated event
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const AdminEventDetailsScreen(),
//                           settings: RouteSettings(arguments: updatedEvent),
//                         ),
//                       );
//                     }
//                   });
//                 }
//               });
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete),
//             onPressed: () => _showDeleteConfirmation(context, event),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 // Event Details
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Event Status
//                           Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                             decoration: BoxDecoration(
//                               color: _getStatusColor(event),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               _getStatusText(event),
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
                          
//                           // Event Title
//                           Text(
//                             event.title,
//                             style: const TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
                          
//                           // Event ID
//                           // Text(
//                           //   'Event ID: ${event.id}',
//                           //   style: const TextStyle(
//                           //     fontSize: 14,
//                           //     color: Colors.grey,
//                           //   ),
//                           // ),
//                           // const SizedBox(height: 16),
                          
//                           // Event Date and Time
//                           Card(
//                             child: Padding(
//                               padding: const EdgeInsets.all(16),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.calendar_today,
//                                     color: Theme.of(context).primaryColor,
//                                     size: 32,
//                                   ),
//                                   const SizedBox(width: 16),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           dateFormat.format(event.startDate),
//                                           style: const TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           '${timeFormat.format(event.startDate)} - ${timeFormat.format(event.endDate)}',
//                                           style: const TextStyle(
//                                             color: Colors.black54,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 8),
                          
//                           // Event Location
//                           Card(
//                             child: Padding(
//                               padding: const EdgeInsets.all(16),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.location_on,
//                                     color: Theme.of(context).primaryColor,
//                                     size: 32,
//                                   ),
//                                   const SizedBox(width: 16),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         const Text(
//                                           'Location',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           event.location,
//                                           style: const TextStyle(
//                                             color: Colors.black54,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 8),
                          
//                           // Participants
//                           Card(
//                             child: Padding(
//                               padding: const EdgeInsets.all(16),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.people,
//                                     color: Theme.of(context).primaryColor,
//                                     size: 32,
//                                   ),
//                                   const SizedBox(width: 16),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         const Text(
//                                           'Participants',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           '${event.registeredParticipants.length}/${event.maxParticipants} volunteers registered',
//                                           style: const TextStyle(
//                                             color: Colors.black54,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
                          
//                           // Event Description
//                           const Text(
//                             'Description',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             event.description,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               height: 1.5,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
                          
//                           // Registered Participants Section Title
//                           const Text(
//                             'Registered Participants',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
                          
//                           // Participants List
//                           SizedBox(
//                             height: 300, // Fixed height for the participant list
//                             child: _loadingVolunteers
//                                 ? const Center(child: CircularProgressIndicator())
//                                 : _errorMessage.isNotEmpty
//                                     ? Center(
//                                         child: Column(
//                                           mainAxisAlignment: MainAxisAlignment.center,
//                                           children: [
//                                             const Icon(
//                                               Icons.error_outline,
//                                               size: 48,
//                                               color: Colors.red,
//                                             ),
//                                             const SizedBox(height: 16),
//                                             Text(
//                                               _errorMessage,
//                                               style: const TextStyle(
//                                                 color: Colors.red,
//                                               ),
//                                               textAlign: TextAlign.center,
//                                             ),
//                                             const SizedBox(height: 16),
//                                             ElevatedButton(
//                                               onPressed: () => _loadVolunteers(event),
//                                               child: const Text('Retry'),
//                                             ),
//                                           ],
//                                         ),
//                                       )
//                                     : _buildParticipantList(
//                                         registeredVolunteers,
//                                         'No registered participants',
//                                         event: event,
//                                       ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16),
//         child: CustomButton(
//           text: 'Mark Attendance',
//           onPressed: () {
//             Navigator.pushNamed(
//               context,
//               '/admin/attendance-management',
//               arguments: event,
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildParticipantList(List<UserModel> volunteers, String emptyMessage, {
//     required EventModel event,
//   }) {
//     if (volunteers.isEmpty) {
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
//       padding: const EdgeInsets.all(8),
//       itemCount: volunteers.length,
//       itemBuilder: (context, index) {
//         final volunteer = volunteers[index];
        
//         return Card(
//           margin: const EdgeInsets.only(bottom: 8),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Theme.of(context).primaryColor,
//               child: Text(
//                 volunteer.name.isNotEmpty ? volunteer.name.substring(0, 1) : '?',
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
//                 Text('Department: ${volunteer.department}'),
//               ],
//             ),
//             isThreeLine: true,
//             trailing: IconButton(
//               icon: const Icon(Icons.remove_circle, color: Colors.red),
//               onPressed: () => _removeParticipant(event, volunteer.id),
//             ),
//             onTap: () {
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

//   Color _getStatusColor(EventModel event) {
//     if (event.isPast) {
//       return Colors.grey;
//     } else if (event.isOngoing) {
//       return Colors.orange;
//     } else {
//       return Theme.of(context).primaryColor;
//     }
//   }

//   String _getStatusText(EventModel event) {
//     if (event.isPast) {
//       return 'Event Completed';
//     } else if (event.isOngoing) {
//       return 'Event Ongoing';
//     } else {
//       return 'Event Upcoming';
//     }
//   }
// }