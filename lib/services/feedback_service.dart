import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // VOLUNTEER FUNCTIONALITY
  
  // Submit feedback for an event
  Future<void> submitFeedback({
    required String volunteerId,
    required String volunteerName,
    required String eventId,
    required String eventName,
    required DateTime eventDate,
    required String feedback,
  }) async {
    try {
      await _firestore.collection('feedback').add({
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'eventId': eventId,
        'eventName': eventName,
        'eventDate': eventDate,
        'feedback': feedback,
        'submittedAt': FieldValue.serverTimestamp(),
      });
      
      // Log success for debugging
      print('Feedback submitted successfully');
    } catch (e) {
      // Log error for debugging
      print('Error submitting feedback: $e');
      throw Exception('Failed to submit feedback: $e');
    }
  }
  
  // Check if a volunteer has already submitted feedback for an event
  Future<String?> getFeedbackForEvent({
    required String volunteerId,
    required String eventId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedback')
          .where('volunteerId', isEqualTo: volunteerId)
          .where('eventId', isEqualTo: eventId)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // Return the feedback text
        return querySnapshot.docs.first.data()['feedback'] as String?;
      }
      
      return null; // No feedback found
    } catch (e) {
      print('Error getting feedback: $e');
      return null;
    }
  }
  
  // Get feedback ID if a volunteer has already submitted feedback for an event
  Future<String?> getFeedbackIdForEvent({
    required String volunteerId,
    required String eventId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedback')
          .where('volunteerId', isEqualTo: volunteerId)
          .where('eventId', isEqualTo: eventId)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // Return the document ID
        return querySnapshot.docs.first.id;
      }
      
      return null; // No feedback found
    } catch (e) {
      print('Error getting feedback ID: $e');
      return null;
    }
  }
  
  // Update existing feedback
  Future<void> updateFeedback({
    required String feedbackId,
    required String feedback,
  }) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).update({
        'feedback': feedback,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('Feedback updated successfully');
    } catch (e) {
      print('Error updating feedback: $e');
      throw Exception('Failed to update feedback: $e');
    }
  }
  
  // ADMIN FUNCTIONALITY
  
  // Get all feedback entries
  Future<List<Map<String, dynamic>>> getAllFeedback({
    String sortBy = 'submittedAt',
    bool ascending = false,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedback')
          .orderBy(sortBy, descending: !ascending)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        // Format dates
        DateTime? eventDate;
        DateTime? submittedAt;
        
        if (data['eventDate'] != null) {
          if (data['eventDate'] is Timestamp) {
            eventDate = (data['eventDate'] as Timestamp).toDate();
          } else {
            try {
              eventDate = DateTime.parse(data['eventDate'].toString());
            } catch (e) {
              print('Failed to parse eventDate: $e');
            }
          }
        }
        
        if (data['submittedAt'] != null) {
          if (data['submittedAt'] is Timestamp) {
            submittedAt = (data['submittedAt'] as Timestamp).toDate();
          }
        }
        
        return {
          'id': doc.id,
          'volunteerId': data['volunteerId'] ?? 'Unknown',
          'volunteerName': data['volunteerName'] ?? 'Unknown Volunteer',
          'eventId': data['eventId'] ?? 'Unknown',
          'eventName': data['eventName'] ?? 'Unknown Event',
          'eventDate': eventDate,
          'feedback': data['feedback'] ?? '',
          'submittedAt': submittedAt,
        };
      }).toList();
    } catch (e) {
      print('Error getting feedback: $e');
      throw Exception('Failed to load feedback data: $e');
    }
  }
  
  // Get feedback for a specific event
  Future<List<Map<String, dynamic>>> getFeedbackByEvent(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedback')
          .where('eventId', isEqualTo: eventId)
          .orderBy('submittedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        return {
          'id': doc.id,
          'volunteerId': data['volunteerId'] ?? 'Unknown',
          'volunteerName': data['volunteerName'] ?? 'Unknown Volunteer',
          'eventId': data['eventId'] ?? 'Unknown',
          'eventName': data['eventName'] ?? 'Unknown Event',
          'eventDate': data['eventDate'] is Timestamp ? (data['eventDate'] as Timestamp).toDate() : null,
          'feedback': data['feedback'] ?? '',
          'submittedAt': data['submittedAt'] is Timestamp ? (data['submittedAt'] as Timestamp).toDate() : null,
        };
      }).toList();
    } catch (e) {
      print('Error getting feedback for event: $e');
      throw Exception('Failed to load event feedback: $e');
    }
  }
  
  // Get feedback by volunteer
  Future<List<Map<String, dynamic>>> getFeedbackByVolunteer(String volunteerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedback')
          .where('volunteerId', isEqualTo: volunteerId)
          .orderBy('submittedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        return {
          'id': doc.id,
          'volunteerId': data['volunteerId'] ?? 'Unknown',
          'volunteerName': data['volunteerName'] ?? 'Unknown Volunteer',
          'eventId': data['eventId'] ?? 'Unknown',
          'eventName': data['eventName'] ?? 'Unknown Event',
          'eventDate': data['eventDate'] is Timestamp ? (data['eventDate'] as Timestamp).toDate() : null,
          'feedback': data['feedback'] ?? '',
          'submittedAt': data['submittedAt'] is Timestamp ? (data['submittedAt'] as Timestamp).toDate() : null,
        };
      }).toList();
    } catch (e) {
      print('Error getting feedback for volunteer: $e');
      throw Exception('Failed to load volunteer feedback: $e');
    }
  }
  
  // Delete a feedback entry
  Future<void> deleteFeedback(String feedbackId) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).delete();
      print('Feedback deleted successfully');
    } catch (e) {
      print('Error deleting feedback: $e');
      throw Exception('Failed to delete feedback: $e');
    }
  }
  
  // Get feedback statistics
  Future<Map<String, dynamic>> getFeedbackStats() async {
    try {
      final querySnapshot = await _firestore.collection('feedback').get();
      
      final totalFeedbacks = querySnapshot.docs.length;
      final uniqueEvents = querySnapshot.docs.map((doc) => doc.data()['eventId']).toSet().length;
      final uniqueVolunteers = querySnapshot.docs.map((doc) => doc.data()['volunteerId']).toSet().length;
      
      // Get the most recent feedback
      DateTime? latestFeedbackDate;
      for (var doc in querySnapshot.docs) {
        final submittedAt = doc.data()['submittedAt'];
        if (submittedAt is Timestamp) {
          final date = submittedAt.toDate();
          if (latestFeedbackDate == null || date.isAfter(latestFeedbackDate)) {
            latestFeedbackDate = date;
          }
        }
      }
      
      return {
        'totalFeedbacks': totalFeedbacks,
        'uniqueEvents': uniqueEvents,
        'uniqueVolunteers': uniqueVolunteers,
        'latestFeedbackDate': latestFeedbackDate,
      };
    } catch (e) {
      print('Error getting feedback stats: $e');
      throw Exception('Failed to load feedback statistics: $e');
    }
  }
  
  // Get current user's feedback for all events
  Future<List<Map<String, dynamic>>> getCurrentUserFeedback() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      return await getFeedbackByVolunteer(currentUser.uid);
    } catch (e) {
      print('Error getting current user feedback: $e');
      return [];
    }
  }
}














// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class FeedbackService extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
  
//   Future<void> submitFeedback({
//     required String volunteerId,
//     required String volunteerName,
//     required String eventId,
//     required String eventName,
//     required DateTime eventDate,
//     required String feedback,
//   }) async {
//     try {
//       await _firestore.collection('feedback').add({
//         'volunteerId': volunteerId,
//         'volunteerName': volunteerName,
//         'eventId': eventId,
//         'eventName': eventName,
//         'eventDate': eventDate,
//         'feedback': feedback,
//         'submittedAt': FieldValue.serverTimestamp(),
//       });
      
//       // Log success for debugging
//       print('Feedback submitted successfully');
//     } catch (e) {
//       // Log error for debugging
//       print('Error submitting feedback: $e');
//       throw Exception('Failed to submit feedback: $e');
//     }
//   }
  
//   Future<String?> getFeedbackForEvent({
//     required String volunteerId,
//     required String eventId,
//   }) async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('feedback')
//           .where('volunteerId', isEqualTo: volunteerId)
//           .where('eventId', isEqualTo: eventId)
//           .get();
      
//       if (querySnapshot.docs.isNotEmpty) {
//         // Return the feedback text
//         return querySnapshot.docs.first.data()['feedback'] as String?;
//       }
      
//       return null; // No feedback found
//     } catch (e) {
//       print('Error getting feedback: $e');
//       return null;
//     }
//   }
// }