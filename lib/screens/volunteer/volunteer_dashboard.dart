import 'package:flutter/material.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:nss_app/widgets/common/event_card.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({Key? key}) : super(key: key);

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  int _selectedIndex = 0;
  final List<String> _titles = ['Dashboard', 'Events', 'Attendance', 'Profile'];

  // Mock user for UI development - without using it in initializers
  late final UserModel _currentUser = UserModel.getMockVolunteers().first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Show notifications
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildDashboardTab()
          : Container(), // We'll use navigation for other tabs
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      return; // Don't navigate if already on the selected tab
    }

    if (index == 0) {
      // Dashboard tab
      setState(() {
        _selectedIndex = index;
      });
    } else if (index == 1) {
      // Events tab
      Navigator.pushNamed(context, '/volunteer/events');
    } else if (index == 2) {
      // Attendance tab
      Navigator.pushNamed(context, '/volunteer/attendance');
    } else if (index == 3) {
      // Profile tab
      Navigator.pushNamed(context, '/volunteer/profile');
    }
  }

  // Dashboard Tab Content
  Widget _buildDashboardTab() {
    // Get mock events for UI development
    final List<EventModel> upcomingEvents =
        EventModel.getMockEvents().where((event) => event.isUpcoming).toList();

    final List<EventModel> ongoingEvents =
        EventModel.getMockEvents().where((event) => event.isOngoing).toList();

    final List<EventModel> registeredEvents = EventModel.getMockEvents()
        .where((event) =>
            event.registeredParticipants.contains(_currentUser.id) &&
            event.isUpcoming)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        // Simulate refreshing data
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          // Refresh data
        });
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        _currentUser.name.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${_currentUser.name}!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Volunteer ID: ${_currentUser.volunteerId}',
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

            // Quick Stats
            Row(
              children: [
                Builder(builder: (context) {
                  return _buildStatCard(
                    context,
                    icon: Icons.event_available,
                    value: registeredEvents.length.toString(),
                    label: 'Registered Events',
                  );
                }),
                const SizedBox(width: 16),
                Builder(builder: (context) {
                  return _buildStatCard(
                    context,
                    icon: Icons.how_to_reg,
                    value: '100%',
                    label: 'Attendance',
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),

            // Ongoing Events Section
            if (ongoingEvents.isNotEmpty) ...[
              const Text(
                'Ongoing Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...ongoingEvents.map((event) => EventCard(
                    event: event,
                    isOngoing: true,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/volunteer/event-details',
                        arguments: event,
                      );
                    },
                  )),
              const SizedBox(height: 24),
            ],

            // Upcoming Events Section
            if (upcomingEvents.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/volunteer/events');
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...upcomingEvents.take(3).map((event) => EventCard(
                    event: event,
                    isRegistered:
                        event.registeredParticipants.contains(_currentUser.id),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/volunteer/event-details',
                        arguments: event,
                      );
                    },
                  )),
            ],

            // No events message
            if (upcomingEvents.isEmpty && ongoingEvents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No events scheduled at the moment',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
