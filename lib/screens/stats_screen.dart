import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../services/pdf_service.dart';
import '../services/share_service.dart';
import '../utils/constants.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _topClients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await DatabaseHelper.instance.getMonthlyStats(_selectedYear, _selectedMonth);
    final start = DateTime(_selectedYear, _selectedMonth, 1);
    final end = DateTime(_selectedYear, _selectedMonth + 1, 1);
    final topClients = await DatabaseHelper.instance.getTopClients(limit: 5, start: start, end: end);

    setState(() {
      _stats = stats;
      _topClients = topClients;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final income = (_stats?['income'] ?? 0).toDouble();
    final expenses = (_stats?['expenses'] ?? 0).toDouble();
    final materials = (_stats?['materials'] ?? 0).toDouble();
    final net = (_stats?['net'] ?? 0).toDouble();
    final count = (_stats?['appointmentCount'] ?? 0).toInt();
    final daily = (_stats?['daily'] ?? []) as List<Map<String, dynamic>>;

    final monthName = DateFormat('MMMM yyyy', 'ru').format(DateTime(_selectedYear, _selectedMonth));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Статистика', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Месяц выбор
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedMonth--;
                      if (_selectedMonth < 1) {
                        _selectedMonth = 12;
                        _selectedYear--;
                      }
                      _isLoading = true;
                    });
                    _loadData();
                  },
                  icon: const Icon(Icons.chevron_left, color: AppColors.navActive),
                ),
                Text(
                  monthName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedMonth++;
                      if (_selectedMonth > 12) {
                        _selectedMonth = 1;
                        _selectedYear++;
                      }
                      _isLoading = true;
                    });
                    _loadData();
                  },
                  icon: const Icon(Icons.chevron_right, color: AppColors.navActive),
                ),
                IconButton(
                  onPressed: () async {
                    final path = await PdfService.generateMonthlyReport(_selectedYear, _selectedMonth);
                    await ShareService.shareFile(path, subject: 'Отчет за $monthName');
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: AppColors.navActive),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Карточки
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Доход', income, AppColors.income),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Расход', expenses + materials, AppColors.expense),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Прибыль', net, net >= 0 ? AppColors.income : AppColors.expense),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Визитов', count.toDouble(), AppColors.navActive, isInt: true),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // График
            if (daily.isNotEmpty) ...[
              const Text('Доход по дням', style: AppStyles.cardTitle),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final day = value.toInt();
                            if (day < 1 || day > daily.length) return const SizedBox();
                            return Text(
                              day.toString(),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: daily.asMap().entries.map((e) {
                      final day = DateTime.parse(e.value['day'] as String).day;
                      final income = (e.value['income'] as num).toDouble();
                      return BarChartGroupData(
                        x: day,
                        barRods: [
                          BarChartRodData(
                            toY: income,
                            color: AppColors.income,
                            width: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Топ клиенты
            const Text('Топ клиенты', style: AppStyles.cardTitle),
            const SizedBox(height: 12),
            if (_topClients.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Нет данных',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ..._topClients.map((c) => _buildClientRow(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, double value, Color color, {bool isInt = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            isInt ? '${value.toInt()}' : '${NumberFormat('#,###').format(value.toInt())} ₽',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientRow(Map<String, dynamic> client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
                (client['name'] as String)[0].toUpperCase(),
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
                  client['name'],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${client['count']} визитов',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${NumberFormat('#,###').format((client['total'] as num).toInt())} ₽',
            style: const TextStyle(
              color: AppColors.income,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
