class UserEntity {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String birthDate;
  final String gender;
  final List<String> habits;
  final DateTime createdAt;

  UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.gender,
    required this.habits,
    required this.createdAt,
  });

  // Конвертация в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate,
      'gender': gender,
      'habits': habits,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Создание из Map из Firestore
  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      birthDate: map['birthDate'] ?? '',
      gender: map['gender'] ?? '',
      habits: List<String>.from(map['habits'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
