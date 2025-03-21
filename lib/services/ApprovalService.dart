import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nss_app/models/user_model.dart';

class ApprovalService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Fetch all pending volunteer approvals
  Future<List<UserModel>> getPendingApprovals() async {
    try {
      print('Fetching pending approvals from users collection...');
      
      // First try to get unapproved users from the users collection
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .where('isApproved', isEqualTo: false)
          .get();
          
      print('Found ${usersQuery.docs.length} unapproved volunteers in users collection');
      
      // Map users collection data to UserModel objects
      final pendingUsers = usersQuery.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          volunteerId: data['volunteerId'] ?? '',
          department: data['department'] ?? '',
          bloodGroup: data['bloodGroup'] ?? '',
          place: data['place'] ?? '',
          role: data['role'] ?? 'volunteer',
          isApproved: false,
          eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      
      return pendingUsers;
    } catch (e) {
      print('Error fetching pending approvals: $e');
      return [];
    }
  }
  
  // Approve a volunteer
  Future<bool> approveVolunteer(UserModel volunteer) async {
    try {
      // Start a batch write to ensure atomicity
      final batch = _firestore.batch();
      
      // Update the user document in the users collection
      final userDocRef = _firestore.collection('users').doc(volunteer.id);
      batch.update(userDocRef, {
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });
      
      // Also update the status in pending_approvals collection if it exists
      try {
        final pendingDocRef = _firestore.collection('pending_approvals').doc(volunteer.id);
        final pendingDoc = await pendingDocRef.get();
        
        if (pendingDoc.exists) {
          batch.update(pendingDocRef, {
            'status': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        // Continue even if there's an issue with the pending_approvals collection
        print('Note: Could not update pending_approvals collection: $e');
      }
      
      // Commit the batch
      await batch.commit();
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error approving volunteer: $e');
      return false;
    }
  }
  
  // Reject a volunteer
  Future<bool> rejectVolunteer(UserModel volunteer, {String reason = ''}) async {
    try {
      // Start a batch write to ensure atomicity
      final batch = _firestore.batch();
      
      // Create or update in pending_approvals collection to track rejection reason
      final pendingDocRef = _firestore.collection('pending_approvals').doc(volunteer.id);
      
      try {
        final pendingDoc = await pendingDocRef.get();
        
        if (pendingDoc.exists) {
          batch.update(pendingDocRef, {
            'status': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
            'rejectionReason': reason,
          });
        } else {
          batch.set(pendingDocRef, {
            'name': volunteer.name,
            'email': volunteer.email,
            'volunteerId': volunteer.volunteerId,
            'status': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
            'rejectionReason': reason,
          });
        }
      } catch (e) {
        print('Note: Issue with pending_approvals collection: $e');
      }
      
      // Remove the user document or mark as rejected in users collection
      final userDocRef = _firestore.collection('users').doc(volunteer.id);
      batch.delete(userDocRef);
      
      // Commit the batch
      await batch.commit();
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error rejecting volunteer: $e');
      return false;
    }
  }
  
  // Get approval statistics
  Future<Map<String, dynamic>> getApprovalStatistics() async {
    try {
      // Initialize stats map
      final Map<String, dynamic> stats = {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'total': 0,
      };
      
      // Get pending count from users collection (unapproved volunteers only)
      final pendingQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .where('isApproved', isEqualTo: false)
          .count()
          .get();
          
      stats['pending'] = pendingQuery.count ?? 0;
      
      // Get approved count from users collection (approved volunteers only)
      final approvedQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .where('isApproved', isEqualTo: true)
          .count()
          .get();
          
      stats['approved'] = approvedQuery.count ?? 0;
      
      // Get rejected count from pending_approvals collection
      try {
        final rejectedQuery = await _firestore
            .collection('pending_approvals')
            .where('status', isEqualTo: 'rejected')
            .count()
            .get();
            
        stats['rejected'] = rejectedQuery.count ?? 0;
      } catch (e) {
        print('Error getting rejected count: $e');
        stats['rejected'] = 0;
      }
      
      // Calculate total
      stats['total'] = stats['pending'] + stats['approved'] + stats['rejected'];
      
      return stats;
    } catch (e) {
      print('Error in getApprovalStatistics: $e');
      
      // If there's an error, try a different approach without count()
      try {
        final Map<String, dynamic> stats = {
          'pending': 0,
          'approved': 0,
          'rejected': 0,
          'total': 0,
        };
        
        // Get pending count - make sure we filter for volunteer role
        final pendingDocs = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'volunteer')
            .where('isApproved', isEqualTo: false)
            .get();
            
        stats['pending'] = pendingDocs.docs.length;
        
        // Get approved count - make sure we filter for volunteer role
        final approvedDocs = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'volunteer')
            .where('isApproved', isEqualTo: true)
            .get();
            
        stats['approved'] = approvedDocs.docs.length;
        
        // Get rejected count
        try {
          final rejectedDocs = await _firestore
              .collection('pending_approvals')
              .where('status', isEqualTo: 'rejected')
              .get();
              
          stats['rejected'] = rejectedDocs.docs.length;
        } catch (e) {
          stats['rejected'] = 0;
        }
        
        // Calculate total
        stats['total'] = stats['pending'] + stats['approved'] + stats['rejected'];
        
        return stats;
      } catch (innerError) {
        print('Secondary approach also failed: $innerError');
        return {
          'pending': 0,
          'approved': 0,
          'rejected': 0,
          'total': 0,
        };
      }
    }
  }
}















// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:nss_app/models/user_model.dart';

// class ApprovalService extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   // Fetch all pending volunteer approvals
//   Future<List<UserModel>> getPendingApprovals() async {
//     try {
//       print('Fetching pending approvals from users collection...');
      
//       // First try to get unapproved users from the users collection
//       final usersQuery = await _firestore
//           .collection('users')
//           .where('isApproved', isEqualTo: false)
//           .get();
          
//       print('Found ${usersQuery.docs.length} unapproved users in users collection');
      
//       // Map users collection data to UserModel objects
//       final pendingUsers = usersQuery.docs.map((doc) {
//         final data = doc.data();
//         return UserModel(
//           id: doc.id,
//           name: data['name'] ?? '',
//           email: data['email'] ?? '',
//           volunteerId: data['volunteerId'] ?? '',
//           department: data['department'] ?? '',
//           bloodGroup: data['bloodGroup'] ?? '',
//           place: data['place'] ?? '',
//           role: data['role'] ?? 'volunteer',
//           isApproved: false,
//           eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
//           createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//         );
//       }).toList();
      
//       return pendingUsers;
//     } catch (e) {
//       print('Error fetching pending approvals: $e');
//       return [];
//     }
//   }
  
//   // Approve a volunteer
//   Future<bool> approveVolunteer(UserModel volunteer) async {
//     try {
//       // Start a batch write to ensure atomicity
//       final batch = _firestore.batch();
      
//       // Update the user document in the users collection
//       final userDocRef = _firestore.collection('users').doc(volunteer.id);
//       batch.update(userDocRef, {
//         'isApproved': true,
//         'approvedAt': FieldValue.serverTimestamp(),
//       });
      
//       // Also update the status in pending_approvals collection if it exists
//       try {
//         final pendingDocRef = _firestore.collection('pending_approvals').doc(volunteer.id);
//         final pendingDoc = await pendingDocRef.get();
        
//         if (pendingDoc.exists) {
//           batch.update(pendingDocRef, {
//             'status': 'approved',
//             'approvedAt': FieldValue.serverTimestamp(),
//           });
//         }
//       } catch (e) {
//         // Continue even if there's an issue with the pending_approvals collection
//         print('Note: Could not update pending_approvals collection: $e');
//       }
      
//       // Commit the batch
//       await batch.commit();
      
//       notifyListeners();
//       return true;
//     } catch (e) {
//       print('Error approving volunteer: $e');
//       return false;
//     }
//   }
  
//   // Reject a volunteer
//   Future<bool> rejectVolunteer(UserModel volunteer, {String reason = ''}) async {
//     try {
//       // Start a batch write to ensure atomicity
//       final batch = _firestore.batch();
      
//       // Create or update in pending_approvals collection to track rejection reason
//       final pendingDocRef = _firestore.collection('pending_approvals').doc(volunteer.id);
      
//       try {
//         final pendingDoc = await pendingDocRef.get();
        
//         if (pendingDoc.exists) {
//           batch.update(pendingDocRef, {
//             'status': 'rejected',
//             'rejectedAt': FieldValue.serverTimestamp(),
//             'rejectionReason': reason,
//           });
//         } else {
//           batch.set(pendingDocRef, {
//             'name': volunteer.name,
//             'email': volunteer.email,
//             'volunteerId': volunteer.volunteerId,
//             'status': 'rejected',
//             'rejectedAt': FieldValue.serverTimestamp(),
//             'rejectionReason': reason,
//           });
//         }
//       } catch (e) {
//         print('Note: Issue with pending_approvals collection: $e');
//       }
      
//       // Remove the user document or mark as rejected in users collection
//       final userDocRef = _firestore.collection('users').doc(volunteer.id);
//       batch.delete(userDocRef);
      
//       // Commit the batch
//       await batch.commit();
      
//       notifyListeners();
//       return true;
//     } catch (e) {
//       print('Error rejecting volunteer: $e');
//       return false;
//     }
//   }
  
//   // Get approval statistics
//   Future<Map<String, dynamic>> getApprovalStatistics() async {
//     try {
//       // Initialize stats map
//       final Map<String, dynamic> stats = {
//         'pending': 0,
//         'approved': 0,
//         'rejected': 0,
//         'total': 0,
//       };
      
//       // Get pending count from users collection (unapproved users)
//       final pendingQuery = await _firestore
//           .collection('users')
//           .where('isApproved', isEqualTo: false)
//           .count()
//           .get();
          
//       stats['pending'] = pendingQuery.count ?? 0;
      
//       // Get approved count from users collection
//       final approvedQuery = await _firestore
//           .collection('users')
//           .where('isApproved', isEqualTo: true)
//           .count()
//           .get();
          
//       stats['approved'] = approvedQuery.count ?? 0;
      
//       // Get rejected count from pending_approvals collection
//       try {
//         final rejectedQuery = await _firestore
//             .collection('pending_approvals')
//             .where('status', isEqualTo: 'rejected')
//             .count()
//             .get();
            
//         stats['rejected'] = rejectedQuery.count ?? 0;
//       } catch (e) {
//         print('Error getting rejected count: $e');
//         stats['rejected'] = 0;
//       }
      
//       // Calculate total
//       stats['total'] = stats['pending'] + stats['approved'] + stats['rejected'];
      
//       return stats;
//     } catch (e) {
//       print('Error in getApprovalStatistics: $e');
      
//       // If there's an error, try a different approach without count()
//       try {
//         final Map<String, dynamic> stats = {
//           'pending': 0,
//           'approved': 0,
//           'rejected': 0,
//           'total': 0,
//         };
        
//         // Get pending count
//         final pendingDocs = await _firestore
//             .collection('users')
//             .where('isApproved', isEqualTo: false)
//             .get();
            
//         stats['pending'] = pendingDocs.docs.length;
        
//         // Get approved count
//         final approvedDocs = await _firestore
//             .collection('users')
//             .where('isApproved', isEqualTo: true)
//             .get();
            
//         stats['approved'] = approvedDocs.docs.length;
        
//         // Get rejected count
//         try {
//           final rejectedDocs = await _firestore
//               .collection('pending_approvals')
//               .where('status', isEqualTo: 'rejected')
//               .get();
              
//           stats['rejected'] = rejectedDocs.docs.length;
//         } catch (e) {
//           stats['rejected'] = 0;
//         }
        
//         // Calculate total
//         stats['total'] = stats['pending'] + stats['approved'] + stats['rejected'];
        
//         return stats;
//       } catch (innerError) {
//         print('Secondary approach also failed: $innerError');
//         return {
//           'pending': 0,
//           'approved': 0,
//           'rejected': 0,
//           'total': 0,
//         };
//       }
//     }
//   }
// }



// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:nss_app/models/user_model.dart';

// class ApprovalService extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   // Fetch all pending volunteer approvals
//   Future<List<UserModel>> getPendingApprovals() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('pending_approvals')
//           .where('status', isEqualTo: 'pending')
//           .orderBy('createdAt', descending: true)
//           .get();
      
//       return querySnapshot.docs.map((doc) {
//         final data = doc.data();
//         return UserModel(
//           id: doc.id,
//           name: data['name'] ?? '',
//           email: data['email'] ?? '',
//           volunteerId: data['volunteerId'] ?? '',
//           department: data['department'] ?? '',
//           bloodGroup: data['bloodGroup'] ?? '',
//           place: data['place'] ?? '',
//           role: 'volunteer', // Default role for pending approvals
//           isApproved: false, // Pending approvals are not approved yet
//           eventsParticipated: [], // No events participated yet
//           createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//         );
//       }).toList();
//     } catch (e) {
//       debugPrint('Error fetching pending approvals: $e');
//       return [];
//     }
//   }
  
//   // Approve a volunteer
//   Future<bool> approveVolunteer(UserModel volunteer) async {
//     try {
//       // Start a batch write to ensure atomicity
//       final batch = _firestore.batch();
      
//       // 1. Update the user document in the users collection
//       final userDocRef = _firestore.collection('users').doc(volunteer.id);
//       batch.update(userDocRef, {
//         'isApproved': true,
//         'approvedAt': FieldValue.serverTimestamp(),
//       });
      
//       // 2. Update the pending approval document
//       final pendingDocRef = _firestore.collection('pending_approvals').doc(volunteer.id);
//       batch.update(pendingDocRef, {
//         'status': 'approved',
//         'approvedAt': FieldValue.serverTimestamp(),
//       });
      
//       // Commit the batch
//       await batch.commit();
      
//       notifyListeners();
//       return true;
//     } catch (e) {
//       debugPrint('Error approving volunteer: $e');
//       return false;
//     }
//   }
  
//   // Reject a volunteer
//   Future<bool> rejectVolunteer(UserModel volunteer, {String reason = ''}) async {
//     try {
//       // Start a batch write to ensure atomicity
//       final batch = _firestore.batch();
      
//       // 1. Update the pending approval document
//       final pendingDocRef = _firestore.collection('pending_approvals').doc(volunteer.id);
//       batch.update(pendingDocRef, {
//         'status': 'rejected',
//         'rejectedAt': FieldValue.serverTimestamp(),
//         'rejectionReason': reason,
//       });
      
//       // Commit the batch
//       await batch.commit();
      
//       notifyListeners();
//       return true;
//     } catch (e) {
//       debugPrint('Error rejecting volunteer: $e');
//       return false;
//     }
//   }
  
//   // Get approval statistics - alternative method using QuerySnapshot instead of count()
//   Future<Map<String, dynamic>> getApprovalStatistics() async {
//     try {
//       // Initialize stats map
//       final Map<String, dynamic> stats = {
//         'pending': 0,
//         'approved': 0,
//         'rejected': 0,
//         'total': 0,
//       };
      
//       // Get all documents in one query to reduce network calls
//       final QuerySnapshot querySnapshot = await _firestore
//           .collection('pending_approvals')
//           .get();
      
//       // Count documents by status
//       for (var doc in querySnapshot.docs) {
//         final String status = doc.get('status') as String? ?? 'pending';
        
//         if (status == 'pending') {
//           stats['pending'] = (stats['pending'] as int) + 1;
//         } else if (status == 'approved') {
//           stats['approved'] = (stats['approved'] as int) + 1;
//         } else if (status == 'rejected') {
//           stats['rejected'] = (stats['rejected'] as int) + 1;
//         }
//       }
      
//       // Calculate total
//       stats['total'] = (stats['pending'] as int) + 
//                        (stats['approved'] as int) + 
//                        (stats['rejected'] as int);
      
//       return stats;
//     } catch (e) {
//       debugPrint('Error getting approval statistics: $e');
//       return {
//         'pending': 0,
//         'approved': 0,
//         'rejected': 0,
//         'total': 0,
//       };
//     }
//   }
// }