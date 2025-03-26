import 'package:flutter/material.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/widgets/common/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nss_app/services/event_service.dart';
import 'package:nss_app/services/auth_service.dart';
import 'package:nss_app/services/feedback_service.dart';
import 'package:nss_app/services/profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerEventDetailsScreen extends StatefulWidget {
  const VolunteerEventDetailsScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerEventDetailsScreen> createState() => _VolunteerEventDetailsScreenState();
}

class _VolunteerEventDetailsScreenState extends State<VolunteerEventDetailsScreen> {
  bool _isRegistering = false;
  bool _isLoading = false;
  bool _isSubmittingFeedback = false;
  String _errorMessage = '';
  late EventModel _event;
  bool _isInitialized = false;
  String _userId = '';
  String _userName = '';
  String _existingFeedback = '';
  bool _hasCheckedFeedback = false;
  
  // Controller for feedback text field
  final TextEditingController _feedbackController = TextEditingController();
  
  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isInitialized) {
      _loadUserId();
      
      // Get event from arguments
      final event = ModalRoute.of(context)?.settings.arguments as EventModel?;
      
      if (event != null) {
        _event = event;
        _refreshEventData();
        _isInitialized = true;
      }
    }
  }
  
  void _loadUserId() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileService = Provider.of<ProfileService>(context, listen: false);
    
    setState(() {
      _userId = authService.currentUser?.uid ?? '';
    });
    
    // Also get user's name for feedback
    if (_userId.isNotEmpty) {
      try {
        final userProfile = await profileService.getCurrentUserProfile();
        if (userProfile != null && mounted) {
          setState(() {
            _userName = userProfile.name;
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
      }
    }
  }
  
  Future<void> _checkExistingFeedback() async {
    if (_hasCheckedFeedback || _userId.isEmpty || !_event.isPast) return;
    
    try {
      final feedbackService = Provider.of<FeedbackService>(context, listen: false);
      final feedback = await feedbackService.getFeedbackForEvent(
        volunteerId: _userId, 
        eventId: _event.id
      );
      
      if (feedback != null && mounted) {
        setState(() {
          _existingFeedback = feedback;
          _feedbackController.text = feedback;
        });
      }
      
      setState(() {
        _hasCheckedFeedback = true;
      });
    } catch (e) {
      print('Error checking existing feedback: $e');
    }
  }
  
  Future<void> _refreshEventData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final eventService = Provider.of<EventService>(context, listen: false);
      final updatedEvent = await eventService.getEventById(_event.id);
      
      if (updatedEvent != null && mounted) {
        setState(() {
          _event = updatedEvent;
          _isLoading = false;
        });
        
        // Check for existing feedback if event is past
        if (_event.isPast) {
          _checkExistingFeedback();
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to fetch the latest event data';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading event: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _registerForEvent() async {
    if (_userId.isEmpty) {
      _userId = "1"; // For testing, assign a default user ID if none exists
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Using default test user ID'),
          backgroundColor: Colors.blue,
        ),
      );
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final eventService = Provider.of<EventService>(context, listen: false);
      
      // Log registration attempt
      print('Attempting to register user $_userId for event ${_event.id}');
      
      // Simple direct update to Firestore
      await FirebaseFirestore.instance
          .collection('events')
          .doc(_event.id)
          .update({
        'registeredParticipants': FieldValue.arrayUnion([_userId]),
      });
      
      // Refresh the event data after registration
      await _refreshEventData();
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully registered for event! User ID: $_userId'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      print('Registration error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }
  
  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your feedback'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmittingFeedback = true;
    });
    
    try {
      final feedbackService = Provider.of<FeedbackService>(context, listen: false);
      
      // Check if feedback already exists
      final existingFeedbackId = await feedbackService.getFeedbackIdForEvent(
        volunteerId: _userId,
        eventId: _event.id,
      );
      
      if (existingFeedbackId != null) {
        // Update existing feedback
        await feedbackService.updateFeedback(
          feedbackId: existingFeedbackId,
          feedback: _feedbackController.text.trim(),
        );
      } else {
        // Submit new feedback
        await feedbackService.submitFeedback(
          volunteerId: _userId,
          volunteerName: _userName.isNotEmpty ? _userName : 'Unknown Volunteer',
          eventId: _event.id,
          eventName: _event.title,
          eventDate: _event.startDate,
          feedback: _feedbackController.text.trim(),
        );
      }
      
      if (!mounted) return;
      
      setState(() {
        _existingFeedback = _feedbackController.text.trim();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      print('Feedback submission error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting feedback: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingFeedback = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshEventData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    final isRegistered = _event.registeredParticipants.contains(_userId);
    final isPast = _event.isPast;
    final isOngoing = _event.isOngoing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEventData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: _getStatusColor(isPast, isOngoing, isRegistered),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(isPast, isOngoing, isRegistered),
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
                _event.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              
              // Event ID
              Text(
                'Event ID: ${_event.id}',
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
                              dateFormat.format(_event.startDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${timeFormat.format(_event.startDate)} - ${timeFormat.format(_event.endDate)}',
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
                              _event.location,
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
                              '${_event.registeredParticipants.length}/${_event.maxParticipants} volunteers registered',
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
                _event.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Registration Button
              if (!isPast && !isRegistered)
                CustomButton(
                  text: 'Register for Event',
                  isLoading: _isRegistering,
                  onPressed: _registerForEvent,
                ),
                
              // Already Registered
              if (isRegistered && !isPast)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registered Successfully',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'You are registered for this event. Make sure to attend on time!',
                              style: TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Feedback Section (only for past events)
              if (isPast && isRegistered)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'Event Feedback',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // If feedback already exists, show it
                    if (_existingFeedback.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Submitted Feedback:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _existingFeedback,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _existingFeedback = '';
                                      _feedbackController.text = '';
                                    });
                                  },
                                  child: const Text('Edit Feedback'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Please share your experience about this event:',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _feedbackController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Write your feedback here...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: 'Submit Feedback',
                              isLoading: _isSubmittingFeedback,
                              onPressed: _submitFeedback,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(bool isPast, bool isOngoing, bool isRegistered) {
    if (isPast) {
      return Colors.grey;
    } else if (isOngoing) {
      return Colors.orange;
    } else if (isRegistered) {
      return Colors.green;
    } else {
      return Theme.of(context).primaryColor;
    }
  }

  String _getStatusText(bool isPast, bool isOngoing, bool isRegistered) {
    if (isPast) {
      return 'Event Completed';
    } else if (isOngoing) {
      return 'Event Ongoing';
    } else if (isRegistered) {
      return 'Registered';
    } else {
      return 'Registration Open';
    }
  }
}





















// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:nss_app/services/event_service.dart';
// import 'package:nss_app/services/auth_service.dart';
// import 'package:nss_app/services/feedback_service.dart';
// import 'package:nss_app/services/profile_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class VolunteerEventDetailsScreen extends StatefulWidget {
//   const VolunteerEventDetailsScreen({Key? key}) : super(key: key);

//   @override
//   State<VolunteerEventDetailsScreen> createState() => _VolunteerEventDetailsScreenState();
// }

// class _VolunteerEventDetailsScreenState extends State<VolunteerEventDetailsScreen> {
//   bool _isRegistering = false;
//   bool _isLoading = false;
//   bool _isSubmittingFeedback = false;
//   String _errorMessage = '';
//   late EventModel _event;
//   bool _isInitialized = false;
//   String _userId = '';
//   String _userName = '';
//   String _existingFeedback = '';
//   bool _hasCheckedFeedback = false;
  
//   // Controller for feedback text field
//   final TextEditingController _feedbackController = TextEditingController();
  
//   @override
//   void dispose() {
//     _feedbackController.dispose();
//     super.dispose();
//   }
  
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
    
//     if (!_isInitialized) {
//       _loadUserId();
      
//       // Get event from arguments
//       final event = ModalRoute.of(context)?.settings.arguments as EventModel?;
      
//       if (event != null) {
//         _event = event;
//         _refreshEventData();
//         _isInitialized = true;
//       }
//     }
//   }
  
//   void _loadUserId() async {
//     final authService = Provider.of<AuthService>(context, listen: false);
//     final profileService = Provider.of<ProfileService>(context, listen: false);
    
//     setState(() {
//       _userId = authService.currentUser?.uid ?? '';
//     });
    
//     // Also get user's name for feedback
//     if (_userId.isNotEmpty) {
//       try {
//         final userProfile = await profileService.getCurrentUserProfile();
//         if (userProfile != null && mounted) {
//           setState(() {
//             _userName = userProfile.name;
//           });
//         }
//       } catch (e) {
//         print('Error loading user profile: $e');
//       }
//     }
//   }
  
//   Future<void> _checkExistingFeedback() async {
//     if (_hasCheckedFeedback || _userId.isEmpty || !_event.isPast) return;
    
//     try {
//       final feedbackService = Provider.of<FeedbackService>(context, listen: false);
//       final feedback = await feedbackService.getFeedbackForEvent(
//         volunteerId: _userId, 
//         eventId: _event.id
//       );
      
//       if (feedback != null && mounted) {
//         setState(() {
//           _existingFeedback = feedback;
//           _feedbackController.text = feedback;
//         });
//       }
      
//       setState(() {
//         _hasCheckedFeedback = true;
//       });
//     } catch (e) {
//       print('Error checking existing feedback: $e');
//     }
//   }
  
//   Future<void> _refreshEventData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });
    
//     try {
//       final eventService = Provider.of<EventService>(context, listen: false);
//       final updatedEvent = await eventService.getEventById(_event.id);
      
//       if (updatedEvent != null && mounted) {
//         setState(() {
//           _event = updatedEvent;
//           _isLoading = false;
//         });
        
//         // Check for existing feedback if event is past
//         if (_event.isPast) {
//           _checkExistingFeedback();
//         }
//       } else if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'Unable to fetch the latest event data';
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'Error loading event: ${e.toString()}';
//         });
//       }
//     }
//   }

//   Future<void> _registerForEvent() async {
//     if (_userId.isEmpty) {
//       _userId = "1"; // For testing, assign a default user ID if none exists
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Using default test user ID'),
//           backgroundColor: Colors.blue,
//         ),
//       );
//     }

//     setState(() {
//       _isRegistering = true;
//     });

//     try {
//       final eventService = Provider.of<EventService>(context, listen: false);
      
//       // Log registration attempt
//       print('Attempting to register user $_userId for event ${_event.id}');
      
//       // Simple direct update to Firestore
//       await FirebaseFirestore.instance
//           .collection('events')
//           .doc(_event.id)
//           .update({
//         'registeredParticipants': FieldValue.arrayUnion([_userId]),
//       });
      
//       // Refresh the event data after registration
//       await _refreshEventData();
      
//       if (!mounted) return;
      
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Successfully registered for event! User ID: $_userId'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
      
//       print('Registration error: $e');
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Registration failed: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isRegistering = false;
//         });
//       }
//     }
//   }
  
//   Future<void> _submitFeedback() async {
//     if (_feedbackController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter your feedback'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }
    
//     setState(() {
//       _isSubmittingFeedback = true;
//     });
    
//     try {
//       final feedbackService = Provider.of<FeedbackService>(context, listen: false);
      
//       await feedbackService.submitFeedback(
//         volunteerId: _userId,
//         volunteerName: _userName.isNotEmpty ? _userName : 'Unknown Volunteer',
//         eventId: _event.id,
//         eventName: _event.title,
//         eventDate: _event.startDate,
//         feedback: _feedbackController.text.trim(),
//       );
      
//       if (!mounted) return;
      
//       setState(() {
//         _existingFeedback = _feedbackController.text.trim();
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Feedback submitted successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
      
//       print('Feedback submission error: $e');
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error submitting feedback: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSubmittingFeedback = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isInitialized) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Event Details')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_errorMessage.isNotEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Event Details')),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.error_outline,
//                 size: 64,
//                 color: Colors.red,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 _errorMessage,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.red,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: _refreshEventData,
//                 child: const Text('Retry'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
//     final timeFormat = DateFormat('hh:mm a');
    
//     final isRegistered = _event.registeredParticipants.contains(_userId);
//     final isPast = _event.isPast;
//     final isOngoing = _event.isOngoing;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Event Details'),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _refreshEventData,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Event Status
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(isPast, isOngoing, isRegistered),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   _getStatusText(isPast, isOngoing, isRegistered),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Event Title
//               Text(
//                 _event.title,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 4),
              
//               // Event ID
//               Text(
//                 'Event ID: ${_event.id}',
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Event Date and Time
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.calendar_today,
//                         color: Theme.of(context).primaryColor,
//                         size: 32,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               dateFormat.format(_event.startDate),
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               '${timeFormat.format(_event.startDate)} - ${timeFormat.format(_event.endDate)}',
//                               style: const TextStyle(
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
              
//               // Event Location
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.location_on,
//                         color: Theme.of(context).primaryColor,
//                         size: 32,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Location',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               _event.location,
//                               style: const TextStyle(
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
              
//               // Participants
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.people,
//                         color: Theme.of(context).primaryColor,
//                         size: 32,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Participants',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               '${_event.registeredParticipants.length}/${_event.maxParticipants} volunteers registered',
//                               style: const TextStyle(
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Event Description
//               const Text(
//                 'Description',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _event.description,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 32),
              
//               // Registration Button
//               if (!isPast && !isRegistered)
//                 CustomButton(
//                   text: 'Register for Event',
//                   isLoading: _isRegistering,
//                   onPressed: _registerForEvent,
//                 ),
                
//               // Already Registered
//               if (isRegistered && !isPast)
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.green.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.green),
//                   ),
//                   child: const Row(
//                     children: [
//                       Icon(
//                         Icons.check_circle,
//                         color: Colors.green,
//                       ),
//                       SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Registered Successfully',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green,
//                               ),
//                             ),
//                             SizedBox(height: 4),
//                             Text(
//                               'You are registered for this event. Make sure to attend on time!',
//                               style: TextStyle(
//                                 color: Colors.black87,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
              
//               // Feedback Section (only for past events)
//               if (isPast && isRegistered)
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 24),
//                     const Text(
//                       'Event Feedback',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
                    
//                     // If feedback already exists, show it
//                     if (_existingFeedback.isNotEmpty)
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.blue),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Your Submitted Feedback:',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.blue,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               _existingFeedback,
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 height: 1.5,
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 TextButton(
//                                   onPressed: () {
//                                     setState(() {
//                                       _existingFeedback = '';
//                                       _feedbackController.text = '';
//                                     });
//                                   },
//                                   child: const Text('Edit Feedback'),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       )
//                     else
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Please share your experience about this event:',
//                             style: TextStyle(
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           TextField(
//                             controller: _feedbackController,
//                             maxLines: 5,
//                             decoration: InputDecoration(
//                               hintText: 'Write your feedback here...',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                                 borderSide: BorderSide(
//                                   color: Theme.of(context).primaryColor,
//                                   width: 2,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           SizedBox(
//                             width: double.infinity,
//                             child: CustomButton(
//                               text: 'Submit Feedback',
//                               isLoading: _isSubmittingFeedback,
//                               onPressed: _submitFeedback,
//                             ),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(bool isPast, bool isOngoing, bool isRegistered) {
//     if (isPast) {
//       return Colors.grey;
//     } else if (isOngoing) {
//       return Colors.orange;
//     } else if (isRegistered) {
//       return Colors.green;
//     } else {
//       return Theme.of(context).primaryColor;
//     }
//   }

//   String _getStatusText(bool isPast, bool isOngoing, bool isRegistered) {
//     if (isPast) {
//       return 'Event Completed';
//     } else if (isOngoing) {
//       return 'Event Ongoing';
//     } else if (isRegistered) {
//       return 'Registered';
//     } else {
//       return 'Registration Open';
//     }
//   }
// }



















// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:nss_app/services/event_service.dart';
// import 'package:nss_app/services/auth_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class VolunteerEventDetailsScreen extends StatefulWidget {
//   const VolunteerEventDetailsScreen({Key? key}) : super(key: key);

//   @override
//   State<VolunteerEventDetailsScreen> createState() => _VolunteerEventDetailsScreenState();
// }

// class _VolunteerEventDetailsScreenState extends State<VolunteerEventDetailsScreen> {
//   bool _isRegistering = false;
//   bool _isLoading = false;
//   String _errorMessage = '';
//   late EventModel _event;
//   bool _isInitialized = false;
//   String _userId = '';
  
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
    
//     if (!_isInitialized) {
//       _loadUserId();
      
//       // Get event from arguments
//       final event = ModalRoute.of(context)?.settings.arguments as EventModel?;
      
//       if (event != null) {
//         _event = event;
//         _refreshEventData();
//         _isInitialized = true;
//       }
//     }
//   }
  
//   void _loadUserId() {
//     final authService = Provider.of<AuthService>(context, listen: false);
//     _userId = authService.currentUser?.uid ?? '';
//   }
  
//   Future<void> _refreshEventData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });
    
//     try {
//       final eventService = Provider.of<EventService>(context, listen: false);
//       final updatedEvent = await eventService.getEventById(_event.id);
      
//       if (updatedEvent != null && mounted) {
//         setState(() {
//           _event = updatedEvent;
//           _isLoading = false;
//         });
//       } else if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'Unable to fetch the latest event data';
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'Error loading event: ${e.toString()}';
//         });
//       }
//     }
//   }

//   Future<void> _registerForEvent() async {
//     if (_userId.isEmpty) {
//       _userId = "1"; // For testing, assign a default user ID if none exists
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Using default test user ID'),
//           backgroundColor: Colors.blue,
//         ),
//       );
//     }

//     setState(() {
//       _isRegistering = true;
//     });

//     try {
//       final eventService = Provider.of<EventService>(context, listen: false);
      
//       // Log registration attempt
//       print('Attempting to register user $_userId for event ${_event.id}');
      
//       // Simple direct update to Firestore
//       await FirebaseFirestore.instance
//           .collection('events')
//           .doc(_event.id)
//           .update({
//         'registeredParticipants': FieldValue.arrayUnion([_userId]),
//       });
      
//       // Refresh the event data after registration
//       await _refreshEventData();
      
//       if (!mounted) return;
      
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Successfully registered for event! User ID: $_userId'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
      
//       print('Registration error: $e');
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Registration failed: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isRegistering = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isInitialized) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Event Details')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_errorMessage.isNotEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Event Details')),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.error_outline,
//                 size: 64,
//                 color: Colors.red,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 _errorMessage,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.red,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: _refreshEventData,
//                 child: const Text('Retry'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
//     final timeFormat = DateFormat('hh:mm a');
    
//     final isRegistered = _event.registeredParticipants.contains(_userId);
//     final isPast = _event.isPast;
//     final isOngoing = _event.isOngoing;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Event Details'),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _refreshEventData,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Event Status
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(isPast, isOngoing, isRegistered),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   _getStatusText(isPast, isOngoing, isRegistered),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Event Title
//               Text(
//                 _event.title,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 4),
              
//               // Event ID
//               Text(
//                 'Event ID: ${_event.id}',
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Event Date and Time
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.calendar_today,
//                         color: Theme.of(context).primaryColor,
//                         size: 32,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               dateFormat.format(_event.startDate),
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               '${timeFormat.format(_event.startDate)} - ${timeFormat.format(_event.endDate)}',
//                               style: const TextStyle(
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
              
//               // Event Location
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.location_on,
//                         color: Theme.of(context).primaryColor,
//                         size: 32,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Location',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               _event.location,
//                               style: const TextStyle(
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
              
//               // Participants
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.people,
//                         color: Theme.of(context).primaryColor,
//                         size: 32,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Participants',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               '${_event.registeredParticipants.length}/${_event.maxParticipants} volunteers registered',
//                               style: const TextStyle(
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Event Description
//               const Text(
//                 'Description',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _event.description,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 32),
              
//               // Registration Button
//               if (!isPast && !isRegistered)
//                 CustomButton(
//                   text: 'Register for Event',
//                   isLoading: _isRegistering,
//                   onPressed: _registerForEvent,
//                 ),
                
//               // Already Registered
//               if (isRegistered && !isPast)
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.green.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.green),
//                   ),
//                   child: const Row(
//                     children: [
//                       Icon(
//                         Icons.check_circle,
//                         color: Colors.green,
//                       ),
//                       SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Registered Successfully',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green,
//                               ),
//                             ),
//                             SizedBox(height: 4),
//                             Text(
//                               'You are registered for this event. Make sure to attend on time!',
//                               style: TextStyle(
//                                 color: Colors.black87,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(bool isPast, bool isOngoing, bool isRegistered) {
//     if (isPast) {
//       return Colors.grey;
//     } else if (isOngoing) {
//       return Colors.orange;
//     } else if (isRegistered) {
//       return Colors.green;
//     } else {
//       return Theme.of(context).primaryColor;
//     }
//   }

//   String _getStatusText(bool isPast, bool isOngoing, bool isRegistered) {
//     if (isPast) {
//       return 'Event Completed';
//     } else if (isOngoing) {
//       return 'Event Ongoing';
//     } else if (isRegistered) {
//       return 'Registered';
//     } else {
//       return 'Registration Open';
//     }
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/utils/constants.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:nss_app/services/event_service.dart';
// import 'package:nss_app/services/auth_service.dart';

// class VolunteerEventDetailsScreen extends StatefulWidget {
//   const VolunteerEventDetailsScreen({Key? key}) : super(key: key);

//   @override
//   State<VolunteerEventDetailsScreen> createState() => _VolunteerEventDetailsScreenState();
// }

// class _VolunteerEventDetailsScreenState extends State<VolunteerEventDetailsScreen> {
//   bool _isRegistering = false;
//   bool _isLoading = false;
//   String _errorMessage = '';
//   late EventModel _event;
//   bool _isInitialized = false;
//   String _userId = '';
  
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
    
//     if (!_isInitialized) {
//       _loadUserId();
      
//       // Get event from arguments
//       final event = ModalRoute.of(context)?.settings.arguments as EventModel?;
      
//       if (event != null) {
//         _event = event;
//         _refreshEventData();
//         _isInitialized = true;
//       }
//     }
//   }
  
//   void _loadUserId() {
//     final authService = Provider.of<AuthService>(context, listen: false);
//     _userId = authService.currentUser?.uid ?? '';
//   }
  
//   Future<void> _refreshEventData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });
    
//     try {
//       final eventService = Provider.of<EventService>(context, listen: false);
//       final updatedEvent = await eventService.getEventById(_event.id);
      
//       if (updatedEvent != null && mounted) {
//         setState(() {
//           _event = updatedEvent;
//           _isLoading = false;
//         });
//       } else if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'Unable to fetch the latest event data';
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'Error loading event: ${e.toString()}';
//         });
//       }
//     }
//   }

//   Future<void> _registerForEvent() async {
//     if (_userId.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please log in to register for events'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _isRegistering = true;
//     });

//     try {
//       final eventService = Provider.of<EventService>(context, listen: false);
//       await eventService.registerForEvent(_event.id, _userId);
      
//       // Refresh the event data after registration
//       await _refreshEventData();
      
//       if (!mounted) return;
      
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(AppConstants.successParticipationRequested),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Registration failed: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isRegistering = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isInitialized) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Event Details')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_errorMessage.isNotEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Event Details')),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.error_outline,
//                 size: 64,
//                 color: Colors.red,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 _errorMessage,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.red,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: _refreshEventData,
//                 child: const Text('Retry'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
//     final timeFormat = DateFormat('hh:mm a');
    
//     final isRegistered = _event.registeredParticipants.contains(_userId);
//     final isPast = _event.isPast;
//     final isOngoing = _event.isOngoing;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Event Details'),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _refreshEventData,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Event Status
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(isPast, isOngoing, isRegistered),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   _getStatusText(isPast, isOngoing, isRegistered),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Event Title
//               Text(
//                 _event.title,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 4),
              
//               // Event ID
//               Text(
//                 'Event ID: ${_event.id}',
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Event Date and Time
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.calendar_today,
//                         color: Theme.of(context).primaryColor,
//                         size: 32,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               dateFormat.format(_event.startDate),
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               '${timeFormat.format(_event.startDate)} - ${timeFormat.format(_event.endDate)}',
//                               style: const TextStyle(
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
              
//               // Event Location
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.location_on,
//                         color: Theme.of(context).primaryColor,
//                         size: 32,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Location',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               _event.location,
//                               style: const TextStyle(
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
              
//               // Participants
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.people,
//                         color: Theme.of(context).primaryColor,
//                         size: 32,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Participants',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               '${_event.registeredParticipants.length}/${_event.maxParticipants} volunteers registered',
//                               style: const TextStyle(
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Event Description
//               const Text(
//                 'Description',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _event.description,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 32),
              
//               // Registration Button
//               if (!isPast && !isRegistered)
//                 CustomButton(
//                   text: 'Register for Event',
//                   isLoading: _isRegistering,
//                   onPressed: _registerForEvent,
//                 ),
                
//               // Already Registered
//               if (isRegistered && !isPast)
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.green.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.green),
//                   ),
//                   child: const Row(
//                     children: [
//                       Icon(
//                         Icons.check_circle,
//                         color: Colors.green,
//                       ),
//                       SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Registered Successfully',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green,
//                               ),
//                             ),
//                             SizedBox(height: 4),
//                             Text(
//                               'You are registered for this event. Make sure to attend on time!',
//                               style: TextStyle(
//                                 color: Colors.black87,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(bool isPast, bool isOngoing, bool isRegistered) {
//     if (isPast) {
//       return Colors.grey;
//     } else if (isOngoing) {
//       return Colors.orange;
//     } else if (isRegistered) {
//       return Colors.green;
//     } else {
//       return Theme.of(context).primaryColor;
//     }
//   }

//   String _getStatusText(bool isPast, bool isOngoing, bool isRegistered) {
//     if (isPast) {
//       return 'Event Completed';
//     } else if (isOngoing) {
//       return 'Event Ongoing';
//     } else if (isRegistered) {
//       return 'Registered';
//     } else {
//       return 'Registration Open';
//     }
//   }
// }







// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:nss_app/utils/constants.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:intl/intl.dart';

// class VolunteerEventDetailsScreen extends StatefulWidget {
//   const VolunteerEventDetailsScreen({Key? key}) : super(key: key);

//   @override
//   State<VolunteerEventDetailsScreen> createState() => _VolunteerEventDetailsScreenState();
// }

// class _VolunteerEventDetailsScreenState extends State<VolunteerEventDetailsScreen> {
//   bool _isRegistering = false;
  
//   // Mock user for UI development
//   final UserModel _currentUser = UserModel.getMockVolunteers().first;

//   Future<void> _registerForEvent(EventModel event) async {
//     setState(() {
//       _isRegistering = true;
//     });

//     // Simulate API call
//     await Future.delayed(const Duration(seconds: 2));

//     setState(() {
//       _isRegistering = false;
//     });

//     if (!mounted) return;

//     // Show success message
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(AppConstants.successParticipationRequested),
//         backgroundColor: Colors.green,
//       ),
//     );

//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Get event from arguments or use a mock event for UI development
//     final event = ModalRoute.of(context)?.settings.arguments as EventModel? ??
//         EventModel.getMockEvents().first;

//     final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
//     final timeFormat = DateFormat('hh:mm a');
    
//     final isRegistered = event.registeredParticipants.contains(_currentUser.id);
//     final isPast = event.isPast;
//     final isOngoing = event.isOngoing;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Event Details'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Event Status
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//               decoration: BoxDecoration(
//                 color: _getStatusColor(isPast, isOngoing, isRegistered),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 _getStatusText(isPast, isOngoing, isRegistered),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Event Title
//             Text(
//               event.title,
//               style: const TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Event Date and Time
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.calendar_today,
//                       color: Theme.of(context).primaryColor,
//                       size: 32,
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             dateFormat.format(event.startDate),
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '${timeFormat.format(event.startDate)} - ${timeFormat.format(event.endDate)}',
//                             style: const TextStyle(
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
            
//             // Event Location
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.location_on,
//                       color: Theme.of(context).primaryColor,
//                       size: 32,
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Location',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             event.location,
//                             style: const TextStyle(
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
            
//             // Participants
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.people,
//                       color: Theme.of(context).primaryColor,
//                       size: 32,
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Participants',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '${event.registeredParticipants.length}/${event.maxParticipants} volunteers registered',
//                             style: const TextStyle(
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Event Description
//             const Text(
//               'Description',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               event.description,
//               style: const TextStyle(
//                 fontSize: 16,
//                 height: 1.5,
//               ),
//             ),
//             const SizedBox(height: 32),
            
//             // Registration Button
//             if (!isPast && !isRegistered)
//               CustomButton(
//                 text: 'Register for Event',
//                 isLoading: _isRegistering,
//                 onPressed: () => _registerForEvent(event),
//               ),
              
//             // Already Registered
//             if (isRegistered && !isPast)
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.green),
//                 ),
//                 child: const Row(
//                   children: [
//                     Icon(
//                       Icons.check_circle,
//                       color: Colors.green,
//                     ),
//                     SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Registered Successfully',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             'You are registered for this event. Make sure to attend on time!',
//                             style: TextStyle(
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(bool isPast, bool isOngoing, bool isRegistered) {
//     if (isPast) {
//       return Colors.grey;
//     } else if (isOngoing) {
//       return Colors.orange;
//     } else if (isRegistered) {
//       return Colors.green;
//     } else {
//       return Theme.of(context).primaryColor;
//     }
//   }

//   String _getStatusText(bool isPast, bool isOngoing, bool isRegistered) {
//     if (isPast) {
//       return 'Event Completed';
//     } else if (isOngoing) {
//       return 'Event Ongoing';
//     } else if (isRegistered) {
//       return 'Registered';
//     } else {
//       return 'Registration Open';
//     }
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:nss_app/utils/constants.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:intl/intl.dart';

// class VolunteerEventDetailsScreen extends StatefulWidget {
//   const VolunteerEventDetailsScreen({Key? key}) : super(key: key);

//   @override
//   State<VolunteerEventDetailsScreen> createState() => _VolunteerEventDetailsScreenState();
// }

// class _VolunteerEventDetailsScreenState extends State<VolunteerEventDetailsScreen> {
//   bool _isRegistering = false;
  
//   // Mock user for UI development
//   final UserModel _currentUser = UserModel.getMockVolunteers().first;

//   Future<void> _registerForEvent(EventModel event) async {
//     setState(() {
//       _isRegistering = true;
//     });

//     // Simulate API call
//     await Future.delayed(const Duration(seconds: 2));

//     setState(() {
//       _isRegistering = false;
//     });

//     if (!mounted) return;

//     // Show success message
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(AppConstants.successParticipationRequested),
//         backgroundColor: Colors.green,
//       ),
//     );

//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Get event from arguments or use a mock event for UI development
//     final event = ModalRoute.of(context)?.settings.arguments as EventModel? ??
//         EventModel.getMockEvents().first;

//     final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
//     final timeFormat = DateFormat('hh:mm a');
    
//     final isRegistered = event.registeredParticipants.contains(_currentUser.id);
//     final isApproved = event.approvedParticipants.contains(_currentUser.id);
//     final isPast = event.isPast;
//     final isOngoing = event.isOngoing;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Event Details'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Event Status
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//               decoration: BoxDecoration(
//                 color: _getStatusColor(isPast, isOngoing, isRegistered, isApproved),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 _getStatusText(isPast, isOngoing, isRegistered, isApproved),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Event Title
//             Text(
//               event.title,
//               style: const TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Event Date and Time
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.calendar_today,
//                       color: Theme.of(context).primaryColor,
//                       size: 32,
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             dateFormat.format(event.startDate),
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '${timeFormat.format(event.startDate)} - ${timeFormat.format(event.endDate)}',
//                             style: const TextStyle(
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
            
//             // Event Location
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.location_on,
//                       color: Theme.of(context).primaryColor,
//                       size: 32,
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Location',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             event.location,
//                             style: const TextStyle(
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
            
//             // Participants
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.people,
//                       color: Theme.of(context).primaryColor,
//                       size: 32,
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Participants',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '${event.approvedParticipants.length}/${event.maxParticipants} volunteers registered',
//                             style: const TextStyle(
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Event Description
//             const Text(
//               'Description',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               event.description,
//               style: const TextStyle(
//                 fontSize: 16,
//                 height: 1.5,
//               ),
//             ),
//             const SizedBox(height: 32),
            
//             // Registration Button
//             if (!isPast && !isRegistered)
//               CustomButton(
//                 text: 'Register for Event',
//                 isLoading: _isRegistering,
//                 onPressed: () => _registerForEvent(event),
//               ),
              
//             // Registered but not approved
//             if (isRegistered && !isApproved)
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.orange),
//                 ),
//                 child: const Row(
//                   children: [
//                     Icon(
//                       Icons.info,
//                       color: Colors.orange,
//                     ),
//                     SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Registration Pending',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.orange,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             'Your registration is pending approval from the admin.',
//                             style: TextStyle(
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//             // Registered and approved
//             if (isApproved && !isPast)
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.green),
//                 ),
//                 child: const Row(
//                   children: [
//                     Icon(
//                       Icons.check_circle,
//                       color: Colors.green,
//                     ),
//                     SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Registration Approved',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             'Your registration has been approved. Make sure to attend on time!',
//                             style: TextStyle(
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(bool isPast, bool isOngoing, bool isRegistered, bool isApproved) {
//     if (isPast) {
//       return Colors.grey;
//     } else if (isOngoing) {
//       return Colors.orange;
//     } else if (isRegistered && isApproved) {
//       return Colors.green;
//     } else if (isRegistered) {
//       return Colors.orange;
//     } else {
//       return Theme.of(context).primaryColor;
//     }
//   }

//   String _getStatusText(bool isPast, bool isOngoing, bool isRegistered, bool isApproved) {
//     if (isPast) {
//       return 'Event Completed';
//     } else if (isOngoing) {
//       return 'Event Ongoing';
//     } else if (isRegistered && isApproved) {
//       return 'Registered & Approved';
//     } else if (isRegistered) {
//       return 'Registration Pending Approval';
//     } else {
//       return 'Registration Open';
//     }
//   }
// }