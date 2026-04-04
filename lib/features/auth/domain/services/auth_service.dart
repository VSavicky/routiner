import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/features/auth/domain/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Регистрация через email и пароль
  Future<UserEntity?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String birthDate,
    required String gender,
    required List<String> habits,
  }) async {
    try {
      // Создаем пользователя в Firebase Auth
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) return null;

      // Создаем запись пользователя в Firestore
      final userEntity = UserEntity(
        id: user.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        gender: gender,
        habits: habits,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userEntity.toMap());

      // Сохраняем сессию
      await _saveSession(user.uid);

      return userEntity;
    } catch (e) {
      print('Error during registration: $e');
      return null;
    }
  }

  // Вход через email и пароль
  Future<UserEntity?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) return null;

      // Получаем данные пользователя из Firestore
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      
      if (!docSnapshot.exists) return null;

      // Сохраняем сессию
      await _saveSession(user.uid);

      return UserEntity.fromMap(docSnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error during sign in: $e');
      return null;
    }
  }

  // Выход
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _clearSession();
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  // Получение текущего пользователя
  User? get currentUser => _firebaseAuth.currentUser;

  // Поток изменений состояния авторизации
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<bool> isLoggedIn() async {
    final userId = await getCurrentUserId();
    return userId != null;
  }
}
