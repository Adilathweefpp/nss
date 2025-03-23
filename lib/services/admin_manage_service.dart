import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nss_app/models/user_model.dart';

class AdminManageService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Migrate existing admins to the new structure if needed
  Future<void> migrateExistingAdmins() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
          
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String? uid = data['uid'];
        final String email = data['email'] ?? '';
        
        // If there's a UID but the document ID doesn't match it
        if (uid != null && uid.isNotEmpty && doc.id != uid) {
          print('Migrating admin document for: $email');
          
          // Create a new document with the correct ID
          await _firestore.collection('users').doc(uid).set(data);
          
          // Delete the old document
          await _firestore.collection('users').doc(doc.id).delete();
          
          print('Migration complete for: $email');
        }
      }
    } catch (e) {
      print('Error migrating admins: $e');
    }
  }

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

  // Check and fix admin profile for currently logged in user
  Future<bool> checkAndFixCurrentAdminProfile() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No user logged in to check profile');
        return false;
      }
      
      // First check if document exists with Auth UID
      final docSnap = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (docSnap.exists) {
        print('Admin profile already exists with correct structure');
        return true;
      }
      
      // If not, look for documents with matching email
      final QuerySnapshot emailSnap = await _firestore
          .collection('users')
          .where('email', isEqualTo: currentUser.email)
          .get();
          
      if (emailSnap.docs.isEmpty) {
        print('No admin profile found for current user');
        return false;
      }
      
      // Get the first matching document
      final oldDoc = emailSnap.docs.first;
      final oldData = oldDoc.data() as Map<String, dynamic>;
      
      // Create a new document with the correct ID
      await _firestore.collection('users').doc(currentUser.uid).set({
        ...oldData,
        'uid': currentUser.uid, // Ensure UID is set
      });
      
      // If it's a different document, delete the old one
      if (oldDoc.id != currentUser.uid) {
        await _firestore.collection('users').doc(oldDoc.id).delete();
      }
      
      print('Fixed admin profile structure');
      return true;
    } catch (e) {
      print('Error checking/fixing admin profile: $e');
      return false;
    }
  }
  
  // Add new admin to Firestore and Firebase Authentication
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
      // Check if admin with same email already exists in Firestore
      final QuerySnapshot existingEmail = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingEmail.docs.isNotEmpty) {
        return false;
      }

      // First create the user in Firebase Authentication
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update the user display name in Authentication
      await userCredential.user?.updateDisplayName(name);

      // Create new admin document in Firestore using the Auth UID as document ID
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
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
        'uid': userCredential.user?.uid, // Store the Firebase Auth UID
        // Don't store password in Firestore as it's now managed by Firebase Auth
      });

      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding admin: $e');
      return false;
    }
  }

  // Remove admin from Firestore and Firebase Authentication
  Future<bool> removeAdmin(String adminId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('adminId', isEqualTo: adminId)
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }
      
      // The document ID is the same as the Auth UID
      final String uid = snapshot.docs.first.id;
      
      // Delete from Firestore
      await _firestore.collection('users').doc(uid).delete();
      
      // Delete from Firebase Authentication if UID exists
      try {
        // Note: This requires admin SDK or custom auth tokens in production
        // For client-side deletion, the user needs to be recently authenticated
        User? currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == uid) {
          await currentUser.delete();
        } else {
          // You might need to implement a Cloud Function to delete users
          // from Authentication when not signed in as that user
          print('Warning: Cannot delete Authentication user. User not currently signed in.');
        }
      } catch (authError) {
        print('Error removing user from Authentication: $authError');
        // Continue with function as we've already deleted from Firestore
      }
          
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



















// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:nss_app/models/user_model.dart';

// class AdminManageService extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Get all admins from Firestore
//   Future<List<UserModel>> getAdmins() async {
//     try {
//       final QuerySnapshot snapshot = await _firestore
//           .collection('users')
//           .where('role', isEqualTo: 'admin')
//           .get();

//       return snapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return UserModel(
//           id: doc.id,
//           name: data['name'] ?? '',
//           email: data['email'] ?? '',
//           volunteerId: data['volunteerId'] ?? '',
//           adminId: data['adminId'] ?? '',
//           bloodGroup: data['bloodGroup'] ?? '',
//           place: data['place'] ?? '',
//           department: data['department'] ?? '',
//           role: data['role'] ?? 'admin',
//           isApproved: data['isApproved'] ?? true,
//           eventsParticipated:
//               List<String>.from(data['eventsParticipated'] ?? []),
//           createdAt:
//               (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//         );
//       }).toList();
//     } catch (e) {
//       print('Error getting admins: $e');
//       return [];
//     }
//   }

//   // Add new admin to Firestore and Firebase Authentication
//   Future<bool> addAdmin({
//     required String name,
//     required String email,
//     required String adminId,
//     required String department,
//     required String password,
//     String bloodGroup = '',
//     String place = '',
//   }) async {
//     try {
//       // Check if admin with same email already exists in Firestore
//       final QuerySnapshot existingEmail = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       if (existingEmail.docs.isNotEmpty) {
//         return false;
//       }

//       // First create the user in Firebase Authentication
//       final UserCredential userCredential =
//           await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       // Update the user display name in Authentication
//       await userCredential.user?.updateDisplayName(name);

//       // Create new admin document in Firestore with the Auth UID
//       await _firestore.collection('users').add({
//         'name': name,
//         'email': email,
//         'adminId': adminId,
//         'volunteerId': '',
//         'bloodGroup': bloodGroup,
//         'place': place,
//         'department': department,
//         'role': 'admin',
//         'isApproved': true,
//         'eventsParticipated': [],
//         'createdAt': FieldValue.serverTimestamp(),
//         'uid': userCredential.user?.uid, // Store the Firebase Auth UID
//         // Don't store password in Firestore as it's now managed by Firebase Auth
//       });

//       notifyListeners();
//       return true;
//     } catch (e) {
//       print('Error adding admin: $e');
//       return false;
//     }
//   }

//   // Remove admin from Firestore and Firebase Authentication
//   Future<bool> removeAdmin(String adminId) async {
//     try {
//       final QuerySnapshot snapshot = await _firestore
//           .collection('users')
//           .where('adminId', isEqualTo: adminId)
//           .get();

//       if (snapshot.docs.isEmpty) {
//         return false;
//       }

//       final userData = snapshot.docs.first.data() as Map<String, dynamic>;
//       final String? uid = userData['uid'];

//       // Delete from Firestore
//       await _firestore.collection('users').doc(snapshot.docs.first.id).delete();

//       // Delete from Firebase Authentication if UID exists
//       if (uid != null) {
//         try {
//           // Note: This requires admin SDK or custom auth tokens in production
//           // For client-side deletion, the user needs to be recently authenticated
//           User? currentUser = _auth.currentUser;
//           if (currentUser != null && currentUser.uid == uid) {
//             await currentUser.delete();
//           } else {
//             // You might need to implement a Cloud Function to delete users
//             // from Authentication when not signed in as that user
//             print(
//                 'Warning: Cannot delete Authentication user. User not currently signed in.');
//           }
//         } catch (authError) {
//           print('Error removing user from Authentication: $authError');
//           // Continue with function as we've already deleted from Firestore
//         }
//       }

//       notifyListeners();
//       return true;
//     } catch (e) {
//       print('Error removing admin: $e');
//       return false;
//     }
//   }

//   // Generate unique admin ID suggestion
//   Future<String> generateUniqueAdminId() async {
//     try {
//       final QuerySnapshot snapshot = await _firestore
//           .collection('users')
//           .where('role', isEqualTo: 'admin')
//           .get();

//       final int count = snapshot.docs.length + 1;
//       return 'NSS-ADMIN-${count.toString().padLeft(3, '0')}';
//     } catch (e) {
//       print('Error generating admin ID: $e');
//       return 'NSS-ADMIN-001';
//     }
//   }

//   // Check if admin ID already exists
//   Future<bool> isAdminIdUnique(String adminId) async {
//     try {
//       final QuerySnapshot snapshot = await _firestore
//           .collection('users')
//           .where('adminId', isEqualTo: adminId)
//           .get();

//       return snapshot.docs.isEmpty;
//     } catch (e) {
//       print('Error checking admin ID uniqueness: $e');
//       return false;
//     }
//   }
// }











// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:nss_app/models/user_model.dart';

// class AdminManageService extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Get all admins from Firestore
//   Future<List<UserModel>> getAdmins() async {
//     try {
//       final QuerySnapshot snapshot = await _firestore
//           .collection('users')
//           .where('role', isEqualTo: 'admin')
//           .get();

//       return snapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return UserModel(
//           id: doc.id,
//           name: data['name'] ?? '',
//           email: data['email'] ?? '',
//           volunteerId: data['volunteerId'] ?? '',
//           adminId: data['adminId'] ?? '',
//           bloodGroup: data['bloodGroup'] ?? '',
//           place: data['place'] ?? '',
//           department: data['department'] ?? '',
//           role: data['role'] ?? 'admin',
//           isApproved: data['isApproved'] ?? true,
//           eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
//           createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//         );
//       }).toList();
//     } catch (e) {
//       print('Error getting admins: $e');
//       return [];
//     }
//   }

//   // Add new admin to Firestore
//   Future<bool> addAdmin({
//     required String name,
//     required String email,
//     required String adminId,
//     required String department,
//     required String password,
//     String bloodGroup = '',
//     String place = '',
//   }) async {
//     try {
//       // Check if admin with same email already exists
//       final QuerySnapshot existingEmail = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();

//       if (existingEmail.docs.isNotEmpty) {
//         return false;
//       }

//       // Create new admin document
//       await _firestore.collection('users').add({
//         'name': name,
//         'email': email,
//         'adminId': adminId,
//         'volunteerId': '',
//         'bloodGroup': bloodGroup,
//         'place': place,
//         'department': department,
//         'role': 'admin',
//         'isApproved': true,
//         'eventsParticipated': [],
//         'createdAt': FieldValue.serverTimestamp(),
//         'password': password, // Note: In a real app, you would handle authentication through Firebase Auth
//       });

//       notifyListeners();
//       return true;
//     } catch (e) {
//       print('Error adding admin: $e');
//       return false;
//     }
//   }

//   // Remove admin from Firestore
//   Future<bool> removeAdmin(String adminId) async {
//     try {
//       final QuerySnapshot snapshot = await _firestore
//           .collection('users')
//           .where('adminId', isEqualTo: adminId)
//           .get();

//       if (snapshot.docs.isEmpty) {
//         return false;
//       }

//       await _firestore.collection('users').doc(snapshot.docs.first.id).delete();
      
//       notifyListeners();
//       return true;
//     } catch (e) {
//       print('Error removing admin: $e');
//       return false;
//     }
//   }

//   // Generate unique admin ID suggestion
//   Future<String> generateUniqueAdminId() async {
//     try {
//       final QuerySnapshot snapshot = await _firestore
//           .collection('users')
//           .where('role', isEqualTo: 'admin')
//           .get();

//       final int count = snapshot.docs.length + 1;
//       return 'NSS-ADMIN-${count.toString().padLeft(3, '0')}';
//     } catch (e) {
//       print('Error generating admin ID: $e');
//       return 'NSS-ADMIN-001';
//     }
//   }
  
//   // Check if admin ID already exists
//   Future<bool> isAdminIdUnique(String adminId) async {
//     try {
//       final QuerySnapshot snapshot = await _firestore
//           .collection('users')
//           .where('adminId', isEqualTo: adminId)
//           .get();
          
//       return snapshot.docs.isEmpty;
//     } catch (e) {
//       print('Error checking admin ID uniqueness: $e');
//       return false;
//     }
//   }
// }