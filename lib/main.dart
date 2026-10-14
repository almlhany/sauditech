import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const SmartAlarmApp());
}

class SmartAlarmApp extends StatelessWidget {
  const SmartAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق المنبه والمهام',
      // دعم اللغة العربية بشكل كامل
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // الألوان والوضع الليلي
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        fontFamily: 'Cairo', // افتراض استخدام خط عربي مثل كاهيرو
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Cairo',
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AlarmsTab(),
    const TasksTab(),
    const StatisticsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنبه والمهام الذكية'),
        centerTitle: true,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'المنبه',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'المهام',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'الإحصائيات',
          ),
        ],
      ),
    );
  }
}

// صفحة المنبه
class AlarmsTab extends StatelessWidget {
  const AlarmsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.alarm, color: Colors.indigo, size: 32),
            title: const Text('07:00 ص', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            subtitle: const Text('الاستيقاظ للعمل - تكرار يومي'),
            trailing: Switch(
              value: true,
              onChanged: (bool value) {},
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            // إضافة نغمة من ملفات الهاتف أو منبه جديد
          },
          icon: const Icon(Icons.add),
          label: const Text('إضافة منبه جديد'),
        ),
      ],
    );
  }
}

// صفحة المهام اليومية
class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        CheckboxListTile(
          value: true,
          onChanged: null,
          title: Text('مراجعة التقويم اليومي', style: TextStyle(decoration: TextDecoration.lineThrough)),
          subtitle: Text('مكتملة - إشعار فوري'),
        ),
        CheckboxListTile(
          value: false,
          onChanged: null,
          title: Text('اجتماع العمل الأساسي'),
          subtitle: Text('الموعد: 10:00 صباحاً'),
        ),
      ],
    );
  }
}

// صفحة الإحصائيات الأسبوعية
class StatisticsTab extends StatelessWidget {
  const StatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.indigo),
            SizedBox(height: 16),
            Text(
              'نظام الإحصائيات الأسبوعي',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'أنجزت 85% من مهامك هذا الأسبوع. استمر في الأداء الرائع!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
