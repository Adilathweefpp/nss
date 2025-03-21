import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nss_app/models/user_model.dart';

class ProfileService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current logged in user data
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      // Get current user ID
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        print('No user logged in');
        return null;
      }
      
      print('Fetching user profile for: ${currentUser.uid}');
      
      // Get user data from Firestore
      final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (!doc.exists) {
        print('User document does not exist in Firestore');
        return null;
      }
      
      final data = doc.data()!;
      print('User data retrieved: $data');
      
      // Map the data to UserModel
      return UserModel(
        id: doc.id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        volunteerId: data['volunteerId'] ?? '',
        department: data['department'] ?? '',
        bloodGroup: data['bloodGroup'] ?? '',
        place: data['place'] ?? '',
        role: data['role'] ?? 'volunteer',
        isApproved: data['isApproved'] ?? false,
        eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile({
    required String name,
    required String bloodGroup,
    required String place,
    required String department,
  }) async {
    try {
      // Get current user ID
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        print('No user logged in');
        return false;
      }
      
      print('Updating profile for user: ${currentUser.uid}');
      
      // Update user data in Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'name': name,
        'bloodGroup': bloodGroup,
        'place': place,
        'department': department,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update display name in Firebase Auth
      await currentUser.updateDisplayName(name);
      
      print('Profile updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }
  
  // Sign out user
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out');
      return true;
    } catch (e) {
      print('Error signing out: $e');
      return false;
    }
  }
}