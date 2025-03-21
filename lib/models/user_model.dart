class UserModel {
  final String id;
  final String name;
  final String email;
  final String volunteerId;
  final String adminId; // Added admin_id field
  final String bloodGroup;
  final String place;
  final String department;
  final String role; // 'volunteer' or 'admin'
  final bool isApproved;
  final List<String> eventsParticipated;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.volunteerId,
    this.adminId = '', // New field with default empty value
    required this.bloodGroup,
    required this.place,
    required this.department,
    required this.role,
    this.isApproved = false,
    this.eventsParticipated = const [],
    required this.createdAt,
  });

  // Mock data for UI development
  static List<UserModel> getMockVolunteers() {
    return [
      UserModel(
        id: '1',
        name: 'Adil athweef p p',
        email: 'adilathweef777@gmail.com.com',
        volunteerId: 'NSS001',
        bloodGroup: 'AB-',
        place: 'Malappuram',
        department: 'Computer Application',
        role: 'volunteer',
        isApproved: true,
        eventsParticipated: ['1', '2'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      UserModel(
        id: '2',
        name: 'Fuhad',
        email: 'fuhad@example.com',
        volunteerId: 'NSS002',
        bloodGroup: 'B+',
        place: 'Malapppuram',
        department: 'Electronics',
        role: 'volunteer',
        isApproved: true,
        eventsParticipated: ['1'],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      UserModel(
        id: '3',
        name: 'Anand',
        email: 'Anand@example.com',
        volunteerId: 'NSS003',
        bloodGroup: 'O+',
        place: 'Malappuram',
        department: 'Mechanical',
        role: 'volunteer',
        isApproved: false,
        eventsParticipated: [],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  // Mock data for pending approvals
  static List<UserModel> getMockPendingVolunteers() {
    return [
      UserModel(
        id: '3',
        name: 'Joel',
        email: 'Joel@example.com',
        volunteerId: 'NSS004',
        bloodGroup: 'O+',
        place: 'Alappuzha',
        department: 'Mechanical',
        role: 'volunteer',
        isApproved: false,
        eventsParticipated: [],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      UserModel(
        id: '4',
        name: 'Abhishek',
        email: 'Abi@example.com',
        volunteerId: 'NSS005',
        bloodGroup: 'AB+',
        place: 'Kozhikode',
        department: 'Civil',
        role: 'volunteer',
        isApproved: false,
        eventsParticipated: [],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  // Mock data for admins
  static List<UserModel> getMockAdmins() {
    return [
      UserModel(
        id: '5',
        name: 'Dr. Sabeel',
        email: 'Sabeel@example.com',
        volunteerId: '', // Empty for admins
        adminId: 'NSS-ADMIN-001', // Using adminId for admins
        bloodGroup: 'A+',
        place: 'Kollam',
        department: 'Mathematics',
        role: 'admin',
        isApproved: true,
        eventsParticipated: [],
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      UserModel(
        id: '6',
        name: 'Prof. meera',
        email: 'meera@example.com',
        volunteerId: '', // Empty for admins
        adminId: 'NSS-ADMIN-002', // Using adminId for admins
        bloodGroup: 'B+',
        place: 'Kollam',
        department: 'Electronics',
        role: 'admin',
        isApproved: true,
        eventsParticipated: [],
        createdAt: DateTime.now().subtract(const Duration(days: 85)),
      ),
    ];
  }
}





// class UserModel {
//   final String id;
//   final String name;
//   final String email;
//   final String volunteerId;
//   final String bloodGroup;
//   final String place;
//   final String department;
//   final String role; // 'volunteer' or 'admin'
//   final bool isApproved;
//   final List<String> eventsParticipated;
//   final DateTime createdAt;

//   UserModel({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.volunteerId,
//     required this.bloodGroup,
//     required this.place,
//     required this.department,
//     required this.role,
//     this.isApproved = false,
//     this.eventsParticipated = const [],
//     required this.createdAt,
//   });

//   // Mock data for UI development
//   static List<UserModel> getMockVolunteers() {
//     return [
//       UserModel(
//         id: '1',
//         name: 'Adil athweef p p',
//         email: 'adilathweef777@gmail.com.com',
//         volunteerId: 'NSS001',
//         bloodGroup: 'AB-',
//         place: 'Malappuram',
//         department: 'Computer Application',
//         role: 'volunteer',
//         isApproved: true,
//         eventsParticipated: ['1', '2'],
//         createdAt: DateTime.now().subtract(const Duration(days: 30)),
//       ),
//       UserModel(
//         id: '2',
//         name: 'Fuhad',
//         email: 'fuhad@example.com',
//         volunteerId: 'NSS002',
//         bloodGroup: 'B+',
//         place: 'Malapppuram',
//         department: 'Electronics',
//         role: 'volunteer',
//         isApproved: true,
//         eventsParticipated: ['1'],
//         createdAt: DateTime.now().subtract(const Duration(days: 25)),
//       ),
//       UserModel(
//         id: '3',
//         name: 'Anand',
//         email: 'Anand@example.com',
//         volunteerId: 'NSS003',
//         bloodGroup: 'O+',
//         place: 'Malappuram',
//         department: 'Mechanical',
//         role: 'volunteer',
//         isApproved: false,
//         eventsParticipated: [],
//         createdAt: DateTime.now().subtract(const Duration(days: 2)),
//       ),
//     ];
//   }

//   // Mock data for pending approvals
//   static List<UserModel> getMockPendingVolunteers() {
//     return [
//       UserModel(
//         id: '3',
//         name: 'Joel',
//         email: 'Joel@example.com',
//         volunteerId: 'NSS004',
//         bloodGroup: 'O+',
//         place: 'Alappuzha',
//         department: 'Mechanical',
//         role: 'volunteer',
//         isApproved: false,
//         eventsParticipated: [],
//         createdAt: DateTime.now().subtract(const Duration(days: 2)),
//       ),
//       UserModel(
//         id: '4',
//         name: 'Abhishek',
//         email: 'Abi@example.com',
//         volunteerId: 'NSS005',
//         bloodGroup: 'AB+',
//         place: 'Kozhikode',
//         department: 'Civil',
//         role: 'volunteer',
//         isApproved: false,
//         eventsParticipated: [],
//         createdAt: DateTime.now().subtract(const Duration(days: 1)),
//       ),
//     ];
//   }

//   // Mock data for admins
//   static List<UserModel> getMockAdmins() {
//     return [
//       UserModel(
//         id: '5',
//         name: 'Dr. Sabeel',
//         email: 'Sabeel@example.com',
//         volunteerId: 'NSS-ADMIN-001',
//         bloodGroup: 'A+',
//         place: 'Kollam',
//         department: 'Mathematics',
//         role: 'admin',
//         isApproved: true,
//         eventsParticipated: [],
//         createdAt: DateTime.now().subtract(const Duration(days: 90)),
//       ),
//       UserModel(
//         id: '6',
//         name: 'Prof. meera',
//         email: 'meera@example.com',
//         volunteerId: 'NSS-ADMIN-002',
//         bloodGroup: 'B+',
//         place: 'Kollam',
//         department: 'Electronics',
//         role: 'admin',
//         isApproved: true,
//         eventsParticipated: [],
//         createdAt: DateTime.now().subtract(const Duration(days: 85)),
//       ),
//     ];
//   }
// }
