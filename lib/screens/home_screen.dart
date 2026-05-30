import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_appointment_screen.dart';
import 'add_client_screen.dart';
import 'add_expense_screen.dart';
import '../database/database_helper.dart';
import '../models/appointment.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onCalendarTap;
  
  const HomeScreen({super.key, this.onCalendarTap});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _todayStats;
  List<Appointment> _todayAppointments = [];
  List<Appointment> _debtAppointments = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final stats = await DatabaseHelper.instance.getFinanceSummary(DateTime.now());
    final appointments = await DatabaseHelper.instance.getAppointmentsForDate(DateTime.now());
    
    final debts = appointments.where((a) => 
      a.status == AppointmentStatus.doneUnpaid
    ).toList();
    
    setState(() {
      _todayStats = stats;
      _todayAppointments = appointments;
      _debtAppointments = debts;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildIncomeCard(),
                const SizedBox(height: 16),
                _buildOccupancyCard(),
                const SizedBox(height: 16),
                _buildDebtsCard(),
                const SizedBox(height: 16),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    final now = DateTime.now();
    final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Сегодня',
          style: AppStyles.header,
        ),
      ],
    );
  }
  
  Widget _buildIncomeCard() {
    if (_isLoading) {
      return _buildSkeletonCard(height: 140);
    }
    
    final income = (_todayStats?['income'] ?? 0).toDouble();
    final appointmentCount = _todayAppointments.length;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.income.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppColors.income,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$appointmentCount ${appointmentCount == 1 ? 'запись' : appointmentCount < 5 ? 'записи' : 'записей'}',
                style: AppStyles.cardTitle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${NumberFormat('#,###').format(income.toInt())} ₽',
            style: AppStyles.bigNumber.copyWith(color: AppColors.income),
          ),
          const SizedBox(height: 4),
          const Text(
            'ожидаемый доход',
            style: AppStyles.cardSubtitle,
          ),
        ],
      ),
    );
  }
  
  Widget _buildOccupancyCard() {
    if (_isLoading) {
      return _buildSkeletonCard(height: 140);
    }
    
    final slots = List.generate(13, (index) => 8 + index);
    
    final busySlots = <int>{};
    for (var app in _todayAppointments) {
      final hour = app.dateTime.hour;
      if (hour >= 8 && hour <= 20) {
        busySlots.add(hour);
      }
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Занятость',
            style: AppStyles.cardTitle,
          ),
          const SizedBox(height: 12),
          Row(
            children: slots.map((hour) => _buildTimeSlot(hour, busySlots.contains(hour))).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '08:00',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '20:00',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeSlot(int hour, bool isBusy) {
    return Expanded(
      child: GestureDetector(
        onTap: isBusy ? () {
          widget.onCalendarTap?.call();
        } : null,
        child: Container(
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isBusy ? AppColors.scheduled : AppColors.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '$hour',
              style: TextStyle(
                fontSize: 10,
                color: isBusy ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDebtsCard() {
    if (_isLoading) {
      return _buildSkeletonCard(height: 140);
    }
    
    if (_debtAppointments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.donePaid,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Долги',
                  style: AppStyles.cardTitle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Нет задолженностей',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.doneUnpaid.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.doneUnpaid.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.doneUnpaid,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Долги',
                style: AppStyles.cardTitle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._debtAppointments.take(3).map((app) => _buildDebtItem(app)),
          if (_debtAppointments.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'И ещё ${_debtAppointments.length - 3}...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDebtItem(Appointment appointment) {
    final daysOverdue = DateTime.now().difference(appointment.dateTime).inDays;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.clientName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${appointment.service} — ${NumberFormat('#,###').format(appointment.price.toInt())} ₽',
                  style: TextStyle(
                    fontSize: 12,
                    color: daysOverdue > 5 ? AppColors.cancelled : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$daysOverdue ${daysOverdue == 1 ? 'день' : daysOverdue < 5 ? 'дня' : 'дней'}',
            style: TextStyle(
              fontSize: 12,
              color: daysOverdue > 5 ? AppColors.cancelled : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Быстрые действия',
          style: AppStyles.cardTitle,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Запись',
                Icons.add_circle_outline,
                AppColors.scheduled,
                () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
                  );
                  if (result == true) _loadData();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Клиент',
                Icons.person_add_outlined,
                AppColors.income,
                () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddClientScreen()),
                  );
                  if (result == true) _loadData();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Расход',
                Icons.receipt_long_outlined,
                AppColors.expense,
                () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                  );
                  if (result == true) _loadData();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSkeletonCard({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}