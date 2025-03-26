import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PointService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection reference
  CollectionReference get _pointsCollection => _firestore.collection('points');
  
  // Get points for a volunteer
  Future<Map<String, int>> getVolunteerPoints(String volunteerId) async {
    try {
      final docSnapshot = await _pointsCollection.doc(volunteerId).get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        // Convert all values to int
        Map<String, int> pointsMap = {};
        data.forEach((eventId, points) {
          if (points is int) {
            pointsMap[eventId] = points;
          } else if (points is double) {
            pointsMap[eventId] = points.toInt();
          } else if (points is String) {
            pointsMap[eventId] = int.tryParse(points) ?? 0;
          } else {
            pointsMap[eventId] = 0;
          }
        });
        return pointsMap;
      }
      return {};
    } catch (e) {
      print('Error fetching volunteer points: $e');
      return {};
    }
  }
  
  // Add or update points for a volunteer for a specific event
  Future<void> updateVolunteerPoints(String volunteerId, String eventId, int points) async {
    try {
      await _pointsCollection.doc(volunteerId).set({
        eventId: points
      }, SetOptions(merge: true));
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update points: $e');
    }
  }
  
  // Update points for multiple volunteers in a batch
  Future<void> updatePointsInBatch(Map<String, Map<String, int>> pointsData) async {
    try {
      final batch = _firestore.batch();
      
      pointsData.forEach((volunteerId, eventPoints) {
        final docRef = _pointsCollection.doc(volunteerId);
        batch.set(docRef, eventPoints, SetOptions(merge: true));
      });
      
      await batch.commit();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update points in batch: $e');
    }
  }
  
  // Get total points for a volunteer
  Future<int> getTotalPointsForVolunteer(String volunteerId) async {
    try {
      final pointsMap = await getVolunteerPoints(volunteerId);
      int totalPoints = 0;
      for (var points in pointsMap.values) {
        totalPoints += points;
      }
      return totalPoints;
    } catch (e) {
      print('Error calculating total points: $e');
      return 0;
    }
  }
  
  // Get points for an event
  Future<Map<String, int>> getPointsForEvent(String eventId, List<String> volunteerIds) async {
    try {
      Map<String, int> result = {};
      
      // Query for each volunteer to get their points for this event
      for (final volunteerId in volunteerIds) {
        final docSnapshot = await _pointsCollection.doc(volunteerId).get();
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          if (data.containsKey(eventId)) {
            final points = data[eventId];
            if (points is int) {
              result[volunteerId] = points;
            } else if (points is double) {
              result[volunteerId] = points.toInt();
            } else if (points is String) {
              result[volunteerId] = int.tryParse(points) ?? 0;
            } else {
              result[volunteerId] = 0;
            }
          } else {
            result[volunteerId] = 0;
          }
        } else {
          result[volunteerId] = 0;
        }
      }
      
      return result;
    } catch (e) {
      print('Error fetching points for event: $e');
      return {};
    }
  }
}