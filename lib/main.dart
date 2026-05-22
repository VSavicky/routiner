import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:routiner/core/routing/app_routing.dart';
import 'package:routiner/firebase_options.dart';
import 'package:routiner/utils/firebase_test.dart';
import 'package:routiner/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _localeLanguageCodeKey = 'locale_language_code';
const String _localeCountryCodeKey = 'locale_country_code';

Future<Locale> _loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString(_localeLanguageCodeKey);
  final countryCode = prefs.getString(_localeCountryCodeKey);

  if (languageCode != null && languageCode.isNotEmpty) {
    return Locale(languageCode, countryCode);
  }

  final selectedLanguage = prefs.getString('selected_language');
  switch (selectedLanguage) {
    case 'Русский':
      return const Locale('ru', 'RU');
    case 'Қазақша':
      return const Locale('kk', 'KZ');
    case 'English':
    default:
      return const Locale('en', 'US');
  }
}

Future<void> _saveLocale(Locale locale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_localeLanguageCodeKey, locale.languageCode);
  final countryCode = locale.countryCode;
  if (countryCode == null || countryCode.isEmpty) {
    await prefs.remove(_localeCountryCodeKey);
  } else {
    await prefs.setString(_localeCountryCodeKey, countryCode);
  }
}

final GlobalKey<_MyAppState> myAppKey = GlobalKey<_MyAppState>();

Future<void> changeAppLocale(Locale locale) async {
  await _saveLocale(locale);
  final currentState = myAppKey.currentState;
  if (currentState != null) {
    currentState.setLocale(locale);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
  
  final savedLocale = await _loadSavedLocale();
  runApp(MyApp(key: myAppKey, initialLocale: savedLocale));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key, required this.initialLocale}) : super(key: key);

  final Locale initialLocale;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

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
