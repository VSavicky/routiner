import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routiner/features/achievements/data/models/achievement_model.dart';

class AchievementRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получить достижения пользователя
  Future<List<AchievementModel>> getUserAchievements(String userId) async {
    try {
      print('[ACHIEVEMENT DEBUG] Getting achievements for user: $userId');
      
      // Сначала пробуем без orderBy для работы без индексов
      List<AchievementModel> achievements = [];
      
      try {
        final snapshot = await _firestore
            .collection('achievements')
            .where('userId', isEqualTo: userId)
            .limit(20) // Уменьшаем лимит для быстрой загрузки
            .get();

        achievements = snapshot.docs
            .map((doc) {
              final achievement = AchievementModel.fromFirestore(doc.data(), doc.id);
              print('[ACHIEVEMENT DEBUG] Achievement: ${achievement.id} - ${achievement.title} - User: ${achievement.userId}');
              return achievement;
            })
            .toList();
            
        print('[ACHIEVEMENT DEBUG] Found ${achievements.length} achievements for user: $userId');
      } catch (e) {
        print('[ACHIEVEMENT WARNING] Query without orderBy failed, trying alternative approach: $e');
        
        // Альтернативный подход - получаем все документы и фильтруем локально
        try {
          final allSnapshot = await _firestore
              .collection('achievements')
              .limit(50) // Уменьшаем лимит для быстрой загрузки
              .get();

          achievements = allSnapshot.docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return data?['userId'] == userId;
              })
              .map((doc) {
                final achievement = AchievementModel.fromFirestore(doc.data(), doc.id);
                print('[ACHIEVEMENT DEBUG] Achievement (alternative): ${achievement.id} - ${achievement.title} - User: ${achievement.userId}');
                return achievement;
              })
              .toList();

          // Сортируем локально по дате
          achievements.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
          
          print('[ACHIEVEMENT DEBUG] Found ${achievements.length} achievements for user: $userId (alternative approach)');
        } catch (e2) {
          print('[ACHIEVEMENT ERROR] Alternative approach also failed: $e2');
        }
      }
      
      return achievements;
    } catch (e) {
      print('[ACHIEVEMENT ERROR] Failed to get user achievements: $e');
      return [];
    }
  }

  // Выдать достижение пользователю
  Future<void> awardAchievement(AchievementModel achievement) async {
    try {
      print('[ACHIEVEMENT DEBUG] Attempting to award achievement:');
      print('[ACHIEVEMENT DEBUG] ID: ${achievement.id}');
      print('[ACHIEVEMENT DEBUG] Title: ${achievement.title}');
      print('[ACHIEVEMENT DEBUG] User ID: ${achievement.userId}');
      
      await _firestore
          .collection('achievements')
          .doc(achievement.id)
          .set(achievement.toFirestore());
      
      print('[ACHIEVEMENT] Successfully awarded achievement: ${achievement.title} to user ${achievement.userId}');
    } catch (e) {
      print('[ACHIEVEMENT ERROR] Failed to award achievement: $e');
    }
  }

  // Проверить есть ли уже такое достижение у пользователя
  Future<bool> hasAchievement(String userId, String achievementId) async {
    try {
      final snapshot = await _firestore
          .collection('achievements')
          .where('userId', isEqualTo: userId)
          .where('id', isEqualTo: achievementId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('[ACHIEVEMENT ERROR] Failed to check achievement: $e');
      return false;
    }
  }

  // Проверить есть ли уже достижение по названию (для предотвращения дубликатов)
  Future<bool> hasAchievementByTitle(String userId, String title) async {
    try {
      final snapshot = await _firestore
          .collection('achievements')
          .where('userId', isEqualTo: userId)
          .where('title', isEqualTo: title)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('[ACHIEVEMENT ERROR] Failed to check achievement by title: $e');
      return false;
    }
  }

  // Создать достижение
  AchievementModel createAchievement({
    required String userId,
    required String title,
    required String description,
    required String icon,
    required AchievementType type,
    String? achievementId, // Добавляем параметр для ID
    Map<String, dynamic>? metadata,
  }) {
    return AchievementModel(
      id: achievementId ?? _firestore.collection('achievements').doc().id, // Используем переданный ID или генерируем
      userId: userId,
      title: title,
      description: description,
      icon: icon,
      type: type,
      earnedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  // Предопределенные достижения
  List<AchievementModel> getPredefinedAchievements(String userId) {
    return [
      // Достижения за очки
      AchievementModel(
        id: 'points_100',
        userId: userId,
        title: 'First Steps',
        description: 'Earn your first 100 points',
        icon: '🌟',
        type: AchievementType.points,
        earnedAt: DateTime.now(),
      ),
      AchievementModel(
        id: 'points_500',
        userId: userId,
        title: 'Rising Star',
        description: 'Earn 500 points',
        icon: '⭐',
        type: AchievementType.points,
        earnedAt: DateTime.now(),
      ),
      AchievementModel(
        id: 'points_1000',
        userId: userId,
        title: 'Point Master',
        description: 'Earn 1000 points',
        icon: '🏆',
        type: AchievementType.points,
        earnedAt: DateTime.now(),
      ),
      
      // Достижения за серии
      AchievementModel(
        id: 'streak_7',
        userId: userId,
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: '🔥',
        type: AchievementType.streak,
        earnedAt: DateTime.now(),
      ),
      AchievementModel(
        id: 'streak_30',
        userId: userId,
        title: 'Monthly Champion',
        description: 'Maintain a 30-day streak',
        icon: '💪',
        type: AchievementType.streak,
        earnedAt: DateTime.now(),
      ),
      
      // Достижения за клубы
      AchievementModel(
        id: 'club_first',
        userId: userId,
        title: 'Club Member',
        description: 'Join your first club',
        icon: '👥',
        type: AchievementType.club,
        earnedAt: DateTime.now(),
      ),
      AchievementModel(
        id: 'club_5',
        userId: userId,
        title: 'Social Butterfly',
        description: 'Join 5 clubs',
        icon: '🦋',
        type: AchievementType.club,
        earnedAt: DateTime.now(),
      ),
    ];
  }
}
