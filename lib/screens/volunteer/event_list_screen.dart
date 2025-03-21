import 'package:flutter/material.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:nss_app/widgets/common/event_card.dart';
import 'package:provider/provider.dart';
import 'package:nss_app/services/event_service.dart';
import 'package:nss_app/services/auth_service.dart';

class VolunteerEventListScreen extends StatefulWidget {
  const VolunteerEventListScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerEventListScreen> createState() => _VolunteerEventListScreenState();
}

class _VolunteerEventListScreenState extends State<VolunteerEventListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';
  
  List<EventModel> _allEvents = [];
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserId();
    _loadEvents();
  }
  
  void _loadUserId() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _userId = authService.currentUser?.uid ?? '';
    
    // If no authenticated user, use mock data for now
    if (_userId.isEmpty) {
      _userId = UserModel.getMockVolunteers().first.id;
    }
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load events: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Registered'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorMessage()
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUpcomingEventsTab(),
                      _buildRegisteredEventsTab(),
                      _buildPastEventsTab(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
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
    );
  }

  Widget _buildUpcomingEventsTab() {
    final upcomingEvents = _allEvents
        .where((event) => event.isUpcoming)
        .toList();

    return _buildEventsList(
      upcomingEvents,
      isRegisteredList: upcomingEvents
          .map((event) => event.registeredParticipants.contains(_userId))
          .toList(),
      emptyMessage: 'No upcoming events available',
    );
  }

  Widget _buildRegisteredEventsTab() {
    final registeredEvents = _allEvents
        .where((event) => 
            event.registeredParticipants.contains(_userId) && 
            (event.isUpcoming || event.isOngoing))
        .toList();

    return _buildEventsList(
      registeredEvents,
      isRegisteredList: List.filled(registeredEvents.length, true),
      isOngoingList: registeredEvents.map((event) => event.isOngoing).toList(),
      emptyMessage: 'You haven\'t registered for any events yet',
    );
  }

  Widget _buildPastEventsTab() {
    final pastEvents = _allEvents
        .where((event) => event.isPast)
        .toList();

    return _buildEventsList(
      pastEvents,
      isPastList: List.filled(pastEvents.length, true),
      emptyMessage: 'No past events available',
    );
  }

  Widget _buildEventsList(
    List<EventModel> events, {
    List<bool>? isRegisteredList,
    List<bool>? isOngoingList,
    List<bool>? isPastList,
    required String emptyMessage,
  }) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return EventCard(
          event: events[index],
          isRegistered: isRegisteredList?[index] ?? false,
          isOngoing: isOngoingList?[index] ?? false,
          isPast: isPastList?[index] ?? false,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/volunteer/event-details',
              arguments: events[index],
            ).then((_) => _loadEvents()); // Reload events when returning from details
          },
        );
      },
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:nss_app/widgets/common/event_card.dart';

// class VolunteerEventListScreen extends StatefulWidget {
//   const VolunteerEventListScreen({Key? key}) : super(key: key);

//   @override
//   State<VolunteerEventListScreen> createState() => _VolunteerEventListScreenState();
// }

// class _VolunteerEventListScreenState extends State<VolunteerEventListScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
  
//   // Mock user for UI development
//   final UserModel _currentUser = UserModel.getMockVolunteers().first;
  
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }
  
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Events'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Upcoming'),
//             Tab(text: 'Registered'),
//             Tab(text: 'Past'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildUpcomingEventsTab(),
//           _buildRegisteredEventsTab(),
//           _buildPastEventsTab(),
//         ],
//       ),
//     );
//   }

//   Widget _buildUpcomingEventsTab() {
//     final upcomingEvents = EventModel.getMockEvents()
//         .where((event) => event.isUpcoming)
//         .toList();

//     return _buildEventsList(
//       upcomingEvents,
//       isRegisteredList: upcomingEvents
//           .map((event) => event.registeredParticipants.contains(_currentUser.id))
//           .toList(),
//       emptyMessage: 'No upcoming events available',
//     );
//   }

//   Widget _buildRegisteredEventsTab() {
//     final registeredEvents = EventModel.getMockEvents()
//         .where((event) => 
//             event.registeredParticipants.contains(_currentUser.id) && 
//             (event.isUpcoming || event.isOngoing))
//         .toList();

//     return _buildEventsList(
//       registeredEvents,
//       isRegisteredList: List.filled(registeredEvents.length, true),
//       isOngoingList: registeredEvents.map((event) => event.isOngoing).toList(),
//       emptyMessage: 'You haven\'t registered for any events yet',
//     );
//   }

//   Widget _buildPastEventsTab() {
//     final pastEvents = EventModel.getMockEvents()
//         .where((event) => event.isPast)
//         .toList();

//     return _buildEventsList(
//       pastEvents,
//       isPastList: List.filled(pastEvents.length, true),
//       emptyMessage: 'No past events available',
//     );
//   }

//   Widget _buildEventsList(
//     List<EventModel> events, {
//     List<bool>? isRegisteredList,
//     List<bool>? isOngoingList,
//     List<bool>? isPastList,
//     required String emptyMessage,
//   }) {
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
//         return EventCard(
//           event: events[index],
//           isRegistered: isRegisteredList?[index] ?? false,
//           isOngoing: isOngoingList?[index] ?? false,
//           isPast: isPastList?[index] ?? false,
//           onTap: () {
//             Navigator.pushNamed(
//               context,
//               '/volunteer/event-details',
//               arguments: events[index],
//             );
//           },
//         );
//       },
//     );
//   }
// }