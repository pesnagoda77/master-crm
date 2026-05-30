import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_appointment_screen.dart';
import 'edit_client_screen.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/appointment.dart';
import '../utils/constants.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;
  
  const ClientDetailScreen({super.key, required this.client});
  
  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }
  
  Future<void> _loadAppointments() async {
    final allAppointments = await DatabaseHelper.instance.getAppointmentsForRange(
      DateTime(2000),
      DateTime(2100),
    );
    
    final clientAppointments = allAppointments.where(
      (a) => a.clientId == widget.client.id
    ).toList();
    
    clientAppointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    setState(() {
      _appointments = clientAppointments;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final double totalRevenue = _appointments
        .where((a) => a.status == AppointmentStatus.donePaid)
        .fold(0.0, (sum, a) => sum + a.price);
    
    final int paidCount = _appointments.where((a) => a.status == AppointmentStatus.donePaid).length;
    final double avgCheck = paidCount > 0 ? (totalRevenue / paidCount).toDouble() : 0.0;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditClientScreen(client: widget.client),
                ),
              );
              if (result == true) {
                _loadAppointments();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildContactsCard(),
            const SizedBox(height: 16),
            _buildFinanceCard(totalRevenue, avgCheck),
            const SizedBox(height: 16),
            _buildHistoryCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.navActive.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                widget.client.name.isNotEmpty ? widget.client.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navActive,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.client.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getTagColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getTagLabel(),
              style: TextStyle(
                color: _getTagColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddAppointmentScreen(preselectedClient: widget.client),
                ),
              );
              if (result == true) {
                _loadAppointments();
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Новая запись'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navActive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Контакты',
            style: AppStyles.cardTitle,
          ),
          const SizedBox(height: 12),
          _buildContactRow(Icons.phone, widget.client.phone, 'Позвонить', () async {
            final uri = Uri.parse('tel:${widget.client.phone.replaceAll(RegExp(r'\D'), '')}');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          }),
          if (widget.client.telegram != null)
            _buildContactRow(Icons.telegram, widget.client.telegram!, 'Написать', () async {
              final username = widget.client.telegram!.replaceAll('@', '');
              final uri = Uri.parse('https://t.me/$username');
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            }),
          if (widget.client.address != null)
            _buildContactRow(Icons.location_on, widget.client.address!, 'Маршрут', () async {
              final uri = Uri.parse('https://yandex.ru/maps/?text=${Uri.encodeComponent(widget.client.address!)}');
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            }),
        ],
      ),
    );
  }
  
  Widget _buildContactRow(IconData icon, String text, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                color: AppColors.navActive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinanceCard(double totalRevenue, double avgCheck) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Финансы',
            style: AppStyles.cardTitle,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFinanceItem(
                  'Всего',
                  '${totalRevenue.toInt()} ₽',
                  AppColors.income,
                ),
              ),
              Expanded(
                child: _buildFinanceItem(
                  'Визитов',
                  '${_appointments.length}',
                  AppColors.navActive,
                ),
              ),
              Expanded(
                child: _buildFinanceItem(
                  'Средний чек',
                  '${avgCheck.toInt()} ₽',
                  AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinanceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'История визитов',
                style: AppStyles.cardTitle,
              ),
              Text(
                '${_appointments.length} ${_appointments.length == 1 ? 'визит' : _appointments.length < 5 ? 'визита' : 'визитов'}',
                style: TextStyle(
                  color: AppColors.navActive,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_appointments.isEmpty)
            Text(
              'Пока нет визитов',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ..._appointments.map((a) => _buildHistoryItem(a)),
        ],
      ),
    );
  }
  
  Widget _buildHistoryItem(Appointment appointment) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(appointment.dateTime);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appointment.status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              appointment.status == AppointmentStatus.donePaid ? Icons.check :
              appointment.status == AppointmentStatus.cancelled ? Icons.close :
              Icons.access_time,
              color: appointment.status.color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  appointment.service,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${appointment.price.toInt()} ₽',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: appointment.status == AppointmentStatus.donePaid 
                  ? AppColors.income 
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getTagColor() {
    switch (widget.client.tag) {
      case 'regular': return AppColors.tagRegular;
      case 'debtor': return AppColors.tagDebtor;
      case 'vip': return AppColors.tagVIP;
      case 'problem': return AppColors.tagProblem;
      default: return Colors.grey;
    }
  }
  
  String _getTagLabel() {
    switch (widget.client.tag) {
      case 'regular': return 'Постоянный';
      case 'debtor': return 'Должник';
      case 'vip': return 'VIP';
      case 'problem': return 'Проблемный';
      default: return 'Обычный';
    }
  }
}