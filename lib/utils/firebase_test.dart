import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTest {
  static Future<void> testConnection() async {
    print("🔥 Тестирование Firebase...");
    
    try {
      // Тест Firebase Auth
      final FirebaseAuth auth = FirebaseAuth.instance;
      print("✅ Firebase Auth инициализирован");
      
      // Тест Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      print("✅ Firestore инициализирован");
      
      // Тест подключения (пробуем получить коллекцию)
      final snapshot = await firestore.collection('test').limit(1).get();
      print("✅ Подключение к Firestore работает");
      
      print("🎉 Firebase настроен правильно!");
      
    } catch (e) {
      print("❌ Ошибка Firebase: $e");
      print("📋 Проверьте:");
      print("1. google-services.json в android/app/");
      print("2. Firebase проект создан");
      print("3. Internet разрешение добавлено");
      print("4. Плагины в build.gradle.kts");
    }
  }
  
  static Future<void> testRegistration() async {
    print("🧪 Тест регистрации...");
    
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      
      // Пробуем создать тестового пользователя
      final result = await auth.createUserWithEmailAndPassword(
        email: "test@example.com",
        password: "test123456",
      );
      
      print("✅ Пользователь создан: ${result.user?.email}");
      
      // Пробуем сохранить в Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(result.user!.uid).set({
        'email': result.user!.email,
        'firstName': 'Test',
        'lastName': 'User',
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      print("✅ Данные сохранены в Firestore");
      
      // Удаляем тестового пользователя
      await result.user!.delete();
      await firestore.collection('users').doc(result.user!.uid).delete();
      
      print("🧹 Тестовые данные удалены");
      print("🎉 Регистрация работает!");
      
    } catch (e) {
      print("❌ Ошибка регистрации: $e");
      
      if (e.toString().contains('email-already-in-use')) {
        print("ℹ️ Тестовый пользователь уже существует, это нормально");
      } else {
        print("📋 Проверьте настройки Firebase Authentication");
      }
    }
  }
}
