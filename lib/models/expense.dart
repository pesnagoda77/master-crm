import 'package:flutter/foundation.dart';

class Expense {
  final int? id;
  final DateTime date;
  final double amount;
  final String category;
  final String? receiptPhoto;  // ← ПУТЬ К ФОТО ЧЕКА
  final String? notes;

  Expense({
    this.id,
    required this.date,
    required this.amount,
    required this.category,
    this.receiptPhoto,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'category': category,
      'receiptPhoto': receiptPhoto,
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      amount: map['amount'] as double,
      category: map['category'] as String,
      receiptPhoto: map['receiptPhoto'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Expense copyWith({
    int? id,
    DateTime? date,
    double? amount,
    String? category,
    String? receiptPhoto,
    String? notes,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      receiptPhoto: receiptPhoto ?? this.receiptPhoto,
      notes: notes ?? this.notes,
    );
  }
}