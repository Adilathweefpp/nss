import 'package:flutter/material.dart';
import 'package:nss_app/models/user_model.dart';
import 'package:nss_app/services/ApprovalService.dart';
import 'package:nss_app/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({Key? key}) : super(key: key);

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  List<UserModel> _pendingVolunteers = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String _error = '';
  Map<String, dynamic> _statistics = {
    'pending': 0,
    'approved': 0,
    'rejected': 0,
    'total': 0,
  };
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final approvalService = Provider.of<ApprovalService>(context, listen: false);
      
      // Fetch pending volunteers
      final volunteers = await approvalService.getPendingApprovals();
      
      // Fetch statistics
      final stats = await approvalService.getApprovalStatistics();
      
      if (mounted) {
        setState(() {
          _pendingVolunteers = volunteers;
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load pending approvals. Please try again.';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _approveVolunteer(UserModel volunteer) async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final approvalService = Provider.of<ApprovalService>(context, listen: false);
      final success = await approvalService.approveVolunteer(volunteer);
      
      if (success && mounted) {
        setState(() {
          _pendingVolunteers.removeWhere((v) => v.id == volunteer.id);
          _statistics['pending'] = (_statistics['pending'] as int) - 1;
          _statistics['approved'] = (_statistics['approved'] as int) + 1;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.successVolunteerApproved),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve volunteer. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error approving volunteer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  Future<void> _rejectVolunteer(UserModel volunteer) async {
    // Show rejection reason dialog
    final reason = await _showRejectionDialog();
    if (reason == null) return; // User cancelled
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final approvalService = Provider.of<ApprovalService>(context, listen: false);
      final success = await approvalService.rejectVolunteer(volunteer, reason: reason);
      
      if (success && mounted) {
        setState(() {
          _pendingVolunteers.removeWhere((v) => v.id == volunteer.id);
          _statistics['pending'] = (_statistics['pending'] as int) - 1;
          _statistics['rejected'] = (_statistics['rejected'] as int) + 1;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.successVolunteerRejected),
            backgroundColor: Colors.red,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject volunteer. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error rejecting volunteer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  Future<String?> _showRejectionDialog() async {
    final reasonController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please provide a reason for rejecting this application. This will be shown to the volunteer.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, reasonController.text.trim());
            },
            child: const Text('Submit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildErrorView()
              : _buildBody(),
    );
  }
  
  Widget _buildErrorView() {
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
            _error,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBody() {
    if (_pendingVolunteers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'No pending approvals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All volunteer applications have been processed',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Stats summary
            _buildStatsCard(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Stats summary at the top
        _buildStatsCard(),
        
        // Main list of pending approvals
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _pendingVolunteers.length,
                itemBuilder: (context, index) {
                  final volunteer = _pendingVolunteers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with avatar and name
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue,
                                radius: 24,
                                child: Text(
                                  volunteer.name.isNotEmpty ? volunteer.name.substring(0, 1).toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    volunteer.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Volunteer ID: ${volunteer.volunteerId}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Volunteer Details
                          _buildDetailRow('Email', volunteer.email),
                          _buildDetailRow('Department', volunteer.department),
                          _buildDetailRow('Blood Group', volunteer.bloodGroup),
                          _buildDetailRow('Place', volunteer.place),
                          _buildDetailRow(
                            'Applied On', 
                            DateFormat('dd/MM/yyyy').format(volunteer.createdAt),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: _isProcessing ? null : () => _rejectVolunteer(volunteer),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Reject'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isProcessing ? null : () => _approveVolunteer(volunteer),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Approve'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Loading overlay
              if (_isProcessing)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Pending', _statistics['pending'], Colors.amber),
            _buildStatItem('Approved', _statistics['approved'], Colors.green),
            _buildStatItem('Rejected', _statistics['rejected'], Colors.red),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:nss_app/models/user_model.dart';
// import 'package:nss_app/utils/constants.dart';

// class PendingApprovalsScreen extends StatefulWidget {
//   const PendingApprovalsScreen({Key? key}) : super(key: key);

//   @override
//   State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
// }

// class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
//   List<UserModel> _pendingVolunteers = [];
//   bool _isLoading = false;
  
//   @override
//   void initState() {
//     super.initState();
//     _pendingVolunteers = UserModel.getMockPendingVolunteers();
//   }
  
//   Future<void> _approveVolunteer(UserModel volunteer) async {
//     setState(() {
//       _isLoading = true;
//     });
    
//     // Simulate API call
//     await Future.delayed(const Duration(seconds: 1));
    
//     setState(() {
//       _pendingVolunteers.removeWhere((v) => v.id == volunteer.id);
//       _isLoading = false;
//     });
    
//     if (!mounted) return;
    
//     // Show success message
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(AppConstants.successVolunteerApproved),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
  
//   Future<void> _rejectVolunteer(UserModel volunteer) async {
//     setState(() {
//       _isLoading = true;
//     });
    
//     // Simulate API call
//     await Future.delayed(const Duration(seconds: 1));
    
//     setState(() {
//       _pendingVolunteers.removeWhere((v) => v.id == volunteer.id);
//       _isLoading = false;
//     });
    
//     if (!mounted) return;
    
//     // Show success message
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(AppConstants.successVolunteerRejected),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pending Approvals'),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _buildBody(),
//     );
//   }
  
//   Widget _buildBody() {
//     if (_pendingVolunteers.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.check_circle_outline,
//               size: 64,
//               color: Colors.green,
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'No pending approvals',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'All volunteer applications have been processed',
//               style: TextStyle(
//                 color: Colors.grey,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text('Go Back'),
//             ),
//           ],
//         ),
//       );
//     }
    
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: _pendingVolunteers.length,
//       itemBuilder: (context, index) {
//         final volunteer = _pendingVolunteers[index];
//         return Card(
//           margin: const EdgeInsets.only(bottom: 16),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header with avatar and name
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor: Theme.of(context).primaryColor,
//                       radius: 24,
//                       child: Text(
//                         volunteer.name.substring(0, 1),
//                         style: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             volunteer.name,
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Volunteer ID: ${volunteer.volunteerId}',
//                             style: const TextStyle(
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Volunteer Details
//                 _buildDetailRow('Email', volunteer.email),
//                 _buildDetailRow('Department', volunteer.department),
//                 _buildDetailRow('Blood Group', volunteer.bloodGroup),
//                 _buildDetailRow('Place', volunteer.place),
//                 _buildDetailRow(
//                   'Applied On', 
//                   '${volunteer.createdAt.day}/${volunteer.createdAt.month}/${volunteer.createdAt.year}',
//                 ),
                
//                 const SizedBox(height: 16),
                
//                 // Action Buttons
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     OutlinedButton(
//                       onPressed: () => _rejectVolunteer(volunteer),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.red,
//                         side: const BorderSide(color: Colors.red),
//                       ),
//                       child: const Text('Reject'),
//                     ),
//                     const SizedBox(width: 12),
//                     ElevatedButton(
//                       onPressed: () => _approveVolunteer(volunteer),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                       ),
//                       child: const Text('Approve'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
  
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black54,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }