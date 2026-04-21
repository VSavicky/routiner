import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:routiner/core/constants/app_colors.dart';

class ChallengesService {
  static const String _joinedChallengesKey = 'joined_challenges';
  
  static final ChallengesService _instance = ChallengesService._internal();
  factory ChallengesService() => _instance;
  ChallengesService._internal();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // Конвертировать челлендж в JSON-serializable формат
  Map<String, dynamic> _challengeToJson(Map<String, dynamic> challenge) {
    final Map<String, dynamic> json = {};
    
    challenge.forEach((key, value) {
      if (value is DateTime) {
        json[key] = value.toIso8601String();
      } else if (value is Color) {
        // Сохраняем цвет как строку
        if (value == AppColors.blue) {
          json[key] = 'blue';
        } else if (value == AppColors.purple) {
          json[key] = 'purple';
        } else if (value == AppColors.orange) {
          json[key] = 'orange';
        } else if (value == AppColors.green) {
          json[key] = 'green';
        } else if (value == AppColors.red) {
          json[key] = 'red';
        } else {
          json[key] = 'blue'; // Default
        }
      } else if (value is List) {
        // Рекурсивно конвертируем элементы списка
        json[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _challengeToJson(item);
          }
          return item;
        }).toList();
      } else if (value is Map<String, dynamic>) {
        json[key] = _challengeToJson(value);
      } else {
        json[key] = value;
      }
    });
    
    return json;
  }

  // Конвертировать JSON обратно в челлендж с Color
  Map<String, dynamic> _jsonToChallenge(Map<String, dynamic> json) {
    final Map<String, dynamic> challenge = {};
    
    json.forEach((key, value) {
      if (key == 'endTime' || key == 'joinedAt') {
        // Парсим дату
        if (value is String) {
          try {
            challenge[key] = DateTime.parse(value);
          } catch (e) {
            challenge[key] = DateTime.now().add(const Duration(days: 7));
          }
        } else {
          challenge[key] = value;
        }
      } else if (key == 'color' && value is String) {
        // Восстанавливаем цвет
        switch (value) {
          case 'blue':
            challenge[key] = AppColors.blue;
            break;
          case 'purple':
            challenge[key] = AppColors.purple;
            break;
          case 'orange':
            challenge[key] = AppColors.orange;
            break;
          case 'green':
            challenge[key] = AppColors.green;
            break;
          case 'red':
            challenge[key] = AppColors.red;
            break;
          default:
            challenge[key] = AppColors.blue;
        }
      } else if (value is List) {
        challenge[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _jsonToChallenge(item);
          }
          return item;
        }).toList();
      } else if (value is Map<String, dynamic>) {
        challenge[key] = _jsonToChallenge(value);
      } else {
        challenge[key] = value;
      }
    });
    
    return challenge;
  }

  // Получить список присоединённых челленджей
  Future<List<Map<String, dynamic>>> getJoinedChallenges() async {
    final prefs = await _prefs;
    final String? jsonString = prefs.getString(_joinedChallengesKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => _jsonToChallenge(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Присоединиться к челленджу
  Future<void> joinChallenge(Map<String, dynamic> challenge) async {
    final prefs = await _prefs;
    final joinedChallenges = await getJoinedChallenges();
    
    // Проверяем, не присоединён ли уже
    final String challengeId = challenge['id'] as String? ?? challenge['title'] as String;
    final bool alreadyJoined = joinedChallenges.any((c) => 
      (c['id'] as String? ?? c['title']) == challengeId
    );
    
    if (!alreadyJoined) {
      // Конвертируем новый челлендж в JSON-формат
      final jsonChallenge = _challengeToJson({...challenge});
      
      // Добавляем метку времени присоединения
      final challengeWithJoinTime = {
        ...jsonChallenge,
        'joinedAt': DateTime.now().toIso8601String(),
        'id': challengeId,
      };
      
      joinedChallenges.add(challengeWithJoinTime);
      
      // Конвертируем ВСЕ челленджи в JSON перед сохранением
      final jsonList = joinedChallenges.map((c) => _challengeToJson(c)).toList();
      final String jsonString = jsonEncode(jsonList);
      await prefs.setString(_joinedChallengesKey, jsonString);
    }
  }

  // Покинуть челлендж
  Future<void> leaveChallenge(String challengeId) async {
    final prefs = await _prefs;
    final joinedChallenges = await getJoinedChallenges();
    
    joinedChallenges.removeWhere((c) => 
      (c['id'] as String? ?? c['title']) == challengeId
    );
    
    // Конвертируем все челленджи обратно в JSON-формат
    final jsonList = joinedChallenges.map((c) => _challengeToJson(c)).toList();
    final String jsonString = jsonEncode(jsonList);
    await prefs.setString(_joinedChallengesKey, jsonString);
  }

  // Проверить, присоединён ли пользователь к челленджу
  Future<bool> isJoined(String challengeId) async {
    final joinedChallenges = await getJoinedChallenges();
    return joinedChallenges.any((c) => 
      (c['id'] as String? ?? c['title']) == challengeId
    );
  }

  // Очистить все челленджи (для тестирования)
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.remove(_joinedChallengesKey);
  }
}
