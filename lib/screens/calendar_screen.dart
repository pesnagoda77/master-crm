import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'add_appointment_screen.dart';
import 'edit_appointment_screen.dart';
import '../database/database_helper.dart';
import '../models/appointment.dart';
import '../utils/constants.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Appointment> _appointments = [];
  List<Appointment> _appointmentsForWeek = [];  // ← ДОБАВЛЕНО
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _loadWeekAppointments();  // ← ДОБАВЛЕНО
  }
  
  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    final appointments = await DatabaseHelper.instance.getAppointmentsForDate(_selectedDate);
    appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    setState(() {
      _appointments = appointments;
      _isLoading = false;
    });
  }
  
  Future<void> _loadWeekAppointments() async {  // ← ДОБАВЛЕНО
    final start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final end = start.add(const Duration(days: 7));
    final appointments = await DatabaseHelper.instance.getAppointmentsForRange(start, end);
    setState(() {
      _appointmentsForWeek = appointments;
    });
  }
  
  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadAppointments();
    _loadWeekAppointments();  // ← ДОБАВЛЕНО
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Календарь',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 8),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                    ? _buildEmptyState()
                    : _buildAppointmentsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
          );
          if (result == true) {
            _loadAppointments();
            _loadWeekAppointments();  // ← ДОБАВЛЕНО
          }
        },
        backgroundColor: AppColors.navActive,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildDateSelector() {
    final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                  onPressed: () => _changeDate(-1),
                ),
                Text(
                  DateFormat('MMMM yyyy', 'ru').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final date = _selectedDate.add(
                  Duration(days: index - _selectedDate.weekday + 1),
                );
                final isSelected = date.day == _selectedDate.day &&
                    date.month == _selectedDate.month;
                
                // Проверяем, есть ли записи на этот день
                final hasAppointments = _appointmentsForWeek.any((a) => 
                  a.dateTime.year == date.year && 
                  a.dateTime.month == date.month && 
                  a.dateTime.day == date.day
                );
                
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    _loadAppointments();
                  },
                  child: Container(
                    width: 44,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.navActive : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekdays[date.weekday - 1],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Точка если есть записи
                        if (hasAppointments && !isSelected)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.navActive,
                              shape: BoxShape.circle,
                            ),
                          )
                        else if (hasAppointments && isSelected)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppointmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }
  
  Widget _buildAppointmentCard(Appointment appointment) {
    final timeStr = DateFormat('HH:mm').format(appointment.dateTime);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _markDone(appointment),
              backgroundColor: AppColors.donePaid,
              foregroundColor: Colors.white,
              icon: Icons.check,
              label: 'Выполнено',
            ),
            SlidableAction(
              onPressed: (_) => _callClient(appointment),
              backgroundColor: AppColors.navActive,
              foregroundColor: Colors.white,
              icon: Icons.phone,
              label: 'Позвонить',
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditAppointmentScreen(appointment: appointment),
              ),
            );
            if (result == true) {
              _loadAppointments();
              _loadWeekAppointments();  // ← ДОБАВЛЕНО
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: appointment.status.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: appointment.status.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  appointment.status.label,
                                  style: TextStyle(
                                    color: appointment.status.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            appointment.clientName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appointment.service,
                            style: AppStyles.cardSubtitle,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  appointment.address ?? 'Адрес не указан',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,###').format(appointment.price.toInt())} ₽',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет записей на этот день',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите + чтобы добавить',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
  
  void _markDone(Appointment appointment) async {
    final updated = appointment.copyWith(
      status: appointment.status == AppointmentStatus.scheduled
          ? AppointmentStatus.doneUnpaid
          : AppointmentStatus.donePaid,
    );
    await DatabaseHelper.instance.updateAppointment(updated);
    _loadAppointments();
    _loadWeekAppointments();  // ← ДОБАВЛЕНО
  }
  
  void _callClient(Appointment appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Звоним ${appointment.clientName}...')),
    );
  }
}