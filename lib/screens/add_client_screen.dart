import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../utils/constants.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedTag = 'regular';

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

  // МАСКА ТЕЛЕФОНА
  String _formatPhone(String text) {
    String digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('8')) {
      digits = '7' + digits.substring(1);
    }
    if (!digits.startsWith('7')) {
      digits = '7' + digits;
    }

    if (digits.length >= 11) {
      return '+7 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7, 9)}-${digits.substring(9, 11)}';
    } else if (digits.length >= 7) {
      return '+7 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    } else if (digits.length >= 4) {
      return '+7 (${digits.substring(1, 4)}) ${digits.substring(4)}';
    } else if (digits.length >= 1) {
      return '+7 (${digits.substring(1)}';
    }
    return '+7';
  }

  String _normalizePhone(String text) {
    String digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('8')) {
      digits = '7' + digits.substring(1);
    }
    if (!digits.startsWith('7')) {
      digits = '7' + digits;
    }
    return '+$digits';
  }

  Future<void> _pickContact() async {
    // Запрашиваем разрешение
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Разрешение на контакты не получено')),
      );
      return;
    }

    // Открываем picker контактов
    final contact = await FlutterContacts.openExternalPick();

    if (contact != null) {
      setState(() {
        _nameController.text = contact.displayName;

        // Берём первый телефон
        if (contact.phones.isNotEmpty) {
          final phone = contact.phones.first.number;
          _phoneController.text = _formatPhone(phone);
        }
      });
    }
  }

  Future<void> _saveClient() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя и телефон обязательны')),
      );
      return;
    }

    final normalizedPhone = _normalizePhone(_phoneController.text);

    final client = Client(
      name: _nameController.text.trim(),
      phone: normalizedPhone,
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

    await DatabaseHelper.instance.createClient(client);

    if (mounted) {
      Navigator.pop(context, true);
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
          'Новый клиент',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveClient,
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

            // Телефон с кнопкой контактов
            _buildPhoneField(),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: AppColors.textPrimary),
          onChanged: (value) {
            final formatted = _formatPhone(value);
            if (formatted != value) {
              _phoneController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          },
          decoration: InputDecoration(
            labelText: 'Телефон *',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.phone_outlined,
                color: AppColors.textSecondary),
            hintText: '+7 (900) 123-45-67',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
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
              borderSide:
                  const BorderSide(color: AppColors.navActive, width: 2),
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
          ),
        ),
        const SizedBox(height: 8),
        // Кнопка выбора из контактов
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickContact,
            icon: const Icon(Icons.contacts_outlined, size: 18),
            label: const Text('Выбрать из контактов'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navActive.withOpacity(0.2),
              foregroundColor: AppColors.navActive,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
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
