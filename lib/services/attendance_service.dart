import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nss_app/models/attendance_model.dart';

class AttendanceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get the collection reference
  CollectionReference get _attendanceCollection => _firestore.collection('attendance');
  
  // Mark attendance for a volunteer at an event
  Future<void> markAttendance({
    required String eventId,
    required String volunteerId,
    required bool isPresent,
    required String adminId,
    required String adminName,
  }) async {
    try {
      // Reference to the event document in the attendance collection
      final eventDocRef = _attendanceCollection.doc(eventId);
      
      // Create or update attendance record
      await eventDocRef.set({
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Reference to the volunteer's attendance document
      final volunteerAttendanceRef = eventDocRef.collection('volunteers').doc(volunteerId);
      
      // Set the volunteer's attendance
      await volunteerAttendanceRef.set({
        'volunteerId': volunteerId,
        'isPresent': isPresent,
        'markedBy': adminId,
        'adminName': adminName,
        'markedAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }
  
  // Mark attendance for multiple volunteers
  Future<void> markBulkAttendance({
    required String eventId,
    required Map<String, bool> attendanceStatus,
    required String adminId,
    required String adminName,
  }) async {
    try {
      // Create a batch write
      final batch = _firestore.batch();
      
      // Reference to the event document
      final eventDocRef = _attendanceCollection.doc(eventId);
      
      // Update the last updated timestamp for the event
      batch.set(eventDocRef, {
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Add each volunteer's attendance to the batch
      attendanceStatus.forEach((volunteerId, isPresent) {
        final volunteerRef = eventDocRef.collection('volunteers').doc(volunteerId);
        batch.set(volunteerRef, {
          'volunteerId': volunteerId,
          'isPresent': isPresent,
          'markedBy': adminId,
          'adminName': adminName,
          'markedAt': FieldValue.serverTimestamp(),
        });
      });
      
      // Commit the batch
      await batch.commit();
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to mark bulk attendance: $e');
    }
  }
  
  // Get attendance for a specific event
  Future<Map<String, bool>> getEventAttendance(String eventId) async {
    try {
      final snapshot = await _attendanceCollection
          .doc(eventId)
          .collection('volunteers')
          .get();
          
      final Map<String, bool> attendance = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        attendance[doc.id] = data['isPresent'] ?? false;
      }
      
      return attendance;
    } catch (e) {
      print('Error getting event attendance: $e');
      return {};
    }
  }
  
  // Get detailed attendance for a specific event
  Future<List<AttendanceModel>> getDetailedEventAttendance(String eventId) async {
    try {
      final snapshot = await _attendanceCollection
          .doc(eventId)
          .collection('volunteers')
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AttendanceModel(
          id: doc.id,
          eventId: eventId,
          volunteerId: data['volunteerId'] ?? '',
          isPresent: data['isPresent'] ?? false,
          markedBy: data['markedBy'] ?? '',
          markedAt: (data['markedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error getting detailed event attendance: $e');
      return [];
    }
  }
  
  // Get attendance for a specific volunteer
  Future<List<AttendanceModel>> getVolunteerAttendance(String volunteerId) async {
    List<AttendanceModel> result = [];
    
    try {
      // Get all event documents in the attendance collection
      final eventsSnapshot = await _attendanceCollection.get();
      
      // For each event, check if the volunteer has attendance
      for (var eventDoc in eventsSnapshot.docs) {
        final eventId = eventDoc.id;
        
        // Get the volunteer's attendance record for this event
        final volunteerAttendance = await eventDoc
            .reference
            .collection('volunteers')
            .doc(volunteerId)
            .get();
            
        if (volunteerAttendance.exists) {
          final data = volunteerAttendance.data() as Map<String, dynamic>;
          
          result.add(AttendanceModel(
            id: volunteerAttendance.id,
            eventId: eventId,
            volunteerId: data['volunteerId'] ?? '',
            isPresent: data['isPresent'] ?? false,
            markedBy: data['markedBy'] ?? '',
            markedAt: (data['markedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        }
      }
      
      return result;
    } catch (e) {
      print('Error getting volunteer attendance: $e');
      return [];
    }
  }
  
  // Calculate attendance percentage for a volunteer
  Future<double> calculateAttendancePercentage(String volunteerId, List<String> participatedEventIds) async {
    if (participatedEventIds.isEmpty) return 0.0;
    
    try {
      int presentCount = 0;
      
      for (String eventId in participatedEventIds) {
        // Get the volunteer's attendance record for this event
        final volunteerAttendance = await _attendanceCollection
            .doc(eventId)
            .collection('volunteers')
            .doc(volunteerId)
            .get();
            
        if (volunteerAttendance.exists) {
          final data = volunteerAttendance.data() as Map<String, dynamic>;
          if (data['isPresent'] == true) {
            presentCount++;
          }
        }
      }
      
      return (presentCount / participatedEventIds.length) * 100;
    } catch (e) {
      print('Error calculating attendance percentage: $e');
      return 0.0;
    }
  }
}