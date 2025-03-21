import 'package:flutter/material.dart';
import 'package:nss_app/models/user_model.dart';

class AttendanceMarker extends StatefulWidget {
  final UserModel volunteer;
  final bool initialValue;
  final Function(bool) onChanged;

  const AttendanceMarker({
    Key? key,
    required this.volunteer,
    required this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<AttendanceMarker> createState() => _AttendanceMarkerState();
}

class _AttendanceMarkerState extends State<AttendanceMarker> {
  late bool _isPresent;

  @override
  void initState() {
    super.initState();
    _isPresent = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant AttendanceMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        _isPresent = widget.initialValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Volunteer Avatar
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                widget.volunteer.name.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Volunteer Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.volunteer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${widget.volunteer.volunteerId}',
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            
            // Attendance Toggle
            Row(
              children: [
                Text(
                  _isPresent ? 'Present' : 'Absent',
                  style: TextStyle(
                    color: _isPresent ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _isPresent,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    setState(() {
                      _isPresent = value;
                    });
                    widget.onChanged(value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}