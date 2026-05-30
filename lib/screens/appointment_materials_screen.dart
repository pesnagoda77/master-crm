import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

class AppointmentMaterialsScreen extends StatefulWidget {
  final int appointmentId;
  final double appointmentPrice;
  
  const AppointmentMaterialsScreen({
    super.key,
    required this.appointmentId,
    required this.appointmentPrice,
  });

  @override
  State<AppointmentMaterialsScreen> createState() => _AppointmentMaterialsScreenState();
}

class _AppointmentMaterialsScreenState extends State<AppointmentMaterialsScreen> {
  List<Map<String, dynamic>> _materials = [];
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }
  
  Future<void> _loadMaterials() async {
    final materials = await DatabaseHelper.instance.getMaterialsForAppointment(widget.appointmentId);
    setState(() => _materials = materials);
  }
  
  double get _totalMaterialsCost {
    return _materials.fold(0.0, (sum, m) => sum + (m['cost'] as num).toDouble());
  }
  
  double get _profit {
    return widget.appointmentPrice - _totalMaterialsCost;
  }
  
  Future<void> _addMaterial() async {
    if (_nameController.text.isEmpty || _costController.text.isEmpty) return;
    
    await DatabaseHelper.instance.addMaterial(
      widget.appointmentId,
      _nameController.text.trim(),
      double.parse(_costController.text.trim()),
    );
    
    _nameController.clear();
    _costController.clear();
    await _loadMaterials();
  }
  
  Future<void> _deleteMaterial(int id) async {
    await DatabaseHelper.instance.deleteMaterial(id);
    await _loadMaterials();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Материалы', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Сводка
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Выручка', widget.appointmentPrice, AppColors.income),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Материалы', _totalMaterialsCost, AppColors.expense),
                  const Divider(height: 24, color: AppColors.surface),
                  _buildSummaryRow('Прибыль', _profit, _profit >= 0 ? AppColors.income : AppColors.expense),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Добавление
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Название',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: '₽',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addMaterial,
                  icon: const Icon(Icons.add_circle, color: AppColors.navActive),
                  iconSize: 40,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Список
            Expanded(
              child: _materials.isEmpty
                  ? Center(
                      child: Text(
                        'Нет материалов',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _materials.length,
                      itemBuilder: (context, index) {
                        final m = _materials[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m['name'],
                                  style: const TextStyle(color: AppColors.textPrimary),
                                ),
                              ),
                              Text(
                                '${m['cost'].toStringAsFixed(0)} ₽',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deleteMaterial(m['id']),
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
        Text(
          '${value.toStringAsFixed(0)} ₽',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }
}
