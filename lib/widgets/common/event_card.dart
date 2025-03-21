import 'package:flutter/material.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final bool isRegistered;
  final bool isOngoing;
  final bool isPast;
  final VoidCallback onTap;

  const EventCard({
    Key? key,
    required this.event,
    this.isRegistered = false,
    this.isOngoing = false,
    this.isPast = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar at the top
            Container(
              color: _getStatusColor(),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Date and Time
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${dateFormat.format(event.startDate)} at ${timeFormat.format(event.startDate)}',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.location,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Participants
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${event.registeredParticipants.length}/${event.maxParticipants} participants',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  
                  // Registration button or status
                  if (!isPast) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isRegistered)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Registered',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isOngoing && !isRegistered)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Ongoing',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!isRegistered && !isOngoing)
                          Builder(
                            builder: (context) => ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Register'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (isOngoing) {
      return Colors.orange;
    } else if (isPast) {
      return Colors.grey;
    } else if (isRegistered) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    if (isOngoing) {
      return Icons.access_time;
    } else if (isPast) {
      return Icons.event_busy;
    } else if (isRegistered) {
      return Icons.check_circle;
    } else {
      return Icons.event_available;
    }
  }

  String _getStatusText() {
    if (isOngoing) {
      return 'Ongoing';
    } else if (isPast) {
      return 'Completed';
    } else if (isRegistered) {
      return 'Registered';
    } else {
      return 'Upcoming';
    }
  }
}



// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:intl/intl.dart';

// class EventCard extends StatelessWidget {
//   final EventModel event;
//   final bool isRegistered;
//   final bool isOngoing;
//   final bool isPast;
//   final VoidCallback onTap;

//   const EventCard({
//     Key? key,
//     required this.event,
//     this.isRegistered = false,
//     this.isOngoing = false,
//     this.isPast = false,
//     required this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final dateFormat = DateFormat('MMM dd, yyyy');
//     final timeFormat = DateFormat('hh:mm a');

//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       clipBehavior: Clip.antiAlias,
//       child: InkWell(
//         onTap: onTap,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Status bar at the top
//             Container(
//               color: _getStatusColor(),
//               padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     _getStatusIcon(),
//                     size: 16,
//                     color: Colors.white,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     _getStatusText(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Title
//                   Text(
//                     event.title,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
                  
//                   // Date and Time
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.calendar_today,
//                         size: 16,
//                         color: Colors.grey,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         '${dateFormat.format(event.startDate)} at ${timeFormat.format(event.startDate)}',
//                         style: const TextStyle(
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
                  
//                   // Location
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.location_on,
//                         size: 16,
//                         color: Colors.grey,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         event.location,
//                         style: const TextStyle(
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
                  
//                   // Participants
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.people,
//                         size: 16,
//                         color: Colors.grey,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         '${event.approvedParticipants.length}/${event.maxParticipants} participants',
//                         style: const TextStyle(
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),
                  
//                   // Registration button or status
//                   if (!isPast) ...[
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         if (isRegistered)
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.green.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(4),
//                               border: Border.all(color: Colors.green),
//                             ),
//                             child: const Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   Icons.check_circle,
//                                   color: Colors.green,
//                                   size: 16,
//                                 ),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   'Registered',
//                                   style: TextStyle(
//                                     color: Colors.green,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         if (isOngoing && !isRegistered)
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.orange.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(4),
//                               border: Border.all(color: Colors.orange),
//                             ),
//                             child: const Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   Icons.access_time,
//                                   color: Colors.orange,
//                                   size: 16,
//                                 ),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   'Ongoing',
//                                   style: TextStyle(
//                                     color: Colors.orange,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         if (!isRegistered && !isOngoing)
//                           Builder(
//                             builder: (context) => ElevatedButton(
//                               onPressed: () {},
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Theme.of(context).primaryColor,
//                                 foregroundColor: Colors.white,
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                   vertical: 8,
//                                 ),
//                               ),
//                               child: const Text('Register'),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor() {
//     if (isOngoing) {
//       return Colors.orange;
//     } else if (isPast) {
//       return Colors.grey;
//     } else if (isRegistered) {
//       return Colors.green;
//     } else {
//       return Colors.blue;
//     }
//   }

//   IconData _getStatusIcon() {
//     if (isOngoing) {
//       return Icons.access_time;
//     } else if (isPast) {
//       return Icons.event_busy;
//     } else if (isRegistered) {
//       return Icons.check_circle;
//     } else {
//       return Icons.event_available;
//     }
//   }

//   String _getStatusText() {
//     if (isOngoing) {
//       return 'Ongoing';
//     } else if (isPast) {
//       return 'Completed';
//     } else if (isRegistered) {
//       return 'Registered';
//     } else {
//       return 'Upcoming';
//     }
//   }
// }