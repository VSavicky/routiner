import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:routiner/features/auth/domain/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleSignInService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _webClientId =
      '337123515747-evupvg6kr58mt6497jvldv07rtd50l8r.apps.googleusercontent.com';
  static const String _iosClientId =
      '337123515747-0fiko31i9f5l68b8btpa3lvb0qmc07i0.apps.googleusercontent.com';

  static Future<void>? _initializeFuture;

  Future<void> _ensureInitialized() {
    return _initializeFuture ??= GoogleSignIn.instance.initialize(
      clientId: _clientId,
      serverClientId: _webClientId,
    );
  }

  String? get _clientId {
    if (kIsWeb) return _webClientId;

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _iosClientId;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return null;
    }
  }

  Future<UserEntity?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw UnsupportedError(
          'Google Sign-In interactive authentication is not supported on this platform.',
        );
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google Sign-In did not return an ID token.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user == null) {
        return null;
      }

      await _saveSession(user.uid);

      final userRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userRef.get();

      if (docSnapshot.exists) {
        return UserEntity.fromMap(docSnapshot.data() as Map<String, dynamic>);
      }

      final displayName = user.displayName ?? googleUser.displayName ?? '';
      final nameParts = displayName.trim().split(RegExp(r'\s+'));
      final userEntity = UserEntity(
        id: user.uid,
        email: user.email ?? googleUser.email,
        firstName: nameParts.isNotEmpty && nameParts.first.isNotEmpty
            ? nameParts.first
            : '',
        lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        birthDate: '',
        gender: '',
        habits: const [],
        createdAt: DateTime.now(),
      );

      await userRef.set(userEntity.toMap());
      return userEntity;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }

      debugPrint('Google sign in error: ${e.code.name} ${e.description ?? ''}');
      rethrow;
    } catch (e) {
      debugPrint('Error during Google sign in: $e');
      rethrow;
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
      await _firebaseAuth.signOut();
      await _clearSession();
    } catch (e) {
      debugPrint('Error during sign out: $e');
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
