import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class AddAppointmentScreen extends StatefulWidget {
  final Client? preselectedClient;
  
  const AddAppointmentScreen({super.key, this.preselectedClient});
  
  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  Client? _selectedClient;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final _serviceController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  List<Client> _clients = [];
  
  @override
  void initState() {
    super.initState();
    _selectedClient = widget.preselectedClient;
    _loadClients();
  }
  
  Future<void> _loadClients() async {
    final clients = await DatabaseHelper.instance.getAllClients();
    setState(() => _clients = clients);
  }
  
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.navActive,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }
  
  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.navActive,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }
  
  Future<void> _saveAppointment() async {
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите клиента')),
      );
      return;
    }
    
    if (_serviceController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Услуга и цена обязательны')),
      );
      return;
    }
    
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    final appointment = Appointment(
      clientId: _selectedClient!.id!,
      clientName: _selectedClient!.name,
      dateTime: dateTime,
      service: _serviceController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      address: _addressController.text.trim().isNotEmpty 
          ? _addressController.text.trim() 
          : _selectedClient!.address,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
    );
    
    final id = await DatabaseHelper.instance.createAppointment(appointment);
    
    // Schedule notification
    await NotificationService().scheduleAppointmentReminder(
      id,
      dateTime,
      _selectedClient!.name,
      _serviceController.text.trim(),
    );
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
  
  @override
  void dispose() {
    _serviceController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final dateStr = DateFormat('dd.MM.yyyy').format(_selectedDate);
    
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
          'Новая запись',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveAppointment,
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
            // Клиент
            const Text('Клиент', style: AppStyles.cardTitle),
            const SizedBox(height: 8),
            _buildClientSelector(),
            const SizedBox(height: 16),
            
            // Дата и время
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeButton(
                    Icons.calendar_today,
                    dateStr,
                    _selectDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateTimeButton(
                    Icons.access_time,
                    timeStr,
                    _selectTime,
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
              label: 'Адрес (если отличается от клиента)',
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
          ],
        ),
      ),
    );
  }
  
  Widget _buildClientSelector() {
    if (_selectedClient != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.navActive.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.navActive),
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
                  _selectedClient!.name[0].toUpperCase(),
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
                    _selectedClient!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _selectedClient!.phone,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () => setState(() => _selectedClient = null),
            ),
          ],
        ),
      );
    }
    
    return GestureDetector(
      onTap: _showClientPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.navActive),
        ),
        child: const Row(
          children: [
            Icon(Icons.person_add, color: AppColors.navActive),
            SizedBox(width: 12),
            Text(
              'Выберите клиента',
              style: TextStyle(color: AppColors.navActive),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
  
  void _showClientPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Выберите клиента',
                      style: AppStyles.cardTitle,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _clients.length,
                  itemBuilder: (context, index) {
                    final client = _clients[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.navActive.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            client.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.navActive,
                            ),
                          ),
                        ),
                      ),
                      title: Text(client.name, style: const TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text(client.phone, style: const TextStyle(color: AppColors.textSecondary)),
                      onTap: () {
                        setState(() => _selectedClient = client);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDateTimeButton(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.navActive, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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