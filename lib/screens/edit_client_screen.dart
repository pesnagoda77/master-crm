import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../utils/constants.dart';

class EditClientScreen extends StatefulWidget {
  final Client client;
  
  const EditClientScreen({super.key, required this.client});
  
  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  late final _nameController = TextEditingController(text: widget.client.name);
  late final _phoneController = TextEditingController(text: widget.client.phone);
  late final _telegramController = TextEditingController(text: widget.client.telegram ?? '');
  late final _addressController = TextEditingController(text: widget.client.address ?? '');
  late final _notesController = TextEditingController(text: widget.client.notes ?? '');
  
  late String _selectedTag = widget.client.tag;
  
  final List<Map<String, dynamic>> _tags = [
    {'value': 'regular', 'label': 'Постоянный', 'color': AppColors.tagRegular},
    {'value': 'debtor', 'label': 'Должник', 'color': AppColors.tagDebtor},
    {'value': 'vip', 'label': 'VIP', 'color': AppColors.tagVIP},
    {'value': 'problem', 'label': 'Проблемный', 'color': AppColors.tagProblem},
  ];
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя и телефон обязательны')),
      );
      return;
    }
    
    final updated = widget.client.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      telegram: _telegramController.text.trim().isNotEmpty 
          ? _telegramController.text.trim() 
          : null,
      address: _addressController.text.trim().isNotEmpty 
          ? _addressController.text.trim() 
          : null,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      tag: _selectedTag,
    );
    
    await DatabaseHelper.instance.updateClient(updated);
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
  
  Future<void> _deleteClient() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Удалить клиента?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Это удалит ${widget.client.name} и все его записи. Действие нельзя отменить.',
          style: const TextStyle(color: AppColors.textSecondary),
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
      await DatabaseHelper.instance.deleteClient(widget.client.id!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
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
          'Редактировать клиента',
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
            _buildTextField(
              controller: _nameController,
              label: 'Имя *',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _phoneController,
              label: 'Телефон *',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _telegramController,
              label: 'Telegram',
              icon: Icons.telegram,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _addressController,
              label: 'Адрес',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 24),
            
            const Text('Тег', style: AppStyles.cardTitle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedTag == tag['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedTag = tag['value']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (tag['color'] as Color).withOpacity(0.2) 
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: tag['color'] as Color, width: 2)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: tag['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tag['label'] as String,
                          style: TextStyle(
                            color: isSelected 
                                ? tag['color'] as Color 
                                : AppColors.textSecondary,
                            fontWeight: isSelected 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            _buildTextField(
              controller: _notesController,
              label: 'Заметки',
              icon: Icons.notes_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deleteClient,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Удалить клиента',
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