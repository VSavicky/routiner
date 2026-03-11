АРХИТЕКТУРА ПРИЛОЖЕНИЯ "Routiner"
=================================================

1. СТРУКТУРА ПРОЕКТА
--------------------
lib/
├── core/                      # ВСЕ переиспользуемое
│   ├── constants/             # Константы, ключи, строки
│   ├── di/                     # Dependency Injection
│   ├── error/                   # Failures, исключения
│   ├── localization/             # Локализация
│   ├── middleware/                # Интерцепторы
│   ├── mixins/                     # Переиспользуемые mixins
│   ├── network/                     # HTTP клиенты
│   ├── notification/                 # Локальные уведомления
│   ├── platform/                      # Нативные адаптеры
│   ├── routing/                        # Навигация (GoRouter)
│   ├── services/                        # Firebase Analytics, Crashlytics
│   ├── themes/                            # Темы, стили, цвета
│   ├── utils/                               # Хелперы, extensions
│   └── widgets/                               # Переиспользуемые виджеты
│
├── features/                         # Все фичи
│   ├── auth/                          # Авторизация
│   │   ├── data/                         # Слой данных
│   │   │   ├── datasources/                  # API, Hive
│   │   │   ├── models/                        # DTO с JSON
│   │   │   └── repositories/                   # Имплементации
│   │   ├── domain/                         # Бизнес-слой
│   │   │   ├── entities/                       # User
│   │   │   ├── repositories/                    # Абстракции
│   │   │   └── usecases/                         # SignIn, SignUp
│   │   ├── presentation/                     # UI слой
│   │   │   ├── screens/                          # LoginScreen, RegisterScreen
│   │   │   └── widgets/                           # AuthForm
│   │   └── auth_bloc.dart                     # BLoC фичи
│   │
│   ├── habits/                         # Привычки
│   │   ├── data/
│   │   ├── domain/
│   │   │   ├── entities/                   # Habit, Completion
│   │   │   ├── repositories/                # HabitRepository
│   │   │   └── usecases/                      # GetHabits, CompleteHabit
│   │   ├── presentation/
│   │   │   ├── screens/                        # HabitsOverviewScreen
│   │   │   └── widgets/                          # HabitTile
│   │   └── habits_bloc.dart
│   │
│   ├── analytics/                       # Аналитика
│   │   ├── data/
│   │   ├── domain/
│   │   │   ├── entities/                   # WeeklyProgress
│   │   │   ├── repositories/                # AnalyticsRepository
│   │   │   └── usecases/                      # GetWeeklyStats
│   │   ├── presentation/
│   │   │   ├── screens/                        # AnalyticsScreen
│   │   │   └── widgets/                          # HeatMap, Charts
│   │   └── analytics_bloc.dart
│   │
│   ├── onboarding/                      # Онбординг
│   ├── new_habit/                        # Создание привычки
│   └── profile/                           # Профиль
│
├── main.dart
└── injection_container.dart            # GetIt конфиг

2. ПРАВИЛО ЗАВИСИМОСТЕЙ
-----------------------
Зависимости направлены ТОЛЬКО ВНУТРЬ:
UI → BLoC → UseCases → Repositories(abstract) ← Data(implements)

Domain НЕ знает о Data и Presentation.
Data зависит от Domain (имплементирует интерфейсы).
Presentation зависит от Domain (вызывает usecases).

3. СЛОИ АРХИТЕКТУРЫ
--------------------
DOMAIN (внутренний):
- Entities: бизнес-объекты (Habit, User)
- Repositories: абстрактные классы (abstract class HabitRepository)
- UseCases: сценарии (class GetHabitsUseCase)

DATA (внешний):
- Models: DTO с fromJson/toJson (HabitModel extends Habit)
- Datasources: remote (API), local (Hive)
- Repositories: имплементации (HabitRepositoryImpl)

PRESENTATION (UI):
- BLoC/Cubit: управление состоянием фичи
- Screens: экраны (HabitsOverviewScreen)
- Widgets: виджеты фичи (HabitTile)

4. УПРАВЛЕНИЕ СОСТОЯНИЕМ (BLoC)
--------------------------------
- BLoC лежит в КОРНЕ фичи (рядом с data/domain/presentation)
- 3 файла: *bloc.dart, *event.dart, *state.dart
- BLoC вызывает UseCases, преобразует результат в состояния
- UI через BlocBuilder реагирует на состояния

5. НАВИГАЦИЯ (GoRouter)
-----------------------
core/routing/app_router.dart:
- Декларативные маршруты
- ShellRoute для BottomNavigationBar
- Redirect guards для проверки авторизации

6. DEPENDENCY INJECTION (GetIt)
--------------------------------
injection_container.dart:
- Регистрация синглтонов (datasources, repositories)
- Регистрация фабрик (BLoC)
- Разделение по фичам через отдельные методы _initAuth()

7. ОБРАБОТКА ОШИБОК
-------------------
core/error/failures.dart:
- ServerFailure, CacheFailure, NetworkFailure
- UseCases возвращают Either<Failure, T>
- В BLoC маппинг failures в UI-сообщения

8. ТЕСТИРОВАНИЕ
----------------
test/
├── features/
│   ├── auth/                 # Тесты usecases, bloc
│   └── habits/
└── test_utils/               # Моки, хелперы

9. АССЕТЫ (в корне проекта)
---------------------------
assets/
├── fonts/
├── icons/
│   ├── habit_categories/
│   └── navigation/
├── images/
│   ├── backgrounds/
│   └── illustrations/
├── animations/               # Lottie JSON
└── configs/                  # .env, Firebase JSON