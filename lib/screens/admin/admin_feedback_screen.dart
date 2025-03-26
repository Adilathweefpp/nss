import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nss_app/services/feedback_service.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({Key? key}) : super(key: key);

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _feedbackList = [];
  String _errorMessage = '';
  String _searchQuery = '';
  String _filterByEvent = '';
  
  // Sorting options
  String _sortBy = 'submittedAt';
  bool _sortAscending = false;
  
  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }
  
  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Use the feedback service to get all feedback
      final feedbackService = Provider.of<FeedbackService>(context, listen: false);
      final feedbackItems = await feedbackService.getAllFeedback(
        sortBy: _sortBy,
        ascending: _sortAscending,
      );
      
      if (mounted) {
        setState(() {
          _feedbackList = feedbackItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading feedback: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load feedback: ${e.toString()}';
        });
      }
    }
  }
  
  // Filter feedback based on search query and event filter
  List<Map<String, dynamic>> _getFilteredFeedback() {
    if (_searchQuery.isEmpty && _filterByEvent.isEmpty) {
      return _feedbackList;
    }
    
    return _feedbackList.where((feedback) {
      // Search query filter
      final matchesSearch = _searchQuery.isEmpty ||
          feedback['volunteerName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          feedback['eventName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          feedback['feedback'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Event filter
      final matchesEvent = _filterByEvent.isEmpty ||
          feedback['eventName'] == _filterByEvent;
      
      return matchesSearch && matchesEvent;
    }).toList();
  }
  
  // Get unique event names for filter dropdown
  List<String> _getUniqueEventNames() {
    final eventNames = _feedbackList.map((feedback) => feedback['eventName'].toString()).toSet().toList();
    eventNames.sort();
    return eventNames;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Feedback'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedback,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty 
              ? _buildErrorView()
              : _buildFeedbackList(),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFeedback,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeedbackList() {
    final filteredFeedback = _getFilteredFeedback();
    final uniqueEventNames = _getUniqueEventNames();
    
    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search feedback, volunteer, or event...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Filters Row
              Row(
                children: [
                  // Event Filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Filter by Event',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      ),
                      value: _filterByEvent.isEmpty ? null : _filterByEvent,
                      hint: const Text('All Events'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('All Events'),
                        ),
                        ...uniqueEventNames.map((eventName) => DropdownMenuItem<String>(
                          value: eventName,
                          child: Text(eventName),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterByEvent = value ?? '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Sort Button
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sort by',
                    onSelected: (value) {
                      setState(() {
                        if (_sortBy == value) {
                          // Toggle sort direction if the same field is selected
                          _sortAscending = !_sortAscending;
                        } else {
                          _sortBy = value;
                          _sortAscending = false; // Default to descending for new field
                        }
                      });
                      _loadFeedback();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'submittedAt',
                        child: Text('Date Submitted'),
                      ),
                      const PopupMenuItem(
                        value: 'eventDate',
                        child: Text('Event Date'),
                      ),
                      const PopupMenuItem(
                        value: 'volunteerName',
                        child: Text('Volunteer Name'),
                      ),
                      const PopupMenuItem(
                        value: 'eventName',
                        child: Text('Event Name'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Feedback Count and Sort Indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredFeedback.length} feedback${filteredFeedback.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Sorted by: ${_getSortByLabel()} (${_sortAscending ? 'Asc' : 'Desc'})',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        
        // Feedback List
        Expanded(
          child: filteredFeedback.isEmpty
              ? const Center(
                  child: Text(
                    'No feedback found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredFeedback.length,
                  itemBuilder: (context, index) {
                    final feedback = filteredFeedback[index];
                    return _buildFeedbackCard(feedback);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Name & Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback['eventName'] ?? 'Unknown Event',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (feedback['eventDate'] != null)
                        Text(
                          dateFormat.format(feedback['eventDate']),
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                // Submission Time
                if (feedback['submittedAt'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dateFormat.format(feedback['submittedAt']),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        timeFormat.format(feedback['submittedAt']),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(),
            
            // Volunteer Info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Volunteer: ${feedback['volunteerName']} ', //(ID: ${feedback['volunteerId']}) if error occurs, uncomment it
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Feedback Content
            const Text(
              'Feedback:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                feedback['feedback'] ?? 'No feedback provided',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getSortByLabel() {
    switch (_sortBy) {
      case 'submittedAt':
        return 'Date Submitted';
      case 'eventDate':
        return 'Event Date';
      case 'volunteerName':
        return 'Volunteer Name';
      case 'eventName':
        return 'Event Name';
      default:
        return 'Date Submitted';
    }
  }
}