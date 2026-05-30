import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/pro_screen.dart';
import 'screens/recurring_screen.dart';
import 'services/notification_service.dart';
import 'widgets/bottom_nav.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  await NotificationService().init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мастер CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Порядок должен совпадать с bottom_nav.dart:
  // 0 = Главная, 1 = Календарь, 2 = Клиенты, 3 = Финансы, 4 = Статистика
  late final List<Widget> _screens = [
    HomeScreen(
      onCalendarTap: () => setState(() => _currentIndex = 1),
    ),                         // индекс 0
    const CalendarScreen(),    // индекс 1
    const ClientsScreen(),     // индекс 2
    const FinanceScreen(),     // индекс 3
    const StatsScreen(),       // индекс 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 ? AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Мастер CRM', style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
      ) : null,
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.navActive.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(Icons.business, color: AppColors.navActive, size: 40),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Мастер CRM',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'v2.0',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.surface),
              ListTile(
                leading: const Icon(Icons.repeat, color: AppColors.navActive),
                title: const Text('Повторяющиеся', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: AppColors.navActive),
                title: const Text('Настройки', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.star, color: AppColors.navActive),
                title: const Text('PRO', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProScreen()));
                },
              ),
            ],
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}