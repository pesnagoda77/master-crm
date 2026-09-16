import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'appointment_materials_screen.dart';
import 'appointment_payments_screen.dart';
import '../database/database_helper.dart';
import '../models/appointment.dart';
import '../utils/constants.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Appointment appointment;
  
  const EditAppointmentScreen({super.key, required this.appointment});
  
  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  late final _serviceController = TextEditingController(text: widget.appointment.service);
  late final _priceController = TextEditingController(text: widget.appointment.price.toString());
  late final _addressController = TextEditingController(text: widget.appointment.address ?? '');
  late final _notesController = TextEditingController(text: widget.appointment.notes ?? '');
  
  late AppointmentStatus _status = widget.appointment.status;
  
  @override
  void dispose() {
    _serviceController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _saveChanges() async {
    if (_serviceController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Услуга и цена обязательны')),
      );
      return;
    }
    
    final updated = widget.appointment.copyWith(
      service: _serviceController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      address: _addressController.text.trim().isNotEmpty 
          ? _addressController.text.trim() 
          : null,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      status: _status,
    );
    
    await DatabaseHelper.instance.updateAppointment(updated);
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
  
  Future<void> _deleteAppointment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Удалить запись?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Это действие нельзя отменить',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await DatabaseHelper.instance.deleteAppointment(widget.appointment.id!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(widget.appointment.dateTime);
    final dateStr = DateFormat('dd.MM.yyyy').format(widget.appointment.dateTime);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Редактировать',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text(
              'Сохранить',
              style: TextStyle(
                color: AppColors.navActive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Клиент (только для просмотра)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.navActive.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.appointment.clientName[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.navActive,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.appointment.clientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$dateStr в $timeStr',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Статус
            const Text('Статус', style: AppStyles.cardTitle),
            const SizedBox(height: 12),
            _buildStatusSelector(),
            const SizedBox(height: 16),
            
            // Кнопки материалы / оплаты
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentMaterialsScreen(
                          appointmentId: widget.appointment.id!,
                          appointmentPrice: widget.appointment.price,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.build, size: 18),
                    label: const Text('Материалы'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navActive.withOpacity(0.2),
                      foregroundColor: AppColors.navActive,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentPaymentsScreen(
                          appointmentId: widget.appointment.id!,
                          totalPrice: widget.appointment.price,
                          status: widget.appointment.status,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.currency_ruble, size: 18),
                    label: const Text('Оплаты'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.income.withOpacity(0.2),
                      foregroundColor: AppColors.income,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Услуга
            _buildTextField(
              controller: _serviceController,
              label: 'Услуга *',
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 16),
            
            // Цена
            _buildTextField(
              controller: _priceController,
              label: 'Цена *',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Адрес
            _buildTextField(
              controller: _addressController,
              label: 'Адрес',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            
            // Заметки
            _buildTextField(
              controller: _notesController,
              label: 'Заметки',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            
            // Кнопка удаления
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deleteAppointment,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Удалить запись',
                  style: TextStyle(color: Colors.red),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusSelector() {
    final statuses = [
      {'value': AppointmentStatus.scheduled, 'label': 'Запланировано', 'color': AppColors.scheduled},
      {'value': AppointmentStatus.doneUnpaid, 'label': 'Выполнено, долг', 'color': AppColors.doneUnpaid},
      {'value': AppointmentStatus.donePaid, 'label': 'Выполнено, оплачено', 'color': AppColors.donePaid},
      {'value': AppointmentStatus.cancelled, 'label': 'Отменено', 'color': AppColors.cancelled},
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((s) {
        final status = s['value'] as AppointmentStatus;
        final isSelected = _status == status;
        final color = s['color'] as Color;
        
        return GestureDetector(
          onTap: () => setState(() => _status = status),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  s['label'] as String,
                  style: TextStyle(
                    color: isSelected ? color : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navActive, width: 2),
        ),
        filled: true,
        fillColor: AppColors.cardBackground,
      ),
    );
  }
}