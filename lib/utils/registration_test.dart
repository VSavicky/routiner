import 'package:flutter/material.dart';
import 'package:routiner/features/auth/domain/services/auth_service.dart';
import 'package:routiner/features/auth/domain/entities/user_entity.dart';

class RegistrationTest {
  static Future<void> testRegistration() async {
    print('🧪 Тестирование регистрации...');
    
    final authService = AuthService();
    
    try {
      final userEntity = await authService.registerWithEmailAndPassword(
        email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'test123456',
        firstName: 'Test',
        lastName: 'User',
        birthDate: '01.01.1990',
        gender: 'male',
        habits: ['test'],
      );
      
      if (userEntity != null) {
        print('✅ Регистрация успешна!');
        print('📧 Email: ${userEntity.email}');
        print('👤 Имя: ${userEntity.firstName} ${userEntity.lastName}');
        print('🆔 ID: ${userEntity.id}');
      } else {
        print('❌ Регистрация не удалась');
      }
    } catch (e) {
      print('❌ Ошибка регистрации: $e');
      
      if (e.toString().contains('email-already-in-use')) {
        print('ℹ️ Email уже используется - это нормально');
      } else if (e.toString().contains('network')) {
        print('🌐 Проблема с интернетом');
      } else if (e.toString().contains('permission-denied')) {
        print('🔒 Нет доступа к Firestore');
      } else {
        print('📋 Проверьте настройки Firebase');
      }
    }
  }
  
  static Future<void> testLogin() async {
    print('🔑 Тестирование входа...');
    
    final authService = AuthService();
    
    try {
      final userEntity = await authService.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'test123456',
      );
      
      if (userEntity != null) {
        print('✅ Вход успешен!');
        print('📧 Email: ${userEntity.email}');
        print('👤 Имя: ${userEntity.firstName} ${userEntity.lastName}');
      } else {
        print('❌ Вход не удался');
      }
    } catch (e) {
      print('❌ Ошибка входа: $e');
      
      if (e.toString().contains('user-not-found')) {
        print('👤 Пользователь не найден');
      } else if (e.toString().contains('wrong-password')) {
        print('🔑 Неверный пароль');
      } else if (e.toString().contains('network')) {
        print('🌐 Проблема с интернетом');
      }
    }
  }
}
