import 'dart:async';

/// Утилита для выполнения операций с повторными попытками и экспоненциальной задержкой
class RetryUtils {
  /// Выполняет асинхронную операцию с повторными попытками при ошибках
  ///
  /// [operation] - функция, которая выполняет операцию
  /// [maxRetries] - максимальное количество попыток (по умолчанию 5)
  /// [initialDelay] - начальная задержка между попытками (по умолчанию 1с)
  /// [multiplier] - множитель задержки (по умолчанию 2.0)
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 5,
    Duration initialDelay = const Duration(seconds: 1),
    double multiplier = 2.0,
  }) async {
    int attempts = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        // Если это последняя попытка - выбрасываем ошибку
        if (attempts >= maxRetries) {
          print('[RetryUtils] All $attempts attempts failed: $e');
          rethrow;
        }

        // Логируем попытку
        print('[RetryUtils] Attempt $attempts failed: $e. Retrying in ${currentDelay.inSeconds}s...');

        // Ждем перед следующей попыткой
        await Future.delayed(currentDelay);

        // Увеличиваем задержку экспоненциально
        currentDelay = Duration(
          seconds: (currentDelay.inSeconds * multiplier).round(),
        );
      }
    }
  }
}
