import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nss_app/models/user_model.dart';

class VolunteerManageService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all volunteers (both approved and pending)
  Future<List<UserModel>> getAllVolunteers() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          volunteerId: data['volunteerId'] ?? '',
          adminId: data['adminId'] ?? '',
          bloodGroup: data['bloodGroup'] ?? '',
          place: data['place'] ?? '',
          department: data['department'] ?? '',
          role: data['role'] ?? 'volunteer',
          isApproved: data['isApproved'] ?? false,
          eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error getting volunteers: $e');
      return [];
    }
  }

  // Get approved volunteers
  Future<List<UserModel>> getApprovedVolunteers() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .where('isApproved', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          volunteerId: data['volunteerId'] ?? '',
          adminId: data['adminId'] ?? '',
          bloodGroup: data['bloodGroup'] ?? '',
          place: data['place'] ?? '',
          department: data['department'] ?? '',
          role: data['role'] ?? 'volunteer',
          isApproved: true,
          eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error getting approved volunteers: $e');
      return [];
    }
  }

  // Get pending volunteers
  Future<List<UserModel>> getPendingVolunteers() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .where('isApproved', isEqualTo: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          volunteerId: data['volunteerId'] ?? '',
          adminId: data['adminId'] ?? '',
          bloodGroup: data['bloodGroup'] ?? '',
          place: data['place'] ?? '',
          department: data['department'] ?? '',
          role: data['role'] ?? 'volunteer',
          isApproved: false,
          eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error getting pending volunteers: $e');
      return [];
    }
  }

  // Remove volunteer from database
  Future<bool> removeVolunteer(String volunteerId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('volunteerId', isEqualTo: volunteerId)
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      await _firestore.collection('users').doc(snapshot.docs.first.id).delete();
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error removing volunteer: $e');
      return false;
    }
  }

  // Get a specific volunteer by ID
  Future<UserModel?> getVolunteerById(String volunteerId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('volunteerId', isEqualTo: volunteerId)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      
      return UserModel(
        id: doc.id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        volunteerId: data['volunteerId'] ?? '',
        adminId: data['adminId'] ?? '',
        bloodGroup: data['bloodGroup'] ?? '',
        place: data['place'] ?? '',
        department: data['department'] ?? '',
        role: data['role'] ?? 'volunteer',
        isApproved: data['isApproved'] ?? false,
        eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print('Error getting volunteer by ID: $e');
      return null;
    }
  }
}