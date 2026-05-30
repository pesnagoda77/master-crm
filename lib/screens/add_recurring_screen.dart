import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../utils/constants.dart';

class AddRecurringScreen extends StatefulWidget {
  final Client? preselectedClient;
  
  const AddRecurringScreen({super.key, this.preselectedClient});
  
  @override
  State<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
  Client? _selectedClient;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  final _serviceController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _repeatType = 'weekly';
  int _repeatInterval = 1;
  DateTime? _endDate;
  
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
  
  Future<void> _selectDate(bool isEndDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isEndDate ? (_endDate ?? DateTime.now().add(const Duration(days: 30))) : _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
      setState(() {
        if (isEndDate) {
          _endDate = date;
        } else {
          _startDate = date;
        }
      });
    }
  }
  
  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
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
      setState(() => _startTime = time);
    }
  }
  
  Future<void> _saveRecurring() async {
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
    
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    
    await DatabaseHelper.instance.createRecurring({
      'clientId': _selectedClient!.id!,
      'clientName': _selectedClient!.name,
      'service': _serviceController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'address': _addressController.text.trim().isNotEmpty 
          ? _addressController.text.trim() 
          : _selectedClient!.address,
      'startDate': startDateTime.toIso8601String(),
      'repeatType': _repeatType,
      'repeatInterval': _repeatInterval,
      'endDate': _endDate?.toIso8601String(),
    });
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
  
  @override
  void dispose() {
    _serviceController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final timeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final dateStr = DateFormat('dd.MM.yyyy').format(_startDate);
    final endDateStr = _endDate != null ? DateFormat('dd.MM.yyyy').format(_endDate!) : 'Без окончания';
    
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
          'Повторяющаяся запись',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveRecurring,
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
            
            // Дата и время начала
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeButton(
                    Icons.calendar_today,
                    dateStr,
                    () => _selectDate(false),
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
              label: 'Адрес (если отличается)',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 24),
            
            // Повтор
            const Text('Повтор', style: AppStyles.cardTitle),
            const SizedBox(height: 12),
            _buildRepeatSelector(),
            const SizedBox(height: 16),
            
            // Интервал
            Row(
              children: [
                const Text('Каждый', style: TextStyle(color: AppColors.textPrimary)),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textPrimary),
                    controller: TextEditingController(text: _repeatInterval.toString()),
                    onChanged: (value) {
                      final n = int.tryParse(value);
                      if (n != null && n > 0) setState(() => _repeatInterval = n);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _repeatType == 'daily' ? 'день' : _repeatType == 'weekly' ? 'неделю' : 'месяц',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Дата окончания
            GestureDetector(
              onTap: () => _selectDate(true),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_busy, color: AppColors.navActive),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'До: $endDateStr',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _endDate = null),
                    ),
                  ],
                ),
              ),
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
  
  Widget _buildRepeatSelector() {
    final types = [
      {'value': 'daily', 'label': 'День', 'icon': Icons.calendar_view_day},
      {'value': 'weekly', 'label': 'Неделя', 'icon': Icons.calendar_view_week},
      {'value': 'monthly', 'label': 'Месяц', 'icon': Icons.calendar_view_month},
    ];
    
    return Row(
      children: types.map((type) {
        final isSelected = _repeatType == type['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _repeatType = type['value'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navActive.withOpacity(0.2) : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: AppColors.navActive, width: 2) : null,
              ),
              child: Column(
                children: [
                  Icon(
                    type['icon'] as IconData,
                    color: isSelected ? AppColors.navActive : AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type['label'] as String,
                    style: TextStyle(
                      color: isSelected ? AppColors.navActive : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
