import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Login with email and password - with role parameter
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
    String role = 'student', // Default role is student
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // If logging in as admin from admin screen, update the user's role in Firestore
      if (role == 'admin') {
        await _updateUserRole(credential.user!.uid, true);
      }
      
      notifyListeners();
      return credential;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update user role
  Future<void> _updateUserRole(String userId, bool isAdmin) async {
    try {
      // Check if user document exists
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        // Only update if necessary (if user is not already an admin)
        if (userDoc.data()?['isAdmin'] != isAdmin) {
          await _firestore.collection('users').doc(userId).update({
            'isAdmin': isAdmin,
            'isApproved': true, // Admin users are automatically approved
          });
        }
      } else {
        // Create user document if it doesn't exist
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(userId).set({
            'name': user.displayName ?? 'Admin User',
            'email': user.email,
            'isAdmin': isAdmin,
            'isApproved': true, // Admin users are automatically approved
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      // Handle any errors but don't rethrow to avoid breaking the login flow
      debugPrint('Error updating user role: $e');
    }
  }
  
  // Sign up with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required bool isAdmin,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'isAdmin': isAdmin,
          'isApproved': isAdmin, // Admins are auto-approved, volunteers need approval
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Update display name
        await credential.user!.updateDisplayName(name);
      }
      
      notifyListeners();
      return credential;
    } catch (e) {
      rethrow;
    }
  }
  
  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Check if this is a first time login
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        // Create user document for new users
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'isAdmin': false, // Google sign-in users are volunteers by default
          'isApproved': false, // Need admin approval
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      notifyListeners();
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      // Check if the current user signed in with Google
      final providerData = _auth.currentUser?.providerData;
      final isGoogleUser = providerData?.any((info) => 
          info.providerId == 'google.com') ?? false;
      
      // Only sign out from Google if the user signed in with Google
      if (isGoogleUser) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Firebase Auth
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow;
    }
  }
  
  // Check user role and approval status
  Future<Map<String, dynamic>> getUserData() async {
    try {
      if (currentUser == null) {
        return {'isAdmin': false, 'isApproved': false};
      }
      
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        return {
          'isAdmin': doc.data()?['isAdmin'] ?? false,
          'isApproved': doc.data()?['isApproved'] ?? false,
        };
      }
      
      return {'isAdmin': false, 'isApproved': false};
    } catch (e) {
      return {'isAdmin': false, 'isApproved': false};
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}