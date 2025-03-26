import 'package:flutter/material.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/services/event_service.dart';
import 'package:nss_app/services/point_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class VolunteerPointsDetailsScreen extends StatefulWidget {
  const VolunteerPointsDetailsScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerPointsDetailsScreen> createState() => _VolunteerPointsDetailsScreenState();
}

class _VolunteerPointsDetailsScreenState extends State<VolunteerPointsDetailsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, int> _pointsMap = {};
  Map<String, EventModel> _eventsMap = {};
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get volunteer ID from arguments
    final volunteerId = ModalRoute.of(context)?.settings.arguments as String;
    _loadPointsData(volunteerId);
  }
  
  Future<void> _loadPointsData(String volunteerId) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Get points for this volunteer
      final pointService = Provider.of<PointService>(context, listen: false);
      final pointsMap = await pointService.getVolunteerPoints(volunteerId);
      
      // Get events data for all events where the volunteer has received points
      final eventService = Provider.of<EventService>(context, listen: false);
      Map<String, EventModel> eventsMap = {};
      
      for (String eventId in pointsMap.keys) {
        final event = await eventService.getEventById(eventId);
        if (event != null) {
          eventsMap[eventId] = event;
        }
      }
      
      if (!mounted) return;
      
      setState(() {
        _pointsMap = pointsMap;
        _eventsMap = eventsMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to load points data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points Details'),
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
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final volunteerId = ModalRoute.of(context)?.settings.arguments as String;
                          _loadPointsData(volunteerId);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pointsMap.isEmpty
                  ? const Center(
                      child: Text(
                        'No points earned yet.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : Column(
                      children: [
                        // Total points summary
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.stars,
                                    size: 48,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Points',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        _pointsMap.values.fold(0, (sum, points) => sum + points).toString(),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Points breakdown title
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Points Breakdown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // List of events and points
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _pointsMap.length,
                            itemBuilder: (context, index) {
                              final eventId = _pointsMap.keys.elementAt(index);
                              final points = _pointsMap[eventId] ?? 0;
                              final event = _eventsMap[eventId];
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: Text(
                                      points.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    event?.title ?? 'Unknown Event',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: event != null
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text('Date: ${dateFormat.format(event.startDate)}'),
                                            Text('Location: ${event.location}'),
                                          ],
                                        )
                                      : const Text('Event details not available'),
                                  isThreeLine: true,
                                  onTap: event != null
                                      ? () {
                                          Navigator.pushNamed(
                                            context,
                                            '/volunteer/event-details',
                                            arguments: event,
                                          );
                                        }
                                      : null,
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