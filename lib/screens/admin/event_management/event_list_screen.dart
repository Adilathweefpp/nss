import 'package:flutter/material.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nss_app/services/event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEventListScreen extends StatefulWidget {
  const AdminEventListScreen({Key? key}) : super(key: key);

  @override
  State<AdminEventListScreen> createState() => _AdminEventListScreenState();
}

class _AdminEventListScreenState extends State<AdminEventListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadEvents();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final eventService = Provider.of<EventService>(context, listen: false);
      final events = await eventService.getAllEvents();
      
      setState(() {
        _allEvents = events;
        _filteredEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load events: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        return event.title.toLowerCase().contains(query) ||
            event.location.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
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
                        onPressed: _loadEvents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        ),
                      ),
                    ),
                    
                    // Event Tabs
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Upcoming Events Tab
                          _buildEventList(
                            _filteredEvents.where((event) => event.isUpcoming).toList(),
                            'No upcoming events found',
                          ),
                          
                          // Ongoing Events Tab
                          _buildEventList(
                            _filteredEvents.where((event) => event.isOngoing).toList(),
                            'No ongoing events found',
                          ),
                          
                          // Past Events Tab
                          _buildEventList(
                            _filteredEvents.where((event) => event.isPast).toList(),
                            'No past events found',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/admin/create-event').then((_) => _loadEvents());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventList(List<EventModel> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final dateFormat = DateFormat('MMM dd, yyyy');
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                event.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.numbers, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Event ID: ${event.id}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(dateFormat.format(event.startDate)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(event.location),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('events').doc(event.id).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            final registeredCount = data != null 
                                ? (data['registeredParticipants'] as List<dynamic>?)?.length ?? 0 
                                : event.registeredParticipants.length;
                                
                            return Text('$registeredCount/${event.maxParticipants} participants');
                          }
                          return Text('${event.registeredParticipants.length}/${event.maxParticipants} participants');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusChip(event),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // Navigate to edit event
                          Navigator.pushNamed(
                            context, 
                            '/admin/edit-event',
                            arguments: event,
                          ).then((result) {
                            // Reload events after editing (if successful)
                            if (result == true) {
                              _loadEvents();
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmation(context, event);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                // Navigate to event details
                Navigator.pushNamed(
                  context, 
                  '/admin/event-details',
                  arguments: event,
                ).then((_) => _loadEvents());
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStatusChip(EventModel event) {
    Color color;
    String text;
    
    if (event.isPast) {
      color = Colors.grey;
      text = 'Completed';
    } else if (event.isOngoing) {
      color = Colors.orange;
      text = 'Ongoing';
    } else {
      color = Colors.green;
      text = 'Upcoming';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
              Navigator.pop(context);
              
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deleting event...'),
                  duration: Duration(seconds: 1),
                ),
              );
              
              try {
                final eventService = Provider.of<EventService>(context, listen: false);
                await eventService.deleteEvent(event.id);
                
                // Reload events after deletion
                _loadEvents();
                
                if (!mounted) return;
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Event deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                
                // Show error message
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
}

// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:intl/intl.dart';

// class AdminEventListScreen extends StatefulWidget {
//   const AdminEventListScreen({Key? key}) : super(key: key);

//   @override
//   State<AdminEventListScreen> createState() => _AdminEventListScreenState();
// }

// class _AdminEventListScreenState extends State<AdminEventListScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final TextEditingController _searchController = TextEditingController();
//   List<EventModel> _filteredEvents = [];
  
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _filteredEvents = EventModel.getMockEvents();
    
//     _searchController.addListener(_onSearchChanged);
//   }
  
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _onSearchChanged() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredEvents = EventModel.getMockEvents().where((event) {
//         return event.title.toLowerCase().contains(query) ||
//             event.location.toLowerCase().contains(query);
//       }).toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Event Management'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Upcoming'),
//             Tab(text: 'Ongoing'),
//             Tab(text: 'Past'),
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           // Search Bar
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search events...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
//               ),
//             ),
//           ),
          
//           // Event Tabs
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 // Upcoming Events Tab
//                 _buildEventList(
//                   _filteredEvents.where((event) => event.isUpcoming).toList(),
//                   'No upcoming events found',
//                 ),
                
//                 // Ongoing Events Tab
//                 _buildEventList(
//                   _filteredEvents.where((event) => event.isOngoing).toList(),
//                   'No ongoing events found',
//                 ),
                
//                 // Past Events Tab
//                 _buildEventList(
//                   _filteredEvents.where((event) => event.isPast).toList(),
//                   'No past events found',
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.pushNamed(context, '/admin/create-event');
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   Widget _buildEventList(List<EventModel> events, String emptyMessage) {
//     if (events.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.event_busy,
//               size: 64,
//               color: Colors.grey,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               emptyMessage,
//               style: const TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: events.length,
//       itemBuilder: (context, index) {
//         final event = events[index];
//         final dateFormat = DateFormat('MMM dd, yyyy');
        
//         return Card(
//           margin: const EdgeInsets.only(bottom: 12),
//           child: ListTile(
//             contentPadding: const EdgeInsets.all(16),
//             title: Text(
//               event.title,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
//                     const SizedBox(width: 8),
//                     Text(dateFormat.format(event.startDate)),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.location_on, size: 16, color: Colors.grey),
//                     const SizedBox(width: 8),
//                     Text(event.location),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.people, size: 16, color: Colors.grey),
//                     const SizedBox(width: 8),
//                     Text('${event.approvedParticipants.length}/${event.maxParticipants} participants'),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     _buildStatusChip(event),
//                     const Spacer(),
//                     IconButton(
//                       icon: const Icon(Icons.edit, color: Colors.blue),
//                       onPressed: () {
//                         // Navigate to edit event
//                       },
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       onPressed: () {
//                         _showDeleteConfirmation(context, event);
//                       },
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             isThreeLine: true,
//             onTap: () {
//               // Navigate to event details
//               Navigator.pushNamed(
//                 context, 
//                 '/admin/event-details',
//                 arguments: event,
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
  
//   Widget _buildStatusChip(EventModel event) {
//     Color color;
//     String text;
    
//     if (event.isPast) {
//       color = Colors.grey;
//       text = 'Completed';
//     } else if (event.isOngoing) {
//       color = Colors.orange;
//       text = 'Ongoing';
//     } else {
//       color = Colors.green;
//       text = 'Upcoming';
//     }
    
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: color),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: color,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
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
//             onPressed: () {
//               // Delete event
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Event deleted successfully'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
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
// }