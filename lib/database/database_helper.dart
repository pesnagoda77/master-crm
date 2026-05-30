import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/appointment.dart';
import '../models/expense.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  DatabaseHelper._init();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('master_crm.db');
    return _database!;
  }
  
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }
  
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        telegram TEXT,
        address TEXT,
        notes TEXT,
        tag TEXT DEFAULT 'regular',
        totalRevenue REAL DEFAULT 0,
        visitsCount INTEGER DEFAULT 0,
        lastVisit TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        clientName TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        service TEXT NOT NULL,
        price REAL NOT NULL,
        address TEXT,
        status INTEGER DEFAULT 0,
        notes TEXT,
        photos TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        receiptPhoto TEXT,
        notes TEXT
      )
    ''');
  }
  
  Future<int> createClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap());
  }
  
  Future<List<Client>> getAllClients() async {
    final db = await database;
    final result = await db.query('clients', orderBy: 'name');
    return result.map((map) => Client.fromMap(map)).toList();
  }
  
  Future<Client?> getClient(int id) async {
    final db = await database;
    final maps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Client.fromMap(maps.first);
    }
    return null;
  }
  
  Future<int> updateClient(Client client) async {
    final db = await database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }
  
  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<int> createAppointment(Appointment appointment) async {
    final db = await database;
    return await db.insert('appointments', appointment.toMap());
  }
  
  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    
    final result = await db.query(
      'appointments',
      where: 'dateTime >= ? AND dateTime < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'dateTime',
    );
    return result.map((map) => Appointment.fromMap(map)).toList();
  }
  
  Future<List<Appointment>> getAppointmentsForRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'appointments',
      where: 'dateTime >= ? AND dateTime < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'dateTime',
    );
    return result.map((map) => Appointment.fromMap(map)).toList();
  }
  
  Future<int> updateAppointment(Appointment appointment) async {
    final db = await database;
    return await db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }
  
  Future<int> deleteAppointment(int id) async {
    final db = await database;
    return await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<int> createExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }
  
  Future<List<Expense>> getExpensesForDate(DateTime date) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    
    final result = await db.query(
      'expenses',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }
  
  Future<List<Expense>> getExpensesForRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }
  
  Future<Map<String, dynamic>> getFinanceSummary(DateTime date) async {
    final appointments = await getAppointmentsForDate(date);
    final expenses = await getExpensesForDate(date);
    
    double income = 0;
    double unpaid = 0;
    
    for (var app in appointments) {
      if (app.status == AppointmentStatus.donePaid) {
        income += app.price;
      } else if (app.status == AppointmentStatus.doneUnpaid) {
        unpaid += app.price;
      }
    }
    
    double totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
    
    return {
      'income': income,
      'unpaid': unpaid,
      'expenses': totalExpenses,
      'net': income - totalExpenses,
      'appointmentCount': appointments.length,
    };
  }
  
  Future close() async {
    final db = await database;
    db.close();
  }
}