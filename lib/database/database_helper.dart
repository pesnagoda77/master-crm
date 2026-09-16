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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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
    
    await db.execute('''
      CREATE TABLE appointment_materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appointmentId INTEGER NOT NULL,
        name TEXT NOT NULL,
        cost REAL NOT NULL,
        FOREIGN KEY (appointmentId) REFERENCES appointments (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE recurring_appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        clientName TEXT NOT NULL,
        service TEXT NOT NULL,
        price REAL NOT NULL,
        address TEXT,
        startDate TEXT NOT NULL,
        repeatType TEXT NOT NULL,
        repeatInterval INTEGER NOT NULL,
        endDate TEXT,
        FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appointmentId INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (appointmentId) REFERENCES appointments (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    
    await db.insert('app_settings', {'key': 'is_pro', 'value': 'false'});
    await db.insert('app_settings', {'key': 'free_client_limit', 'value': '5'});
    await db.insert('app_settings', {'key': 'tax_system', 'value': 'usn6'});
    await db.insert('app_settings', {'key': 'monthly_goal', 'value': '150000'});
  }
  
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE appointment_materials (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          appointmentId INTEGER NOT NULL,
          name TEXT NOT NULL,
          cost REAL NOT NULL,
          FOREIGN KEY (appointmentId) REFERENCES appointments (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE TABLE recurring_appointments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clientId INTEGER NOT NULL,
          clientName TEXT NOT NULL,
          service TEXT NOT NULL,
          price REAL NOT NULL,
          address TEXT,
          startDate TEXT NOT NULL,
          repeatType TEXT NOT NULL,
          repeatInterval INTEGER NOT NULL,
          endDate TEXT,
          FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE TABLE payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          appointmentId INTEGER NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          notes TEXT,
          FOREIGN KEY (appointmentId) REFERENCES appointments (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      
      await db.insert('app_settings', {'key': 'is_pro', 'value': 'false'});
      await db.insert('app_settings', {'key': 'free_client_limit', 'value': '5'});
      await db.insert('app_settings', {'key': 'tax_system', 'value': 'usn6'});
      await db.insert('app_settings', {'key': 'monthly_goal', 'value': '150000'});
    }
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
  
  // ========== PAYMENTS ==========
  Future<int> createPayment(int appointmentId, double amount, {String? notes}) async {
    final db = await database;
    return await db.insert('payments', {
      'appointmentId': appointmentId,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'notes': notes,
    });
  }
  
  Future<List<Map<String, dynamic>>> getPaymentsForAppointment(int appointmentId) async {
    final db = await database;
    return await db.query(
      'payments',
      where: 'appointmentId = ?',
      whereArgs: [appointmentId],
      orderBy: 'date DESC',
    );
  }
  
  Future<double> getTotalPaidForAppointment(int appointmentId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE appointmentId = ?',
      [appointmentId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
  
  // ========== APPOINTMENT MATERIALS ==========
  Future<int> addMaterial(int appointmentId, String name, double cost) async {
    final db = await database;
    return await db.insert('appointment_materials', {
      'appointmentId': appointmentId,
      'name': name,
      'cost': cost,
    });
  }
  
  Future<List<Map<String, dynamic>>> getMaterialsForAppointment(int appointmentId) async {
    final db = await database;
    return await db.query(
      'appointment_materials',
      where: 'appointmentId = ?',
      whereArgs: [appointmentId],
    );
  }
  
  Future<double> getTotalMaterialsCost(int appointmentId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(cost) as total FROM appointment_materials WHERE appointmentId = ?',
      [appointmentId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
  
  Future<int> deleteMaterial(int id) async {
    final db = await database;
    return await db.delete('appointment_materials', where: 'id = ?', whereArgs: [id]);
  }
  
  // ========== RECURRING APPOINTMENTS ==========
  Future<int> createRecurring(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('recurring_appointments', data);
  }
  
  Future<List<Map<String, dynamic>>> getAllRecurring() async {
    final db = await database;
    return await db.query('recurring_appointments', orderBy: 'startDate');
  }
  
  Future<int> deleteRecurring(int id) async {
    final db = await database;
    return await db.delete('recurring_appointments', where: 'id = ?', whereArgs: [id]);
  }
  
  // ========== APP SETTINGS ==========
  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (result.isNotEmpty) return result.first['value'] as String;
    return null;
  }
  
  Future<int> setSetting(String key, String value) async {
    final db = await database;
    return await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // ========== FINANCE PERIOD ==========
  Future<Map<String, dynamic>> getFinanceSummaryForPeriod(DateTime start, DateTime end) async {
    final appointments = await getAppointmentsForRange(start, end);
    final expenses = await getExpensesForRange(start, end);
    
    double income = 0;
    double unpaid = 0;
    double materialsCost = 0;
    
    for (var app in appointments) {
      if (app.status == AppointmentStatus.donePaid) {
        income += app.price;
      } else if (app.status == AppointmentStatus.doneUnpaid) {
        unpaid += app.price;
      }
      materialsCost += await getTotalMaterialsCost(app.id!);
    }
    
    double totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
    
    return {
      'income': income,
      'unpaid': unpaid,
      'expenses': totalExpenses,
      'materials': materialsCost,
      'net': income - totalExpenses - materialsCost,
      'appointmentCount': appointments.length,
    };
  }
  
  // ========== STATISTICS ==========
  Future<List<Map<String, dynamic>>> getTopClients({int limit = 10, DateTime? start, DateTime? end}) async {
    final db = await database;
    String whereClause = "a.status = ?";
    List<dynamic> whereArgs = [AppointmentStatus.donePaid.index];
    
    if (start != null && end != null) {
      whereClause += " AND a.dateTime >= ? AND a.dateTime < ?";
      whereArgs.add(start.toIso8601String());
      whereArgs.add(end.toIso8601String());
    }
    
    final result = await db.rawQuery('''
      SELECT c.id, c.name, c.phone, SUM(a.price) as total, COUNT(a.id) as count
      FROM clients c
      JOIN appointments a ON c.id = a.clientId
      WHERE $whereClause
      GROUP BY c.id
      ORDER BY total DESC
      LIMIT ?
    ''', [...whereArgs, limit]);
    
    return result;
  }
  
  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    
    final summary = await getFinanceSummaryForPeriod(start, end);
    
    final db = await database;
    final dailyResult = await db.rawQuery('''
      SELECT date(dateTime) as day, SUM(price) as income, COUNT(*) as count
      FROM appointments
      WHERE status = ? AND dateTime >= ? AND dateTime < ?
      GROUP BY day
      ORDER BY day
    ''', [AppointmentStatus.donePaid.index, start.toIso8601String(), end.toIso8601String()]);
    
    return {
      ...summary,
      'daily': dailyResult,
    };
  }
  
  Future<int> getClientCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM clients');
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }
  
  Future close() async {
    final db = await database;
    db.close();
  }
}