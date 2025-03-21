import 'package:flutter/material.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:nss_app/widgets/common/custom_button.dart';

class EventRegistrationForm extends StatefulWidget {
  final EventModel event;
  final UserModel volunteer;
  final VoidCallback onSuccess;

  const EventRegistrationForm({
    Key? key,
    required this.event,
    required this.volunteer,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<EventRegistrationForm> createState() => _EventRegistrationFormState();
}

class _EventRegistrationFormState extends State<EventRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _agreeToTerms = ValueNotifier<bool>(false);
  bool _isRegistering = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _agreeToTerms.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_agreeToTerms.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isRegistering = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isRegistering = false;
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have successfully registered for this event'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Details
          Text(
            widget.event.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildEventDetail(Icons.calendar_today, 'Date', _formatDate(widget.event.startDate)),
          _buildEventDetail(Icons.access_time, 'Time', _formatTime(widget.event.startDate)),
          _buildEventDetail(Icons.location_on, 'Location', widget.event.location),
          _buildEventDetail(
            Icons.people,
            'Available Slots',
            '${widget.event.maxParticipants - widget.event.registeredParticipants.length} out of ${widget.event.maxParticipants}',
          ),
          const SizedBox(height: 24),

          // Registration Form
          const Text(
            'Reason for Participation',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Write why you want to participate in this event...',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your reason for participation';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Terms and Conditions
          ValueListenableBuilder<bool>(
            valueListenable: _agreeToTerms,
            builder: (context, value, child) {
              return CheckboxListTile(
                title: const Text(
                  'I agree to participate in this event and follow all the rules and regulations.',
                  style: TextStyle(fontSize: 14),
                ),
                value: value,
                onChanged: (newValue) {
                  _agreeToTerms.value = newValue ?? false;
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
          const SizedBox(height: 24),

          // Register Button
          CustomButton(
            text: 'Register for Event',
            isLoading: _isRegistering,
            onPressed: _register,
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}




// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:nss_app/utils/constants.dart';
// import 'package:nss_app/widgets/common/custom_button.dart';

// class EventRegistrationForm extends StatefulWidget {
//   final EventModel event;
//   final UserModel volunteer;
//   final VoidCallback onSuccess;

//   const EventRegistrationForm({
//     Key? key,
//     required this.event,
//     required this.volunteer,
//     required this.onSuccess,
//   }) : super(key: key);

//   @override
//   State<EventRegistrationForm> createState() => _EventRegistrationFormState();
// }

// class _EventRegistrationFormState extends State<EventRegistrationForm> {
//   final _formKey = GlobalKey<FormState>();
//   final _reasonController = TextEditingController();
//   final _agreeToTerms = ValueNotifier<bool>(false);
//   bool _isRegistering = false;

//   @override
//   void dispose() {
//     _reasonController.dispose();
//     _agreeToTerms.dispose();
//     super.dispose();
//   }

//   Future<void> _register() async {
//     if (!_agreeToTerms.value) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please agree to the terms and conditions'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isRegistering = true;
//       });

//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 2));

//       setState(() {
//         _isRegistering = false;
//       });

//       if (!mounted) return;

//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(AppConstants.successParticipationRequested),
//           backgroundColor: Colors.green,
//         ),
//       );

//       widget.onSuccess();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Event Details
//           Text(
//             widget.event.title,
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           _buildEventDetail(Icons.calendar_today, 'Date', _formatDate(widget.event.startDate)),
//           _buildEventDetail(Icons.access_time, 'Time', _formatTime(widget.event.startDate)),
//           _buildEventDetail(Icons.location_on, 'Location', widget.event.location),
//           _buildEventDetail(
//             Icons.people,
//             'Available Slots',
//             '${widget.event.maxParticipants - widget.event.approvedParticipants.length} out of ${widget.event.maxParticipants}',
//           ),
//           const SizedBox(height: 24),

//           // Registration Form
//           const Text(
//             'Reason for Participation',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 8),
//           TextFormField(
//             controller: _reasonController,
//             maxLines: 3,
//             decoration: const InputDecoration(
//               hintText: 'Write why you want to participate in this event...',
//               border: OutlineInputBorder(),
//             ),
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter your reason for participation';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),

//           // Terms and Conditions
//           ValueListenableBuilder<bool>(
//             valueListenable: _agreeToTerms,
//             builder: (context, value, child) {
//               return CheckboxListTile(
//                 title: const Text(
//                   'I agree to participate in this event and follow all the rules and regulations.',
//                   style: TextStyle(fontSize: 14),
//                 ),
//                 value: value,
//                 onChanged: (newValue) {
//                   _agreeToTerms.value = newValue ?? false;
//                 },
//                 controlAffinity: ListTileControlAffinity.leading,
//                 contentPadding: EdgeInsets.zero,
//               );
//             },
//           ),
//           const SizedBox(height: 24),

//           // Register Button
//           CustomButton(
//             text: 'Register for Event',
//             isLoading: _isRegistering,
//             onPressed: _register,
//           ),
//           const SizedBox(height: 8),
//           const Center(
//             child: Text(
//               'Note: Your registration will be reviewed by the admin',
//               style: TextStyle(
//                 color: Colors.grey,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEventDetail(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             size: 16,
//             color: Colors.grey,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             '$label: ',
//             style: const TextStyle(
//               color: Colors.grey,
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }

//   String _formatTime(DateTime date) {
//     return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }
// }