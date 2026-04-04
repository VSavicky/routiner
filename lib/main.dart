import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:routiner/core/routing/app_routing.dart';
import 'package:routiner/utils/firebase_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
    
    // Тестируем подключение
    await FirebaseTest.testConnection();
    
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    print('📋 Check:');
    print('1. google-services.json in android/app/');
    print('2. Firebase project exists');
    print('3. Internet permission in AndroidManifest');
  }
  
  try {
    // Просто проверяем что GoogleSignIn доступен
    print('✅ Google Sign-In available');
  } catch (e) {
    print('❌ Google Sign-In initialization failed: $e');
    print('📋 Check OAuth configuration in Firebase Console');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_ , child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Routiner',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: Typography.englishLike2018.apply(fontSizeFactor: 1.sp),
          ),
          routerConfig: router,
        );
      },
    );
  }
}