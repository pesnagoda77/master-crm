class Client {
  final int? id;
  final String name;
  final String phone;
  final String? telegram;
  final String? address;
  final String? notes;
  final String tag; // 'regular', 'debtor', 'vip', 'problem'
  final double totalRevenue;
  final int visitsCount;
  final DateTime? lastVisit;
  
  Client({
    this.id,
    required this.name,
    required this.phone,
    this.telegram,
    this.address,
    this.notes,
    this.tag = 'regular',
    this.totalRevenue = 0,
    this.visitsCount = 0,
    this.lastVisit,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'telegram': telegram,
      'address': address,
      'notes': notes,
      'tag': tag,
      'totalRevenue': totalRevenue,
      'visitsCount': visitsCount,
      'lastVisit': lastVisit?.toIso8601String(),
    };
  }
  
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      telegram: map['telegram'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      tag: map['tag'] as String? ?? 'regular',
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0,
      visitsCount: map['visitsCount'] as int? ?? 0,
      lastVisit: map['lastVisit'] != null 
          ? DateTime.parse(map['lastVisit'] as String) 
          : null,
    );
  }
  
  Client copyWith({
    int? id,
    String? name,
    String? phone,
    String? telegram,
    String? address,
    String? notes,
    String? tag,
    double? totalRevenue,
    int? visitsCount,
    DateTime? lastVisit,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      telegram: telegram ?? this.telegram,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      tag: tag ?? this.tag,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      visitsCount: visitsCount ?? this.visitsCount,
      lastVisit: lastVisit ?? this.lastVisit,
    );
  }
}