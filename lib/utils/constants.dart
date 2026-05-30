import 'package:flutter/material.dart';

// ==================== ЦВЕТА ====================
class AppColors {
  // Статусы записей
  static const Color scheduled = Color(0xFF2196F3);    // Синий - запланировано
  static const Color doneUnpaid = Color(0xFFFFC107);   // Жёлтый - выполнено, не оплачено
  static const Color donePaid = Color(0xFF4CAF50);     // Зелёный - выполнено и оплачено
  static const Color cancelled = Color(0xFFF44336);    // Красный - отменено
  
  // Теги клиентов
  static const Color tagRegular = Color(0xFF4CAF50);   // Постоянный
  static const Color tagDebtor = Color(0xFFFF9800);     // Должник
  static const Color tagVIP = Color(0xFFFFD700);        // VIP
  static const Color tagProblem = Color(0xFFF44336);    // Проблемный
  
  // Фоны (тёмная тема как в референсе)
  static const Color background = Color(0xFF1A1A1A);
  static const Color cardBackground = Color(0xFF2A2A2A);
  static const Color surface = Color(0xFF333333);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAAAAAA);
  
  // Финансы
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFF44336);
  static const Color profit = Color(0xFF2196F3);
  
  // Навигация
  static const Color navActive = Color(0xFF448AFF);
  static const Color navInactive = Color(0xFF888888);
}

// ==================== СТИЛИ ТЕКСТА ====================
class AppStyles {
  static const TextStyle header = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bigNumber = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle small = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}

// ==================== СТАТУСЫ ЗАПИСЕЙ ====================
enum AppointmentStatus {
  scheduled,      // Запланировано
  doneUnpaid,     // Выполнено, не оплачено
  donePaid,       // Выполнено и оплачено
  cancelled,      // Отменено
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Запланировано';
      case AppointmentStatus.doneUnpaid:
        return 'Выполнено, долг';
      case AppointmentStatus.donePaid:
        return 'Выполнено, оплачено';
      case AppointmentStatus.cancelled:
        return 'Отменено';
    }
  }
  
  Color get color {
    switch (this) {
      case AppointmentStatus.scheduled:
        return AppColors.scheduled;
      case AppointmentStatus.doneUnpaid:
        return AppColors.doneUnpaid;
      case AppointmentStatus.donePaid:
        return AppColors.donePaid;
      case AppointmentStatus.cancelled:
        return AppColors.cancelled;
    }
  }
}