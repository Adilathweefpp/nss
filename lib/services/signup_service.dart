import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Register a new student
  Future<UserCredential> registerStudent({
    required String email,
    required String password,
    required String name,
    required String volunteerId,
    required String bloodGroup,
    required String place,
    required String department,
  }) async {
    try {
      // Create user account in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // If user creation successful, add details to Firestore
      if (credential.user != null) {
        // First add to users collection (with isApproved = false)
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'role': 'volunteer',
          'volunteerId': volunteerId,
          'bloodGroup': bloodGroup,
          'place': place,
          'department': department,
          'isApproved': false,
          'eventsParticipated': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Then add detailed info to pending_approvals collection
        await _firestore.collection('pending_approvals').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'volunteerId': volunteerId,
          'bloodGroup': bloodGroup,
          'place': place,
          'eventsParticipated': [],
          'department': department,
          'role': 'volunteer',
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending', // Could be 'pending', 'approved', or 'rejected'
        });
        
        // Update display name
        await credential.user!.updateDisplayName(name);
      }
      
      notifyListeners();
      return credential;
    } catch (e) {
      print('Error in registerStudent: $e'); // Debug log
      rethrow;
    }
  }
  
  // Get pending approval status
  Future<Map<String, dynamic>> getApprovalStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'status': 'error', 'message': 'Not logged in'};
      }
      
      final doc = await _firestore.collection('pending_approvals').doc(user.uid).get();
      
      if (doc.exists) {
        return {
          'status': doc.data()?['status'] ?? 'pending',
          'message': doc.data()?['rejectionReason'] ?? '',
        };
      }
      
      return {'status': 'error', 'message': 'Approval record not found'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  
  // Delete account if approval is rejected and user wants to reapply
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }
      
      // Delete from pending_approvals collection
      await _firestore.collection('pending_approvals').doc(user.uid).delete();
      
      // Delete from users collection
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete the auth account
      await user.delete();
      
      notifyListeners();
    } catch (e) {
      print('Error in deleteAccount: $e'); // Debug log
      rethrow;
    }
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class StudentService extends ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   // Register a new student
//   Future<UserCredential> registerStudent({
//     required String email,
//     required String password,
//     required String name,
//     required String volunteerId,
//     required String bloodGroup,
//     required String place,
//     required String department,
//   }) async {
//     try {
//       // Create user account in Firebase Auth
//       final credential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
      
//       // If user creation successful, add details to Firestore
//       if (credential.user != null) {
//         // First add to users collection (with isApproved = false)
//         await _firestore.collection('users').doc(credential.user!.uid).set({
//           'name': name,
//           'email': email,
//           'isAdmin': false,
//           'isApproved': false,
//           'createdAt': FieldValue.serverTimestamp(),
//         });
        
//         // Then add detailed info to pending_approvals collection
//         await _firestore.collection('pending_approvals').doc(credential.user!.uid).set({
//           'name': name,
//           'email': email,
//           'volunteerId': volunteerId,
//           'bloodGroup': bloodGroup,
//           'place': place,
//           'department': department,
//           'createdAt': FieldValue.serverTimestamp(),
//           'status': 'pending', // Could be 'pending', 'approved', or 'rejected'
//         });
        
//         // Update display name
//         await credential.user!.updateDisplayName(name);
//       }
      
//       notifyListeners();
//       return credential;
//     } catch (e) {
//       rethrow;
//     }
//   }
  
//   // Get pending approval status
//   Future<Map<String, dynamic>> getApprovalStatus() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         return {'status': 'error', 'message': 'Not logged in'};
//       }
      
//       final doc = await _firestore.collection('pending_approvals').doc(user.uid).get();
      
//       if (doc.exists) {
//         return {
//           'status': doc.data()?['status'] ?? 'pending',
//           'message': doc.data()?['message'] ?? '',
//         };
//       }
      
//       return {'status': 'error', 'message': 'Approval record not found'};
//     } catch (e) {
//       return {'status': 'error', 'message': e.toString()};
//     }
//   }
  
//   // Delete account if approval is rejected and user wants to reapply
//   Future<void> deleteAccount() async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         throw Exception('Not logged in');
//       }
      
//       // Delete from pending_approvals collection
//       await _firestore.collection('pending_approvals').doc(user.uid).delete();
      
//       // Delete from users collection
//       await _firestore.collection('users').doc(user.uid).delete();
      
//       // Delete the auth account
//       await user.delete();
      
//       notifyListeners();
//     } catch (e) {
//       rethrow;
//     }
//   }
// }