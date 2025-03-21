import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nss_app/models/event_model.dart';
import 'package:nss_app/models/user_model.dart';

class EventService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection reference
  CollectionReference get _eventsCollection => _firestore.collection('events');
  
  // Stream of all events
  Stream<List<EventModel>> get eventsStream {
    return _eventsCollection
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _eventFromSnapshot(doc);
      }).toList();
    });
  }
  
  // Convert Firestore document to EventModel
  EventModel _eventFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    return EventModel(
      id: snapshot.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      maxParticipants: data['maxParticipants'] ?? 0,
      registeredParticipants: List<String>.from(data['registeredParticipants'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  
  // Get all events
  Future<List<EventModel>> getAllEvents() async {
    final snapshot = await _eventsCollection.orderBy('startDate', descending: false).get();
    return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
  }
  
  // Get event by ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();
      if (doc.exists) {
        return _eventFromSnapshot(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching event by ID: $e');
      return null;
    }
  }
  
  // Get event ID by title (helper method)
  Future<String?> getEventIdByTitle(String title) async {
    try {
      final snapshot = await _eventsCollection
          .where('title', isEqualTo: title)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error getting event ID by title: $e');
      return null;
    }
  }
  
  // Create new event
  Future<String> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String location,
    required int maxParticipants,
    required String createdBy,
  }) async {
    try {
      final docRef = await _eventsCollection.add({
        'title': title,
        'description': description,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'location': location,
        'maxParticipants': maxParticipants,
        'registeredParticipants': [],
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }
  
  // Update event
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String location,
    required int maxParticipants,
  }) async {
    try {
      await _eventsCollection.doc(eventId).update({
        'title': title,
        'description': description,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'location': location,
        'maxParticipants': maxParticipants,
      });
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }
  
  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }
  
  // Register for event
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      // First, update the event document with the new registered participant
      await _eventsCollection.doc(eventId).update({
        'registeredParticipants': FieldValue.arrayUnion([userId]),
      });
      
      // Then also update the user's eventsParticipated array
      final userDocRef = _firestore.collection('users').doc(userId);
      await userDocRef.update({
        'eventsParticipated': FieldValue.arrayUnion([eventId]),
      });
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to register for event: $e');
    }
  }
  
  // Remove registration
  Future<void> removeRegistration(String eventId, String userId) async {
    try {
      await _eventsCollection.doc(eventId).update({
        'registeredParticipants': FieldValue.arrayRemove([userId]),
      });
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to remove registration: $e');
    }
  }
  
  // Get registered users for an event
  Future<List<UserModel>> getRegisteredUsers(EventModel event) async {
    final registeredIds = event.registeredParticipants;
    if (registeredIds.isEmpty) {
      return [];
    }
    
    final usersCollection = _firestore.collection('users');
    
    try {
      // For small lists, this works fine. For very large lists of participants, 
      // you might need to implement batch fetching
      final userDocs = await usersCollection
          .where(FieldPath.documentId, whereIn: registeredIds)
          .get();
      
      return userDocs.docs.map((doc) {
        final data = doc.data();
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
          createdAt: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      // If there's an error with the query (like too many IDs for a whereIn clause)
      // fall back to individual queries
      List<UserModel> result = [];
      
      for (String userId in registeredIds) {
        try {
          final userDoc = await usersCollection.doc(userId).get();
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            result.add(UserModel(
              id: userDoc.id,
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
              createdAt: data['createdAt'] != null 
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
            ));
          }
        } catch (e) {
          // Skip any individual user fetch errors
          print('Error fetching user $userId: $e');
        }
      }
      
      return result;
    }
  }
  
  // Get upcoming events
  Future<List<EventModel>> getUpcomingEvents() async {
    final snapshot = await _eventsCollection
        .where('startDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('startDate')
        .get();
    
    return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
  }
  
  // Get ongoing events
  Future<List<EventModel>> getOngoingEvents() async {
    final now = Timestamp.fromDate(DateTime.now());
    
    final snapshot = await _eventsCollection
        .where('startDate', isLessThanOrEqualTo: now)
        .where('endDate', isGreaterThanOrEqualTo: now)
        .get();
    
    return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
  }
  
  // Get past events
  Future<List<EventModel>> getPastEvents() async {
    final snapshot = await _eventsCollection
        .where('endDate', isLessThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('endDate', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
  }
}







// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';

// class EventService extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   // Collection reference
//   CollectionReference get _eventsCollection => _firestore.collection('events');
  
//   // Stream of all events
//   Stream<List<EventModel>> get eventsStream {
//     return _eventsCollection
//         .orderBy('startDate', descending: false)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         return _eventFromSnapshot(doc);
//       }).toList();
//     });
//   }
  
//   // Convert Firestore document to EventModel
//   EventModel _eventFromSnapshot(DocumentSnapshot snapshot) {
//     final data = snapshot.data() as Map<String, dynamic>;
    
//     return EventModel(
//       id: snapshot.id,
//       title: data['title'] ?? '',
//       description: data['description'] ?? '',
//       startDate: (data['startDate'] as Timestamp).toDate(),
//       endDate: (data['endDate'] as Timestamp).toDate(),
//       location: data['location'] ?? '',
//       maxParticipants: data['maxParticipants'] ?? 0,
//       registeredParticipants: List<String>.from(data['registeredParticipants'] ?? []),
//       createdBy: data['createdBy'] ?? '',
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//     );
//   }
  
//   // Get all events
//   Future<List<EventModel>> getAllEvents() async {
//     final snapshot = await _eventsCollection.orderBy('startDate', descending: false).get();
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
  
//   // Get event by ID
//   Future<EventModel?> getEventById(String eventId) async {
//     try {
//       final doc = await _eventsCollection.doc(eventId).get();
//       if (doc.exists) {
//         return _eventFromSnapshot(doc);
//       }
//       return null;
//     } catch (e) {
//       print('Error fetching event by ID: $e');
//       return null;
//     }
//   }
  
//   // Get event ID by title (helper method)
//   Future<String?> getEventIdByTitle(String title) async {
//     try {
//       final snapshot = await _eventsCollection
//           .where('title', isEqualTo: title)
//           .limit(1)
//           .get();
      
//       if (snapshot.docs.isNotEmpty) {
//         return snapshot.docs.first.id;
//       }
//       return null;
//     } catch (e) {
//       print('Error getting event ID by title: $e');
//       return null;
//     }
//   }
  
//   // Create new event
//   Future<String> createEvent({
//     required String title,
//     required String description,
//     required DateTime startDate,
//     required DateTime endDate,
//     required String location,
//     required int maxParticipants,
//     required String createdBy,
//   }) async {
//     try {
//       final docRef = await _eventsCollection.add({
//         'title': title,
//         'description': description,
//         'startDate': Timestamp.fromDate(startDate),
//         'endDate': Timestamp.fromDate(endDate),
//         'location': location,
//         'maxParticipants': maxParticipants,
//         'registeredParticipants': [],
//         'createdBy': createdBy,
//         'createdAt': Timestamp.fromDate(DateTime.now()),
//       });
      
//       notifyListeners();
//       return docRef.id;
//     } catch (e) {
//       throw Exception('Failed to create event: $e');
//     }
//   }
  
//   // Update event
//   Future<void> updateEvent({
//     required String eventId,
//     required String title,
//     required String description,
//     required DateTime startDate,
//     required DateTime endDate,
//     required String location,
//     required int maxParticipants,
//   }) async {
//     try {
//       await _eventsCollection.doc(eventId).update({
//         'title': title,
//         'description': description,
//         'startDate': Timestamp.fromDate(startDate),
//         'endDate': Timestamp.fromDate(endDate),
//         'location': location,
//         'maxParticipants': maxParticipants,
//       });
      
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to update event: $e');
//     }
//   }
  
//   // Delete event
//   Future<void> deleteEvent(String eventId) async {
//     try {
//       await _eventsCollection.doc(eventId).delete();
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to delete event: $e');
//     }
//   }
  
//   // Register for event
//   Future<void> registerForEvent(String eventId, String userId) async {
//     try {
//       await _eventsCollection.doc(eventId).update({
//         'registeredParticipants': FieldValue.arrayUnion([userId]),
//       });
      
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to register for event: $e');
//     }
//   }
  
//   // Remove registration
//   Future<void> removeRegistration(String eventId, String userId) async {
//     try {
//       await _eventsCollection.doc(eventId).update({
//         'registeredParticipants': FieldValue.arrayRemove([userId]),
//       });
      
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to remove registration: $e');
//     }
//   }
  
//   // Get registered users for an event
//   Future<List<UserModel>> getRegisteredUsers(EventModel event) async {
//     final registeredIds = event.registeredParticipants;
//     if (registeredIds.isEmpty) {
//       return [];
//     }
    
//     final usersCollection = _firestore.collection('users');
    
//     try {
//       // For small lists, this works fine. For very large lists of participants, 
//       // you might need to implement batch fetching
//       final userDocs = await usersCollection
//           .where(FieldPath.documentId, whereIn: registeredIds)
//           .get();
      
//       return userDocs.docs.map((doc) {
//         final data = doc.data();
//         return UserModel(
//           id: doc.id,
//           name: data['name'] ?? '',
//           email: data['email'] ?? '',
//           volunteerId: data['volunteerId'] ?? '',
//           adminId: data['adminId'] ?? '',
//           bloodGroup: data['bloodGroup'] ?? '',
//           place: data['place'] ?? '',
//           department: data['department'] ?? '',
//           role: data['role'] ?? 'volunteer',
//           isApproved: data['isApproved'] ?? false,
//           eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
//           createdAt: data['createdAt'] != null 
//               ? (data['createdAt'] as Timestamp).toDate()
//               : DateTime.now(),
//         );
//       }).toList();
//     } catch (e) {
//       // If there's an error with the query (like too many IDs for a whereIn clause)
//       // fall back to individual queries
//       List<UserModel> result = [];
      
//       for (String userId in registeredIds) {
//         try {
//           final userDoc = await usersCollection.doc(userId).get();
//           if (userDoc.exists) {
//             final data = userDoc.data() as Map<String, dynamic>;
//             result.add(UserModel(
//               id: userDoc.id,
//               name: data['name'] ?? '',
//               email: data['email'] ?? '',
//               volunteerId: data['volunteerId'] ?? '',
//               adminId: data['adminId'] ?? '',
//               bloodGroup: data['bloodGroup'] ?? '',
//               place: data['place'] ?? '',
//               department: data['department'] ?? '',
//               role: data['role'] ?? 'volunteer',
//               isApproved: data['isApproved'] ?? false,
//               eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
//               createdAt: data['createdAt'] != null 
//                   ? (data['createdAt'] as Timestamp).toDate()
//                   : DateTime.now(),
//             ));
//           }
//         } catch (e) {
//           // Skip any individual user fetch errors
//           print('Error fetching user $userId: $e');
//         }
//       }
      
//       return result;
//     }
//   }
  
//   // Get upcoming events
//   Future<List<EventModel>> getUpcomingEvents() async {
//     final snapshot = await _eventsCollection
//         .where('startDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
//         .orderBy('startDate')
//         .get();
    
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
  
//   // Get ongoing events
//   Future<List<EventModel>> getOngoingEvents() async {
//     final now = Timestamp.fromDate(DateTime.now());
    
//     final snapshot = await _eventsCollection
//         .where('startDate', isLessThanOrEqualTo: now)
//         .where('endDate', isGreaterThanOrEqualTo: now)
//         .get();
    
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
  
//   // Get past events
//   Future<List<EventModel>> getPastEvents() async {
//     final snapshot = await _eventsCollection
//         .where('endDate', isLessThan: Timestamp.fromDate(DateTime.now()))
//         .orderBy('endDate', descending: true)
//         .get();
    
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
// }








// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';

// class EventService extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   // Collection reference
//   CollectionReference get _eventsCollection => _firestore.collection('events');
  
//   // Stream of all events
//   Stream<List<EventModel>> get eventsStream {
//     return _eventsCollection
//         .orderBy('startDate', descending: false)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         return _eventFromSnapshot(doc);
//       }).toList();
//     });
//   }
  
//   // Convert Firestore document to EventModel
//   EventModel _eventFromSnapshot(DocumentSnapshot snapshot) {
//     final data = snapshot.data() as Map<String, dynamic>;
    
//     return EventModel(
//       id: snapshot.id,
//       title: data['title'] ?? '',
//       description: data['description'] ?? '',
//       startDate: (data['startDate'] as Timestamp).toDate(),
//       endDate: (data['endDate'] as Timestamp).toDate(),
//       location: data['location'] ?? '',
//       maxParticipants: data['maxParticipants'] ?? 0,
//       registeredParticipants: List<String>.from(data['registeredParticipants'] ?? []),
//       createdBy: data['createdBy'] ?? '',
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//     );
//   }
  
//   // Get all events
//   Future<List<EventModel>> getAllEvents() async {
//     final snapshot = await _eventsCollection.orderBy('startDate', descending: false).get();
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
  
//   // Get event by ID
//   Future<EventModel?> getEventById(String eventId) async {
//     final doc = await _eventsCollection.doc(eventId).get();
//     if (doc.exists) {
//       return _eventFromSnapshot(doc);
//     }
//     return null;
//   }
  
//   // Create new event
//   Future<String> createEvent({
//     required String title,
//     required String description,
//     required DateTime startDate,
//     required DateTime endDate,
//     required String location,
//     required int maxParticipants,
//     required String createdBy,
//   }) async {
//     try {
//       final docRef = await _eventsCollection.add({
//         'title': title,
//         'description': description,
//         'startDate': Timestamp.fromDate(startDate),
//         'endDate': Timestamp.fromDate(endDate),
//         'location': location,
//         'maxParticipants': maxParticipants,
//         'registeredParticipants': [],
//         'createdBy': createdBy,
//         'createdAt': Timestamp.fromDate(DateTime.now()),
//       });
      
//       notifyListeners();
//       return docRef.id;
//     } catch (e) {
//       throw Exception('Failed to create event: $e');
//     }
//   }
  
//   // Update event
//   Future<void> updateEvent({
//     required String eventId,
//     required String title,
//     required String description,
//     required DateTime startDate,
//     required DateTime endDate,
//     required String location,
//     required int maxParticipants,
//   }) async {
//     try {
//       await _eventsCollection.doc(eventId).update({
//         'title': title,
//         'description': description,
//         'startDate': Timestamp.fromDate(startDate),
//         'endDate': Timestamp.fromDate(endDate),
//         'location': location,
//         'maxParticipants': maxParticipants,
//       });
      
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to update event: $e');
//     }
//   }
  
//   // Delete event
//   Future<void> deleteEvent(String eventId) async {
//     try {
//       await _eventsCollection.doc(eventId).delete();
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to delete event: $e');
//     }
//   }
  
//   // Register for event
//   Future<void> registerForEvent(String eventId, String userId) async {
//     try {
//       await _eventsCollection.doc(eventId).update({
//         'registeredParticipants': FieldValue.arrayUnion([userId]),
//       });
      
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to register for event: $e');
//     }
//   }
  
//   // Remove registration
//   Future<void> removeRegistration(String eventId, String userId) async {
//     try {
//       await _eventsCollection.doc(eventId).update({
//         'registeredParticipants': FieldValue.arrayRemove([userId]),
//       });
      
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to remove registration: $e');
//     }
//   }
  
//   // Get registered users for an event
//   Future<List<UserModel>> getRegisteredUsers(EventModel event) async {
//     final registeredIds = event.registeredParticipants;
//     if (registeredIds.isEmpty) {
//       return [];
//     }
    
//     final usersCollection = _firestore.collection('users');
    
//     try {
//       // For small lists, this works fine. For very large lists of participants, 
//       // you might need to implement batch fetching
//       final userDocs = await usersCollection
//           .where(FieldPath.documentId, whereIn: registeredIds)
//           .get();
      
//       return userDocs.docs.map((doc) {
//         final data = doc.data();
//         return UserModel(
//           id: doc.id,
//           name: data['name'] ?? '',
//           email: data['email'] ?? '',
//           volunteerId: data['volunteerId'] ?? '',
//           adminId: data['adminId'] ?? '',
//           bloodGroup: data['bloodGroup'] ?? '',
//           place: data['place'] ?? '',
//           department: data['department'] ?? '',
//           role: data['role'] ?? 'volunteer',
//           isApproved: data['isApproved'] ?? false,
//           eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
//           createdAt: data['createdAt'] != null 
//               ? (data['createdAt'] as Timestamp).toDate()
//               : DateTime.now(),
//         );
//       }).toList();
//     } catch (e) {
//       // If there's an error with the query (like too many IDs for a whereIn clause)
//       // fall back to individual queries
//       List<UserModel> result = [];
      
//       for (String userId in registeredIds) {
//         try {
//           final userDoc = await usersCollection.doc(userId).get();
//           if (userDoc.exists) {
//             final data = userDoc.data() as Map<String, dynamic>;
//             result.add(UserModel(
//               id: userDoc.id,
//               name: data['name'] ?? '',
//               email: data['email'] ?? '',
//               volunteerId: data['volunteerId'] ?? '',
//               adminId: data['adminId'] ?? '',
//               bloodGroup: data['bloodGroup'] ?? '',
//               place: data['place'] ?? '',
//               department: data['department'] ?? '',
//               role: data['role'] ?? 'volunteer',
//               isApproved: data['isApproved'] ?? false,
//               eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
//               createdAt: data['createdAt'] != null 
//                   ? (data['createdAt'] as Timestamp).toDate()
//                   : DateTime.now(),
//             ));
//           }
//         } catch (e) {
//           // Skip any individual user fetch errors
//           print('Error fetching user $userId: $e');
//         }
//       }
      
//       return result;
//     }
//   }
  
//   // Get upcoming events
//   Future<List<EventModel>> getUpcomingEvents() async {
//     final snapshot = await _eventsCollection
//         .where('startDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
//         .orderBy('startDate')
//         .get();
    
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
  
//   // Get ongoing events
//   Future<List<EventModel>> getOngoingEvents() async {
//     final now = Timestamp.fromDate(DateTime.now());
    
//     final snapshot = await _eventsCollection
//         .where('startDate', isLessThanOrEqualTo: now)
//         .where('endDate', isGreaterThanOrEqualTo: now)
//         .get();
    
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
  
//   // Get past events
//   Future<List<EventModel>> getPastEvents() async {
//     final snapshot = await _eventsCollection
//         .where('endDate', isLessThan: Timestamp.fromDate(DateTime.now()))
//         .orderBy('endDate', descending: true)
//         .get();
    
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
// }






// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';

// class EventService extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   // Collection reference
//   CollectionReference get _eventsCollection => _firestore.collection('events');
  
//   // Stream of all events
//   Stream<List<EventModel>> get eventsStream {
//     return _eventsCollection
//         .orderBy('startDate', descending: false)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         return _eventFromSnapshot(doc);
//       }).toList();
//     });
//   }
  
//   // Convert Firestore document to EventModel
//   EventModel _eventFromSnapshot(DocumentSnapshot snapshot) {
//     final data = snapshot.data() as Map<String, dynamic>;
    
//     return EventModel(
//       id: snapshot.id,
//       title: data['title'] ?? '',
//       description: data['description'] ?? '',
//       startDate: (data['startDate'] as Timestamp).toDate(),
//       endDate: (data['endDate'] as Timestamp).toDate(),
//       location: data['location'] ?? '',
//       maxParticipants: data['maxParticipants'] ?? 0,
//       registeredParticipants: List<String>.from(data['registeredParticipants'] ?? []),
//       createdBy: data['createdBy'] ?? '',
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//     );
//   }
  
//   // Get all events
//   Future<List<EventModel>> getAllEvents() async {
//     final snapshot = await _eventsCollection.orderBy('startDate', descending: false).get();
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
  
//   // Get event by ID
//   Future<EventModel?> getEventById(String eventId) async {
//     final doc = await _eventsCollection.doc(eventId).get();
//     if (doc.exists) {
//       return _eventFromSnapshot(doc);
//     }
//     return null;
//   }
  
//   // Create new event
//   Future<String> createEvent({
//     required String title,
//     required String description,
//     required DateTime startDate,
//     required DateTime endDate,
//     required String location,
//     required int maxParticipants,
//     required String createdBy,
//   }) async {
//     try {
//       final docRef = await _eventsCollection.add({
//         'title': title,
//         'description': description,
//         'startDate': Timestamp.fromDate(startDate),
//         'endDate': Timestamp.fromDate(endDate),
//         'location': location,
//         'maxParticipants': maxParticipants,
//         'registeredParticipants': [],
//         'createdBy': createdBy,
//         'createdAt': Timestamp.fromDate(DateTime.now()),
//       });
      
//       notifyListeners();
//       return docRef.id;
//     } catch (e) {
//       throw Exception('Failed to create event: $e');
//     }
//   }
  
//   // Update event
//   Future<void> updateEvent({
//     required String eventId,
//     required String title,
//     required String description,
//     required DateTime startDate,
//     required DateTime endDate,
//     required String location,
//     required int maxParticipants,
//   }) async {
//     try {
//       await _eventsCollection.doc(eventId).update({
//         'title': title,
//         'description': description,
//         'startDate': Timestamp.fromDate(startDate),
//         'endDate': Timestamp.fromDate(endDate),
//         'location': location,
//         'maxParticipants': maxParticipants,
//       });
      
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to update event: $e');
//     }
//   }
  
//   // Delete event
//   Future<void> deleteEvent(String eventId) async {
//     try {
//       await _eventsCollection.doc(eventId).delete();
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to delete event: $e');
//     }
//   }
  
//   // Register for event
//   Future<void> registerForEvent(String eventId, String userId) async {
//     try {
//       await _eventsCollection.doc(eventId).update({
//         'registeredParticipants': FieldValue.arrayUnion([userId]),
//       });
      
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to register for event: $e');
//     }
//   }
  
//   // Remove registration
//   Future<void> removeRegistration(String eventId, String userId) async {
//     try {
//       await _eventsCollection.doc(eventId).update({
//         'registeredParticipants': FieldValue.arrayRemove([userId]),
//       });
      
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to remove registration: $e');
//     }
//   }
  
//   // Get registered users for an event
//   Future<List<UserModel>> getRegisteredUsers(EventModel event) async {
//     final registeredIds = event.registeredParticipants;
//     if (registeredIds.isEmpty) {
//       return [];
//     }
    
//     final usersCollection = _firestore.collection('users');
    
//     try {
//       // For small lists, this works fine. For very large lists of participants, 
//       // you might need to implement batch fetching
//       final userDocs = await usersCollection
//           .where(FieldPath.documentId, whereIn: registeredIds)
//           .get();
      
//       return userDocs.docs.map((doc) {
//         final data = doc.data();
//         return UserModel(
//           id: doc.id,
//           name: data['name'] ?? '',
//           email: data['email'] ?? '',
//           volunteerId: data['volunteerId'] ?? '',
//           adminId: data['adminId'] ?? '',
//           bloodGroup: data['bloodGroup'] ?? '',
//           place: data['place'] ?? '',
//           department: data['department'] ?? '',
//           role: data['role'] ?? 'volunteer',
//           isApproved: data['isApproved'] ?? false,
//           eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
//           createdAt: data['createdAt'] != null 
//               ? (data['createdAt'] as Timestamp).toDate()
//               : DateTime.now(),
//         );
//       }).toList();
//     } catch (e) {
//       // If there's an error with the query (like too many IDs for a whereIn clause)
//       // fall back to individual queries
//       List<UserModel> result = [];
      
//       for (String userId in registeredIds) {
//         try {
//           final userDoc = await usersCollection.doc(userId).get();
//           if (userDoc.exists) {
//             final data = userDoc.data() as Map<String, dynamic>;
//             result.add(UserModel(
//               id: userDoc.id,
//               name: data['name'] ?? '',
//               email: data['email'] ?? '',
//               volunteerId: data['volunteerId'] ?? '',
//               adminId: data['adminId'] ?? '',
//               bloodGroup: data['bloodGroup'] ?? '',
//               place: data['place'] ?? '',
//               department: data['department'] ?? '',
//               role: data['role'] ?? 'volunteer',
//               isApproved: data['isApproved'] ?? false,
//               eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
//               createdAt: data['createdAt'] != null 
//                   ? (data['createdAt'] as Timestamp).toDate()
//                   : DateTime.now(),
//             ));
//           }
//         } catch (e) {
//           // Skip any individual user fetch errors
//           print('Error fetching user $userId: $e');
//         }
//       }
      
//       return result;
//     }
//   }
  
//   // Get upcoming events
//   Future<List<EventModel>> getUpcomingEvents() async {
//     final snapshot = await _eventsCollection
//         .where('startDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
//         .orderBy('startDate')
//         .get();
    
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
  
//   // Get ongoing events
//   Future<List<EventModel>> getOngoingEvents() async {
//     final now = Timestamp.fromDate(DateTime.now());
    
//     final snapshot = await _eventsCollection
//         .where('startDate', isLessThanOrEqualTo: now)
//         .where('endDate', isGreaterThanOrEqualTo: now)
//         .get();
    
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
  
//   // Get past events
//   Future<List<EventModel>> getPastEvents() async {
//     final snapshot = await _eventsCollection
//         .where('endDate', isLessThan: Timestamp.fromDate(DateTime.now()))
//         .orderBy('endDate', descending: true)
//         .get();
    
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
// }




// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:nss_app/models/event_model.dart';
// import 'package:nss_app/models/user_model.dart';

// class EventService extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   // Collection reference
//   CollectionReference get _eventsCollection => _firestore.collection('events');
  
//   // Stream of all events
//   Stream<List<EventModel>> get eventsStream {
//     return _eventsCollection
//         .orderBy('startDate', descending: false)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.map((doc) {
//         return _eventFromSnapshot(doc);
//       }).toList();
//     });
//   }
  
//   // Convert Firestore document to EventModel
//   EventModel _eventFromSnapshot(DocumentSnapshot snapshot) {
//     final data = snapshot.data() as Map<String, dynamic>;
    
//     return EventModel(
//       id: snapshot.id,
//       title: data['title'] ?? '',
//       description: data['description'] ?? '',
//       startDate: (data['startDate'] as Timestamp).toDate(),
//       endDate: (data['endDate'] as Timestamp).toDate(),
//       location: data['location'] ?? '',
//       maxParticipants: data['maxParticipants'] ?? 0,
//       registeredParticipants: List<String>.from(data['registeredParticipants'] ?? []),
//       createdBy: data['createdBy'] ?? '',
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//     );
//   }
  
//   // Get all events
//   Future<List<EventModel>> getAllEvents() async {
//     final snapshot = await _eventsCollection.orderBy('startDate', descending: false).get();
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
  
//   // Get event by ID
//   Future<EventModel?> getEventById(String eventId) async {
//     final doc = await _eventsCollection.doc(eventId).get();
//     if (doc.exists) {
//       return _eventFromSnapshot(doc);
//     }
//     return null;
//   }
  
//   // Create new event
//   Future<String> createEvent({
//     required String title,
//     required String description,
//     required DateTime startDate,
//     required DateTime endDate,
//     required String location,
//     required int maxParticipants,
//     required String createdBy,
//   }) async {
//     try {
//       final docRef = await _eventsCollection.add({
//         'title': title,
//         'description': description,
//         'startDate': Timestamp.fromDate(startDate),
//         'endDate': Timestamp.fromDate(endDate),
//         'location': location,
//         'maxParticipants': maxParticipants,
//         'registeredParticipants': [],
//         'createdBy': createdBy,
//         'createdAt': Timestamp.fromDate(DateTime.now()),
//       });
      
//       notifyListeners();
//       return docRef.id;
//     } catch (e) {
//       throw Exception('Failed to create event: $e');
//     }
//   }
  
//   // Update event
//   Future<void> updateEvent({
//     required String eventId,
//     required String title,
//     required String description,
//     required DateTime startDate,
//     required DateTime endDate,
//     required String location,
//     required int maxParticipants,
//   }) async {
//     try {
//       await _eventsCollection.doc(eventId).update({
//         'title': title,
//         'description': description,
//         'startDate': Timestamp.fromDate(startDate),
//         'endDate': Timestamp.fromDate(endDate),
//         'location': location,
//         'maxParticipants': maxParticipants,
//       });
      
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to update event: $e');
//     }
//   }
  
//   // Delete event
//   Future<void> deleteEvent(String eventId) async {
//     try {
//       await _eventsCollection.doc(eventId).delete();
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to delete event: $e');
//     }
//   }
  
//   // Register for event
//   Future<void> registerForEvent(String eventId, String userId) async {
//     try {
//       await _eventsCollection.doc(eventId).update({
//         'registeredParticipants': FieldValue.arrayUnion([userId]),
//       });
      
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to register for event: $e');
//     }
//   }
  
//   // Remove registration
//   Future<void> removeRegistration(String eventId, String userId) async {
//     try {
//       await _eventsCollection.doc(eventId).update({
//         'registeredParticipants': FieldValue.arrayRemove([userId]),
//       });
      
//       notifyListeners();
//     } catch (e) {
//       throw Exception('Failed to remove registration: $e');
//     }
//   }
  
//   // Get registered users for an event
//   Future<List<UserModel>> getRegisteredUsers(EventModel event) async {
//     final registeredIds = event.registeredParticipants;
//     if (registeredIds.isEmpty) {
//       return [];
//     }
    
//     final usersCollection = _firestore.collection('users');
    
//     try {
//       // For small lists, this works fine. For very large lists of participants, 
//       // you might need to implement batch fetching
//       final userDocs = await usersCollection
//           .where(FieldPath.documentId, whereIn: registeredIds)
//           .get();
      
//       return userDocs.docs.map((doc) {
//         final data = doc.data();
//         return UserModel(
//           id: doc.id,
//           name: data['name'] ?? '',
//           email: data['email'] ?? '',
//           volunteerId: data['volunteerId'] ?? '',
//           adminId: data['adminId'] ?? '',
//           bloodGroup: data['bloodGroup'] ?? '',
//           place: data['place'] ?? '',
//           department: data['department'] ?? '',
//           role: data['role'] ?? 'volunteer',
//           isApproved: data['isApproved'] ?? false,
//           eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
//           createdAt: data['createdAt'] != null 
//               ? (data['createdAt'] as Timestamp).toDate()
//               : DateTime.now(),
//         );
//       }).toList();
//     } catch (e) {
//       // If there's an error with the query (like too many IDs for a whereIn clause)
//       // fall back to individual queries
//       List<UserModel> result = [];
      
//       for (String userId in registeredIds) {
//         try {
//           final userDoc = await usersCollection.doc(userId).get();
//           if (userDoc.exists) {
//             final data = userDoc.data() as Map<String, dynamic>;
//             result.add(UserModel(
//               id: userDoc.id,
//               name: data['name'] ?? '',
//               email: data['email'] ?? '',
//               volunteerId: data['volunteerId'] ?? '',
//               adminId: data['adminId'] ?? '',
//               bloodGroup: data['bloodGroup'] ?? '',
//               place: data['place'] ?? '',
//               department: data['department'] ?? '',
//               role: data['role'] ?? 'volunteer',
//               isApproved: data['isApproved'] ?? false,
//               eventsParticipated: List<String>.from(data['eventsParticipated'] ?? []),
//               createdAt: data['createdAt'] != null 
//                   ? (data['createdAt'] as Timestamp).toDate()
//                   : DateTime.now(),
//             ));
//           }
//         } catch (e) {
//           // Skip any individual user fetch errors
//           print('Error fetching user $userId: $e');
//         }
//       }
      
//       return result;
//     }
//   }
  
//   // Get upcoming events
//   Future<List<EventModel>> getUpcomingEvents() async {
//     final snapshot = await _eventsCollection
//         .where('startDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
//         .orderBy('startDate')
//         .get();
    
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
  
//   // Get ongoing events
//   Future<List<EventModel>> getOngoingEvents() async {
//     final now = Timestamp.fromDate(DateTime.now());
    
//     final snapshot = await _eventsCollection
//         .where('startDate', isLessThanOrEqualTo: now)
//         .where('endDate', isGreaterThanOrEqualTo: now)
//         .get();
    
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
  
//   // Get past events
//   Future<List<EventModel>> getPastEvents() async {
//     final snapshot = await _eventsCollection
//         .where('endDate', isLessThan: Timestamp.fromDate(DateTime.now()))
//         .orderBy('endDate', descending: true)
//         .get();
    
//     return snapshot.docs.map((doc) => _eventFromSnapshot(doc)).toList();
//   }
// }