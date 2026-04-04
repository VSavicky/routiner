import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/features/auth/domain/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleSignInService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Вход через Google
  Future<UserEntity?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user == null) {
        return null;
      }

      // Сохраняем сессию
      await _saveSession(user.uid);

      // Проверяем/создаем запись в Firestore
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      
      if (docSnapshot.exists) {
        return UserEntity.fromMap(docSnapshot.data() as Map<String, dynamic>);
      } else {
        final displayName = user.displayName ?? '';
        final nameParts = displayName.split(' ');
        
        final userEntity = UserEntity(
          id: user.uid,
          email: user.email ?? '',
          firstName: nameParts.isNotEmpty ? nameParts.first : '',
          lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          birthDate: '',
          gender: '',
          habits: [],
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(userEntity.toMap());
        return userEntity;
      }
    } catch (e) {
      print('❌ Error during Google sign in: $e');
      return null;
    }
  }

  // Выход из Google
  Future<void> signOutGoogle() async {
    try {
      await GoogleSignIn.instance.signOut();
      await _firebaseAuth.signOut();
      await _clearSession();
    } catch (e) {
      print('❌ Error during sign out: $e');
    }
  }

  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }
}
