import 'package:flutter/material.dart';
import 'package:nss_app/utils/constants.dart';
import 'package:nss_app/widgets/common/custom_button.dart';
import 'package:nss_app/widgets/common/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nss_app/services/event_service.dart';
import 'package:nss_app/services/auth_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);
  
  bool _isLoading = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }
  
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, update it
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }
  
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }
  
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }
  
  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }
  
  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
  
  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      // Check if end date/time is after start date/time
      final startDateTime = _combineDateAndTime(_startDate, _startTime);
      final endDateTime = _combineDateAndTime(_endDate, _endTime);
      
      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final eventService = Provider.of<EventService>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        
        final userId = authService.currentUser?.uid ?? '';
        
        final eventId = await eventService.createEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          startDate: startDateTime,
          endDate: endDateTime,
          location: _locationController.text.trim(),
          maxParticipants: int.parse(_maxParticipantsController.text.trim()),
          createdBy: userId,
        );
        
        if (!mounted) return;
        
        // Show success message with event ID
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.successEventCreated} (ID: $eventId)'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create event: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Event Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Event Title Field
              const Text(
                'Event Title',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _titleController,
                hintText: 'Enter event title',
                prefixIcon: Icons.event,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description Field
              const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Enter event description',
                prefixIcon: Icons.description,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Location Field
              const Text(
                'Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _locationController,
                hintText: 'Enter event location',
                prefixIcon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Date and Time Section
              const Text(
                'Date and Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Start Date and Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(dateFormat.format(_startDate)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 20),
                            const SizedBox(width: 8),
                            Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Start Date & Time',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              
              // End Date and Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(dateFormat.format(_endDate)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 20),
                            const SizedBox(width: 8),
                            Text('${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'End Date & Time',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              
              // Max Participants Field
              const Text(
                'Maximum Participants',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _maxParticipantsController,
                hintText: 'Enter maximum number of participants',
                prefixIcon: Icons.people,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter maximum participants';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Create Button
              CustomButton(
                text: 'Create Event',
                isLoading: _isLoading,
                onPressed: _createEvent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:nss_app/utils/constants.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:nss_app/widgets/common/custom_text_field.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:nss_app/services/event_service.dart';
// import 'package:nss_app/services/auth_service.dart';

// class CreateEventScreen extends StatefulWidget {
//   const CreateEventScreen({Key? key}) : super(key: key);

//   @override
//   State<CreateEventScreen> createState() => _CreateEventScreenState();
// }

// class _CreateEventScreenState extends State<CreateEventScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _locationController = TextEditingController();
//   final _maxParticipantsController = TextEditingController();
  
//   DateTime _startDate = DateTime.now().add(const Duration(days: 1));
//   TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
//   DateTime _endDate = DateTime.now().add(const Duration(days: 1));
//   TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);
  
//   bool _isLoading = false;
  
//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _locationController.dispose();
//     _maxParticipantsController.dispose();
//     super.dispose();
//   }
  
//   Future<void> _selectStartDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _startDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked != null && picked != _startDate) {
//       setState(() {
//         _startDate = picked;
//         // If end date is before start date, update it
//         if (_endDate.isBefore(_startDate)) {
//           _endDate = _startDate;
//         }
//       });
//     }
//   }
  
//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _startTime,
//     );
//     if (picked != null && picked != _startTime) {
//       setState(() {
//         _startTime = picked;
//       });
//     }
//   }
  
//   Future<void> _selectEndDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _endDate,
//       firstDate: _startDate,
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked != null && picked != _endDate) {
//       setState(() {
//         _endDate = picked;
//       });
//     }
//   }
  
//   Future<void> _selectEndTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _endTime,
//     );
//     if (picked != null && picked != _endTime) {
//       setState(() {
//         _endTime = picked;
//       });
//     }
//   }
  
//   DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
//     return DateTime(
//       date.year,
//       date.month,
//       date.day,
//       time.hour,
//       time.minute,
//     );
//   }
  
//   Future<void> _createEvent() async {
//     if (_formKey.currentState!.validate()) {
//       // Check if end date/time is after start date/time
//       final startDateTime = _combineDateAndTime(_startDate, _startTime);
//       final endDateTime = _combineDateAndTime(_endDate, _endTime);
      
//       if (endDateTime.isBefore(startDateTime)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('End time must be after start time'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
      
//       setState(() {
//         _isLoading = true;
//       });
      
//       try {
//         final eventService = Provider.of<EventService>(context, listen: false);
//         final authService = Provider.of<AuthService>(context, listen: false);
        
//         final userId = authService.currentUser?.uid ?? '';
        
//         await eventService.createEvent(
//           title: _titleController.text.trim(),
//           description: _descriptionController.text.trim(),
//           startDate: startDateTime,
//           endDate: endDateTime,
//           location: _locationController.text.trim(),
//           maxParticipants: int.parse(_maxParticipantsController.text.trim()),
//           createdBy: userId,
//         );
        
//         if (!mounted) return;
        
//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(AppConstants.successEventCreated),
//             backgroundColor: Colors.green,
//           ),
//         );
        
//         // Navigate back
//         Navigator.pop(context);
//       } catch (e) {
//         if (!mounted) return;
        
//         // Show error message
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to create event: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       } finally {
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dateFormat = DateFormat('MMM dd, yyyy');
    
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Create Event'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Title
//               const Text(
//                 'Event Details',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Event Title Field
//               const Text(
//                 'Event Title',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               CustomTextField(
//                 controller: _titleController,
//                 hintText: 'Enter event title',
//                 prefixIcon: Icons.event,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter event title';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
              
//               // Description Field
//               const Text(
//                 'Description',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               CustomTextField(
//                 controller: _descriptionController,
//                 hintText: 'Enter event description',
//                 prefixIcon: Icons.description,
//                 maxLines: 5,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter event description';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
              
//               // Location Field
//               const Text(
//                 'Location',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               CustomTextField(
//                 controller: _locationController,
//                 hintText: 'Enter event location',
//                 prefixIcon: Icons.location_on,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter event location';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
              
//               // Date and Time Section
//               const Text(
//                 'Date and Time',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Start Date and Time
//               Row(
//                 children: [
//                   Expanded(
//                     child: InkWell(
//                       onTap: () => _selectStartDate(context),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.calendar_today, size: 20),
//                             const SizedBox(width: 8),
//                             Text(dateFormat.format(_startDate)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () => _selectStartTime(context),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.access_time, size: 20),
//                             const SizedBox(width: 8),
//                             Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Start Date & Time',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 12,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // End Date and Time
//               Row(
//                 children: [
//                   Expanded(
//                     child: InkWell(
//                       onTap: () => _selectEndDate(context),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.calendar_today, size: 20),
//                             const SizedBox(width: 8),
//                             Text(dateFormat.format(_endDate)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () => _selectEndTime(context),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.access_time, size: 20),
//                             const SizedBox(width: 8),
//                             Text('${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}'),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'End Date & Time',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 12,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Max Participants Field
//               const Text(
//                 'Maximum Participants',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               CustomTextField(
//                 controller: _maxParticipantsController,
//                 hintText: 'Enter maximum number of participants',
//                 prefixIcon: Icons.people,
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter maximum participants';
//                   }
//                   if (int.tryParse(value) == null || int.parse(value) <= 0) {
//                     return 'Please enter a valid number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 32),
              
//               // Create Button
//               CustomButton(
//                 text: 'Create Event',
//                 isLoading: _isLoading,
//                 onPressed: _createEvent,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:nss_app/utils/constants.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';
// import 'package:nss_app/widgets/common/custom_text_field.dart';
// import 'package:intl/intl.dart';

// class CreateEventScreen extends StatefulWidget {
//   const CreateEventScreen({Key? key}) : super(key: key);

//   @override
//   State<CreateEventScreen> createState() => _CreateEventScreenState();
// }

// class _CreateEventScreenState extends State<CreateEventScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _locationController = TextEditingController();
//   final _maxParticipantsController = TextEditingController();
  
//   DateTime _startDate = DateTime.now().add(const Duration(days: 1));
//   TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
//   DateTime _endDate = DateTime.now().add(const Duration(days: 1));
//   TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);
  
//   bool _isLoading = false;
  
//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _locationController.dispose();
//     _maxParticipantsController.dispose();
//     super.dispose();
//   }
  
//   Future<void> _selectStartDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _startDate,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked != null && picked != _startDate) {
//       setState(() {
//         _startDate = picked;
//         // If end date is before start date, update it
//         if (_endDate.isBefore(_startDate)) {
//           _endDate = _startDate;
//         }
//       });
//     }
//   }
  
//   Future<void> _selectStartTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _startTime,
//     );
//     if (picked != null && picked != _startTime) {
//       setState(() {
//         _startTime = picked;
//       });
//     }
//   }
  
//   Future<void> _selectEndDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _endDate,
//       firstDate: _startDate,
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );
//     if (picked != null && picked != _endDate) {
//       setState(() {
//         _endDate = picked;
//       });
//     }
//   }
  
//   Future<void> _selectEndTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _endTime,
//     );
//     if (picked != null && picked != _endTime) {
//       setState(() {
//         _endTime = picked;
//       });
//     }
//   }
  
//   DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
//     return DateTime(
//       date.year,
//       date.month,
//       date.day,
//       time.hour,
//       time.minute,
//     );
//   }
  
//   void _createEvent() {
//     if (_formKey.currentState!.validate()) {
//       // Check if end date/time is after start date/time
//       final startDateTime = _combineDateAndTime(_startDate, _startTime);
//       final endDateTime = _combineDateAndTime(_endDate, _endTime);
      
//       if (endDateTime.isBefore(startDateTime)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('End time must be after start time'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
      
//       setState(() {
//         _isLoading = true;
//       });
      
//       // Simulate API call
//       Future.delayed(const Duration(seconds: 2), () {
//         setState(() {
//           _isLoading = false;
//         });
        
//         if (!mounted) return;
        
//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(AppConstants.successEventCreated),
//             backgroundColor: Colors.green,
//           ),
//         );
        
//         // Navigate back
//         Navigator.pop(context);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dateFormat = DateFormat('MMM dd, yyyy');
    
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Create Event'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Title
//               const Text(
//                 'Event Details',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Event Title Field
//               const Text(
//                 'Event Title',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               CustomTextField(
//                 controller: _titleController,
//                 hintText: 'Enter event title',
//                 prefixIcon: Icons.event,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter event title';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
              
//               // Description Field
//               const Text(
//                 'Description',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               CustomTextField(
//                 controller: _descriptionController,
//                 hintText: 'Enter event description',
//                 prefixIcon: Icons.description,
//                 maxLines: 5,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter event description';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
              
//               // Location Field
//               const Text(
//                 'Location',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               CustomTextField(
//                 controller: _locationController,
//                 hintText: 'Enter event location',
//                 prefixIcon: Icons.location_on,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter event location';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
              
//               // Date and Time Section
//               const Text(
//                 'Date and Time',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Start Date and Time
//               Row(
//                 children: [
//                   Expanded(
//                     child: InkWell(
//                       onTap: () => _selectStartDate(context),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.calendar_today, size: 20),
//                             const SizedBox(width: 8),
//                             Text(dateFormat.format(_startDate)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () => _selectStartTime(context),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.access_time, size: 20),
//                             const SizedBox(width: 8),
//                             Text('${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}'),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Start Date & Time',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 12,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // End Date and Time
//               Row(
//                 children: [
//                   Expanded(
//                     child: InkWell(
//                       onTap: () => _selectEndDate(context),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.calendar_today, size: 20),
//                             const SizedBox(width: 8),
//                             Text(dateFormat.format(_endDate)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () => _selectEndTime(context),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.access_time, size: 20),
//                             const SizedBox(width: 8),
//                             Text('${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}'),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'End Date & Time',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 12,
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Max Participants Field
//               const Text(
//                 'Maximum Participants',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               CustomTextField(
//                 controller: _maxParticipantsController,
//                 hintText: 'Enter maximum number of participants',
//                 prefixIcon: Icons.people,
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter maximum participants';
//                   }
//                   if (int.tryParse(value) == null || int.parse(value) <= 0) {
//                     return 'Please enter a valid number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 32),
              
//               // Create Button
//               CustomButton(
//                 text: 'Create Event',
//                 isLoading: _isLoading,
//                 onPressed: _createEvent,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }