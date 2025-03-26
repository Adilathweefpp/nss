import 'package:flutter/material.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:nss_app/services/event_service.dart';
import 'package:nss_app/services/point_service.dart';
import 'package:provider/provider.dart';
import 'package:nss_app/widgets/common/custom_button.dart';

class MarkPointsScreen extends StatefulWidget {
  const MarkPointsScreen({Key? key}) : super(key: key);

  @override
  State<MarkPointsScreen> createState() => _MarkPointsScreenState();
}

class _MarkPointsScreenState extends State<MarkPointsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  
  // Lists to store volunteers and their points
  List<UserModel> _participants = [];
  Map<String, int> _pointsMap = {};
  Map<String, TextEditingController> _controllers = {};
  
  late EventModel _event;
  bool _initialized = false;
  
  @override
  void initState() {
    super.initState();
    // We'll initialize data in didChangeDependencies
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Only initialize once
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is EventModel) {
        _event = args;
        _initialized = true;
        _loadParticipants();
      }
    }
  }
  
  Future<void> _loadParticipants() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Get event participants
      final eventService = Provider.of<EventService>(context, listen: false);
      final participants = await eventService.getRegisteredUsers(_event);
      
      // Get points for these participants
      final pointService = Provider.of<PointService>(context, listen: false);
      
      final participantIds = participants.map((p) => p.id).toList();
      Map<String, int> pointsMap = {};
      
      if (participantIds.isNotEmpty) {
        pointsMap = await pointService.getPointsForEvent(
          _event.id, 
          participantIds
        );
      }
      
      // Create controllers for each participant
      Map<String, TextEditingController> controllers = {};
      for (var participant in participants) {
        controllers[participant.id] = TextEditingController(
          text: (pointsMap[participant.id] ?? 0).toString()
        );
      }
      
      if (!mounted) return;
      
      setState(() {
        _participants = participants;
        _pointsMap = pointsMap;
        _controllers = controllers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to load participants: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  void _handleSavePoints() {
    if (!_isSaving && !_isLoading) {
      _savePoints();
    }
  }
  
  Future<void> _savePoints() async {
    if (_participants.isEmpty || !mounted) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Prepare batch update data
      Map<String, Map<String, int>> batchData = {};
      
      for (var participant in _participants) {
        final controller = _controllers[participant.id];
        if (controller != null) {
          final points = int.tryParse(controller.text) ?? 0;
          
          if (!batchData.containsKey(participant.id)) {
            batchData[participant.id] = {};
          }
          
          batchData[participant.id]![_event.id] = points;
        }
      }
      
      // Use point service to update all points at once
      final pointService = Provider.of<PointService>(context, listen: false);
      await pointService.updatePointsInBatch(batchData);
      
      if (!mounted) return;
      
      // Show success message and return to previous screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Points updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // We need to set _isSaving = false before popping to avoid assertion errors
      setState(() {
        _isSaving = false;
      });
      
      // Only pop navigator if we're still mounted
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Only update state if we're still mounted
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save points: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safe guard in case the event wasn't properly initialized
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: Text('Error: No event data provided'),
        ),
      );
    }
    
    return WillPopScope(
      onWillPop: () async {
        // Prevent popping during save operation
        return !_isSaving;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mark Points - ${_event.title}'),
        ),
        body: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Participants list
                  Expanded(
                    child: _isLoading
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
                                      onPressed: _loadParticipants,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : _participants.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No participants found for this event.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _participants.length,
                                    itemBuilder: (context, index) {
                                      final participant = _participants[index];
                                      final controller = _controllers[participant.id];
                                      
                                      if (controller == null) {
                                        return const SizedBox.shrink();
                                      }
                                      
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              // Volunteer info with avatar
                                              Expanded(
                                                flex: 3,
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundColor: Theme.of(context).primaryColor,
                                                      child: Text(
                                                        participant.name.isNotEmpty ? participant.name.substring(0, 1).toUpperCase() : '?',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            participant.name,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            participant.volunteerId,
                                                            style: const TextStyle(
                                                              color: Colors.grey,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // Points input
                                              Expanded(
                                                flex: 2,
                                                child: TextField(
                                                  controller: controller,
                                                  keyboardType: TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                    border: OutlineInputBorder(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            text: 'Save Points',
            onPressed: _handleSavePoints,
            isLoading: _isSaving || _isLoading,
          ),
        ),
      ),
    );
  }
}