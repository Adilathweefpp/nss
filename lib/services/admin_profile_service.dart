import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nss_app/models/user_model.dart';

class AdminProfileService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current admin profile
  Future<UserModel?> getCurrentAdminProfile() async {
    try {
      // Get current user ID
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        print('No user logged in');
        return null;
      }
      
      print('Fetching admin profile for: ${currentUser.uid}');
      
      // Get admin data from Firestore
      final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (!doc.exists) {
        print('Admin document does not exist in Firestore');
        return null;
      }
      
      final data = doc.data()!;
      
      // Verify the user is an admin
      if (data['role'] != 'admin') {
        print('User is not an admin');
        return null;
      }
      
      print('Admin data retrieved: $data');
      
      // Map the data to UserModel
      return UserModel(
        id: doc.id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        volunteerId: data['volunteerId'] ?? '',
        adminId: data['adminId'] ?? '', // Added adminId field
        department: data['department'] ?? '',
        bloodGroup: data['bloodGroup'] ?? '',
        place: data['place'] ?? '',
        role: data['role'] ?? 'admin',
        isApproved: data['isApproved'] ?? true,
        eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print('Error fetching admin profile: $e');
      return null;
    }
  }
  
  // Update admin profile
  Future<bool> updateAdminProfile({
    required String name,
    required String department,
    required String bloodGroup,
    required String adminId, // Changed from volunteerId to adminId
  }) async {
    try {
      // Get current user ID
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        print('No user logged in');
        return false;
      }
      
      print('Updating admin profile for user: ${currentUser.uid}');
      
      // Update user data in Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'name': name,
        'department': department,
        'bloodGroup': bloodGroup,
        'adminId': adminId, // Store as adminId in Firestore
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update display name in Firebase Auth
      await currentUser.updateDisplayName(name);
      
      print('Admin profile updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating admin profile: $e');
      return false;
    }
  }
  
  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        print('No user logged in');
        return false;
      }
      
      if (currentUser.email == null) {
        print('User does not have an email');
        return false;
      }
      
      // Re-authenticate user to verify current password
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );
      
      await currentUser.reauthenticateWithCredential(credential);
      
      // Password verified, update to new password
      await currentUser.updatePassword(newPassword);
      
      print('Password changed successfully');
      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }
  
  // Sign out admin
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      print('Admin signed out');
      return true;
    } catch (e) {
      print('Error signing out: $e');
      return false;
    }
  }
}










// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:nss_app/models/user_model.dart';

// class AdminProfileService extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
  
//   // Get current admin profile
//   Future<UserModel?> getCurrentAdminProfile() async {
//     try {
//       // Get current user ID
//       final User? currentUser = _auth.currentUser;
      
//       if (currentUser == null) {
//         print('No user logged in');
//         return null;
//       }
      
//       print('Fetching admin profile for: ${currentUser.uid}');
      
//       // Get admin data from Firestore
//       final doc = await _firestore.collection('users').doc(currentUser.uid).get();
      
//       if (!doc.exists) {
//         print('Admin document does not exist in Firestore');
//         return null;
//       }
      
//       final data = doc.data()!;
      
//       // Verify the user is an admin
//       if (data['role'] != 'admin') {
//         print('User is not an admin');
//         return null;
//       }
      
//       print('Admin data retrieved: $data');
      
//       // Map the data to UserModel
//       return UserModel(
//         id: doc.id,
//         name: data['name'] ?? '',
//         email: data['email'] ?? '',
//         volunteerId: data['volunteerId'] ?? '',
//         department: data['department'] ?? '',
//         bloodGroup: data['bloodGroup'] ?? '',
//         place: data['place'] ?? '',
//         role: data['role'] ?? 'admin',
//         isApproved: data['isApproved'] ?? true,
//         eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
//         createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       );
//     } catch (e) {
//       print('Error fetching admin profile: $e');
//       return null;
//     }
//   }
  
//   // Update admin profile
//   Future<bool> updateAdminProfile({
//     required String name,
//     required String department,
//   }) async {
//     try {
//       // Get current user ID
//       final User? currentUser = _auth.currentUser;
      
//       if (currentUser == null) {
//         print('No user logged in');
//         return false;
//       }
      
//       print('Updating admin profile for user: ${currentUser.uid}');
      
//       // Update user data in Firestore
//       await _firestore.collection('users').doc(currentUser.uid).update({
//         'name': name,
//         'department': department,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
      
//       // Update display name in Firebase Auth
//       await currentUser.updateDisplayName(name);
      
//       print('Admin profile updated successfully');
//       notifyListeners();
//       return true;
//     } catch (e) {
//       print('Error updating admin profile: $e');
//       return false;
//     }
//   }
  
//   // Change password
//   Future<bool> changePassword({
//     required String currentPassword,
//     required String newPassword,
//   }) async {
//     try {
//       final User? currentUser = _auth.currentUser;
      
//       if (currentUser == null) {
//         print('No user logged in');
//         return false;
//       }
      
//       if (currentUser.email == null) {
//         print('User does not have an email');
//         return false;
//       }
      
//       // Re-authenticate user to verify current password
//       final credential = EmailAuthProvider.credential(
//         email: currentUser.email!,
//         password: currentPassword,
//       );
      
//       await currentUser.reauthenticateWithCredential(credential);
      
//       // Password verified, update to new password
//       await currentUser.updatePassword(newPassword);
      
//       print('Password changed successfully');
//       return true;
//     } catch (e) {
//       print('Error changing password: $e');
//       return false;
//     }
//   }
  
//   // Sign out admin
//   Future<bool> signOut() async {
//     try {
//       await _auth.signOut();
//       print('Admin signed out');
//       return true;
//     } catch (e) {
//       print('Error signing out: $e');
//       return false;
//     }
//   }
// }