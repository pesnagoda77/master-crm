import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';
import '../utils/constants.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});
  
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = 'materials';
  File? _receiptPhoto;
  
  final List<Map<String, dynamic>> _categories = [
    {'value': 'materials', 'label': 'Материалы', 'icon': Icons.build},
    {'value': 'fuel', 'label': 'ГСМ', 'icon': Icons.local_gas_station},
    {'value': 'rent', 'label': 'Аренда', 'icon': Icons.home},
    {'value': 'ads', 'label': 'Реклама', 'icon': Icons.campaign},
    {'value': 'other', 'label': 'Прочее', 'icon': Icons.more_horiz},
  ];
  
  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() {
        _receiptPhoto = File(pickedFile.path);
      });
      
      // Распознаём текст с чека
      await _recognizeReceipt(File(pickedFile.path));
    }
  }
  
  Future<void> _recognizeReceipt(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(imageFile);
    
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      // Ищем сумму в распознанном тексте
      double? foundAmount = _extractAmount(recognizedText.text);
      
      if (foundAmount != null) {
        setState(() {
          _amountController.text = foundAmount.toStringAsFixed(0);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Распознана сумма: ${foundAmount.toStringAsFixed(0)} ₽')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сумма не распознана, введите вручную')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка распознавания: $e')),
      );
    } finally {
      textRecognizer.close();
    }
  }
  
  double? _extractAmount(String text) {
    // Ищем паттерны сумм
    final patterns = [
      RegExp(r'ИТОГО[:\s]*(\d[\d\s]*[.,]?\d*)', caseSensitive: false),
      RegExp(r'ИТОГ[:\s]*(\d[\d\s]*[.,]?\d*)', caseSensitive: false),
      RegExp(r'TOTAL[:\s]*(\d[\d\s]*[.,]?\d*)', caseSensitive: false),
      RegExp(r'СУММА[:\s]*(\d[\d\s]*[.,]?\d*)', caseSensitive: false),
      RegExp(r'(\d[\d\s]*[.,]?\d*)\s*[₽$€]', caseSensitive: false),
      RegExp(r'(\d{1,3}(?:\s?\d{3})*[.,]?\d{0,2})', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String amountStr = match.group(1) ?? '';
        amountStr = amountStr.replaceAll(' ', '').replaceAll(',', '.');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0 && amount < 1000000) {
          return amount;
        }
      }
    }
    
    return null;
  }
  
  Future<void> _saveExpense() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите сумму')),
      );
      return;
    }
    
    final expense = Expense(
      date: DateTime.now(),
      amount: double.parse(_amountController.text.trim()),
      category: _selectedCategory,
      receiptPhoto: _receiptPhoto?.path,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
    );
    
    await DatabaseHelper.instance.createExpense(expense);
    
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
          'Новый расход',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveExpense,
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
              controller: _amountController,
              label: 'Сумма *',
              icon: Icons.currency_ruble,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            
            const Text('Категория', style: AppStyles.cardTitle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['value']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.expense.withOpacity(0.2) : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: AppColors.expense, width: 2)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          color: isSelected ? AppColors.expense : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat['label'] as String,
                          style: TextStyle(
                            color: isSelected ? AppColors.expense : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            const Text('Чек', style: AppStyles.cardTitle),
            const SizedBox(height: 12),
            _buildReceiptPhoto(),
            const SizedBox(height: 24),
            
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
  
  Widget _buildReceiptPhoto() {
    if (_receiptPhoto != null) {
      return GestureDetector(
        onTap: _takePhoto,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(_receiptPhoto!),
              fit: BoxFit.cover,
            ),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    }
    
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Сфоткать чек (OCR)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
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