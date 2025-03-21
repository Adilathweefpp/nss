import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nss_app/models/user_model.dart';

class AdminManageService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all admins from Firestore
  Future<List<UserModel>> getAdmins() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
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
          role: data['role'] ?? 'admin',
          isApproved: data['isApproved'] ?? true,
          eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error getting admins: $e');
      return [];
    }
  }

  // Add new admin to Firestore
  Future<bool> addAdmin({
    required String name,
    required String email,
    required String adminId,
    required String department,
    required String password,
    String bloodGroup = '',
    String place = '',
  }) async {
    try {
      // Check if admin with same email already exists
      final QuerySnapshot existingEmail = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingEmail.docs.isNotEmpty) {
        return false;
      }

      // Create new admin document
      await _firestore.collection('users').add({
        'name': name,
        'email': email,
        'adminId': adminId,
        'volunteerId': '',
        'bloodGroup': bloodGroup,
        'place': place,
        'department': department,
        'role': 'admin',
        'isApproved': true,
        'eventsParticipated': [],
        'createdAt': FieldValue.serverTimestamp(),
        'password': password, // Note: In a real app, you would handle authentication through Firebase Auth
      });

      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding admin: $e');
      return false;
    }
  }

  // Remove admin from Firestore
  Future<bool> removeAdmin(String adminId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('adminId', isEqualTo: adminId)
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      await _firestore.collection('users').doc(snapshot.docs.first.id).delete();
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error removing admin: $e');
      return false;
    }
  }

  // Generate unique admin ID suggestion
  Future<String> generateUniqueAdminId() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      final int count = snapshot.docs.length + 1;
      return 'NSS-ADMIN-${count.toString().padLeft(3, '0')}';
    } catch (e) {
      print('Error generating admin ID: $e');
      return 'NSS-ADMIN-001';
    }
  }
  
  // Check if admin ID already exists
  Future<bool> isAdminIdUnique(String adminId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('adminId', isEqualTo: adminId)
          .get();
          
      return snapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking admin ID uniqueness: $e');
      return false;
    }
  }
}