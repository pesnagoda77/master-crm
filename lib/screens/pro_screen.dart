import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  bool _isPro = false;
  int _clientCount = 0;
  int _freeLimit = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final isProStr = await DatabaseHelper.instance.getSetting('is_pro');
    final limitStr = await DatabaseHelper.instance.getSetting('free_client_limit');
    final count = await DatabaseHelper.instance.getClientCount();
    
    setState(() {
      _isPro = isProStr == 'true';
      _freeLimit = int.tryParse(limitStr ?? '5') ?? 5;
      _clientCount = count;
      _isLoading = false;
    });
  }

  Future<void> _activatePro() async {
    await DatabaseHelper.instance.setSetting('is_pro', 'true');
    setState(() => _isPro = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Подписка', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isPro)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.navActive.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.navActive, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified, color: AppColors.navActive, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'PRO активна',
                      style: TextStyle(
                        color: AppColors.navActive,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Безлимитные клиенты и все функции',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else ...[
              // Free status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_clientCount / $_freeLimit',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Клиентов добавлено',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _clientCount / _freeLimit,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation(
                        _clientCount >= _freeLimit ? Colors.red : AppColors.navActive,
                      ),
                    ),
                    if (_clientCount >= _freeLimit) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Лимит достигнут! Добавьте PRO для безлимитного доступа.',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // PRO features
              const Text('В PRO включено:', style: AppStyles.cardTitle),
              const SizedBox(height: 12),
              _buildFeatureItem(Icons.people, 'Безлимитные клиенты'),
              _buildFeatureItem(Icons.notifications, 'Push-уведомления'),
              _buildFeatureItem(Icons.bar_chart, 'Статистика и графики'),
              _buildFeatureItem(Icons.picture_as_pdf, 'Экспорт PDF отчётов'),
              _buildFeatureItem(Icons.repeat, 'Повторяющиеся записи'),
              _buildFeatureItem(Icons.attach_money, 'Частичная оплата'),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _activatePro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navActive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Активировать PRO',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navActive, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
