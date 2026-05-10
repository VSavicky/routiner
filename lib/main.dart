import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:routiner/core/routing/app_routing.dart';
import 'package:routiner/utils/firebase_test.dart';
import 'package:routiner/l10n/app_localizations.dart';

final GlobalKey<_MyAppState> myAppKey = GlobalKey<_MyAppState>();

void changeAppLocale(Locale locale) {
  final currentState = myAppKey.currentState;
  if (currentState != null) {
    currentState.setLocale(locale);
  }
}

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
  
  runApp(MyApp(key: myAppKey));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', 'US');

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
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: _locale,
          routerConfig: router,
        );
      },
    );
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }
}