import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель привычки для Firestore
class HabitModel {
  final String? id;
  final String userId;
  final String name;
  final String emoji;
  final String color; // hex цвет
  final String habitType; // 'build' или 'quit'
  
  // Target Goal
  final int targetValue;
  final String targetUnit;
  final int incrementStep; // Шаг инкремента (+1, +100, +15 и т.д.)
  
  // Schedule (GOAL)
  final int frequency;
  final String period; // 'day', 'week', 'month'
  
  // Reminders
  final bool remindersEnabled;
  final List<String> reminderTimes; // ["08:00", "21:00"]
  final String reminderPeriod; // 'Every day', 'Weekdays', etc.
  
  // Motivation
  final String? motivation;
  
  // System habit reference
  final bool isDefaultHabit;
  final String? defaultHabitId;
  
  // Challenge reference
  final String? challengeId; // ID челленджа, если привычка из челленджа
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  HabitModel({
    this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.color,
    required this.habitType,
    this.targetValue = 1,
    this.targetUnit = 'times',
    this.incrementStep = 1,
    this.frequency = 1,
    this.period = 'day',
    this.remindersEnabled = true,
    this.reminderTimes = const [],
    this.reminderPeriod = 'Every day',
    this.motivation,
    this.isDefaultHabit = false,
    this.defaultHabitId,
    this.challengeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isArchived = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Конвертация из Firestore документа
  factory HabitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HabitModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '🎯',
      color: data['color'] ?? '#FFB3BA',
      habitType: data['habitType'] ?? 'build',
      targetValue: data['targetValue'] ?? 1,
      targetUnit: data['targetUnit'] ?? 'times',
      incrementStep: data['incrementStep'] ?? 1,
      frequency: data['frequency'] ?? 1,
      period: data['period'] ?? 'day',
      remindersEnabled: data['remindersEnabled'] ?? true,
      reminderTimes: List<String>.from(data['reminderTimes'] ?? []),
      reminderPeriod: data['reminderPeriod'] ?? 'Every day',
      motivation: data['motivation'],
      isDefaultHabit: data['isDefaultHabit'] ?? false,
      defaultHabitId: data['defaultHabitId'],
      challengeId: data['challengeId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isArchived: data['isArchived'] ?? false,
    );
  }

  /// Конвертация в Firestore формат
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'emoji': emoji,
      'color': color,
      'habitType': habitType,
      'targetValue': targetValue,
      'targetUnit': targetUnit,
      'incrementStep': incrementStep,
      'frequency': frequency,
      'period': period,
      'remindersEnabled': remindersEnabled,
      'reminderTimes': reminderTimes,
      'reminderPeriod': reminderPeriod,
      'motivation': motivation,
      'isDefaultHabit': isDefaultHabit,
      'defaultHabitId': defaultHabitId,
      'challengeId': challengeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isArchived': isArchived,
    };
  }

  /// Копия с изменениями
  HabitModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? emoji,
    String? color,
    String? habitType,
    int? targetValue,
    String? targetUnit,
    int? incrementStep,
    int? frequency,
    String? period,
    bool? remindersEnabled,
    List<String>? reminderTimes,
    String? reminderPeriod,
    String? motivation,
    bool? isDefaultHabit,
    String? defaultHabitId,
    String? challengeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return HabitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      habitType: habitType ?? this.habitType,
      targetValue: targetValue ?? this.targetValue,
      targetUnit: targetUnit ?? this.targetUnit,
      incrementStep: incrementStep ?? this.incrementStep,
      frequency: frequency ?? this.frequency,
      period: period ?? this.period,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      reminderPeriod: reminderPeriod ?? this.reminderPeriod,
      motivation: motivation ?? this.motivation,
      isDefaultHabit: isDefaultHabit ?? this.isDefaultHabit,
      defaultHabitId: defaultHabitId ?? this.defaultHabitId,
      challengeId: challengeId ?? this.challengeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isArchived: isArchived ?? this.isArchived,
    );
  }

  /// Получить Color из hex строки
  Color get colorValue {
    final hex = color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Создать из hex цвета
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Период для отображения
  String get periodLabel {
    switch (period) {
      case 'day':
        return 'Daily';
      case 'week':
        return 'Weekly';
      case 'month':
        return 'Monthly';
      default:
        return 'Daily';
    }
  }

  /// Описание периода
  String get periodDetail {
    switch (period) {
      case 'day':
        return 'every day';
      case 'week':
        return 'per week';
      case 'month':
        return 'per month';
      default:
        return 'every day';
    }
  }
}
