import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SahwaApp());
}

// ----------------------------------------------------
// 1. نماذج البيانات (Models)
// ----------------------------------------------------

class AlarmItem {
  int hour;
  int minute;
  String label;
  bool isEnabled;
  int snoozeMinutes;
  String ringtoneName;
  String? ringtonePath;
  bool hasMathChallenge;

  AlarmItem({
    required this.hour,
    required this.minute,
    required this.label,
    this.isEnabled = true,
    this.snoozeMinutes = 5,
    this.ringtoneName = 'نغمة نسيم الفجر',
    this.ringtonePath,
    this.hasMathChallenge = false,
  });

  String get formattedTime {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'ص' : 'م';
    return '$h:$m $period';
  }

  Map<String, dynamic> toMap() => {
        'hour': hour,
        'minute': minute,
        'label': label,
        'isEnabled': isEnabled,
        'snoozeMinutes': snoozeMinutes,
        'ringtoneName': ringtoneName,
        'ringtonePath': ringtonePath,
        'hasMathChallenge': hasMathChallenge,
      };

  factory AlarmItem.fromMap(Map<String, dynamic> map) => AlarmItem(
        hour: map['hour'] ?? 6,
        minute: map['minute'] ?? 0,
        label: map['label'] ?? 'منبه',
        isEnabled: map['isEnabled'] ?? true,
        snoozeMinutes: map['snoozeMinutes'] ?? 5,
        ringtoneName: map['ringtoneName'] ?? 'نغمة نسيم الفجر',
        ringtonePath: map['ringtonePath'],
        hasMathChallenge: map['hasMathChallenge'] ?? false,
      );
}

class TaskItem {
  String title;
  String category;
  bool isCompleted;
  int streak;

  TaskItem({
    required this.title,
    required this.category,
    this.isCompleted = false,
    this.streak = 1,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'isCompleted': isCompleted,
        'streak': streak,
      };

  factory TaskItem.fromMap(Map<String, dynamic> map) => TaskItem(
        title: map['title'] ?? '',
        category: map['category'] ?? 'عادات',
        isCompleted: map['isCompleted'] ?? false,
        streak: map['streak'] ?? 1,
      );
}

// ----------------------------------------------------
// 2. التطبيق الرئيسي (Root App)
// ----------------------------------------------------

class SahwaApp extends StatefulWidget {
  const SahwaApp({super.key});

  @override
  State<SahwaApp> createState() => _SahwaAppState();
}

class _SahwaAppState extends State<SahwaApp> {
  ThemeMode _themeMode = ThemeMode.dark; // الوضع الليلي المريح للعين افتراضياً

  void _setTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'صحوة',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF59E0B),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // كحلي مريح للعين
        cardColor: const Color(0xFF1E293B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF59E0B),
          brightness: Brightness.dark,
        ),
      ),
      // دعم اتجاه اليمين لليسار (RTL) للغة العربية مباشرة
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },
      home: SahwaHomeScreen(
        currentTheme: _themeMode,
        onThemeChanged: _setTheme,
      ),
    );
  }
}

// ----------------------------------------------------
// 3. الشاشة الرئيسية والتبويبات
// ----------------------------------------------------

class SahwaHomeScreen extends StatefulWidget {
  final ThemeMode currentTheme;
  final Function(ThemeMode) onThemeChanged;

  const SahwaHomeScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<SahwaHomeScreen> createState() => _SahwaHomeScreenState();
}

class _SahwaHomeScreenState extends State<SahwaHomeScreen> {
  int _currentIndex = 0;
  List<AlarmItem> _alarms = [];
  List<TaskItem> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  // تحميل البيانات المحفوظة
  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final aJson = prefs.getString('alarms_data');
    final tJson = prefs.getString('tasks_data');

    setState(() {
      if (aJson != null && aJson.isNotEmpty) {
        try {
          final List list = jsonDecode(aJson);
          _alarms = list.map((e) => AlarmItem.fromMap(e)).toList();
        } catch (_) {}
      } else {
        // منبهات أولية جاهزة
        _alarms = [
          AlarmItem(hour: 5, minute: 15, label: 'صلاة الفجر وبداية البركة', isEnabled: true),
          AlarmItem(hour: 7, minute: 30, label: 'الاستعداد للعمل والدراسة', isEnabled: true, hasMathChallenge: true),
        ];
      }

      if (tJson != null && tJson.isNotEmpty) {
        try {
          final List list = jsonDecode(tJson);
          _tasks = list.map((e) => TaskItem.fromMap(e)).toList();
        } catch (_) {}
      } else {
        // مهام وعادات أولية جاهزة
        _tasks = [
          TaskItem(title: 'أذكار الصباح والورد القرآني', category: 'عبادات', isCompleted: true, streak: 5),
          TaskItem(title: 'تمارين خفيفة وشرب لتر ماء', category: 'صحة', isCompleted: false, streak: 3),
          TaskItem(title: 'تحديد أهم 3 أولويات لإنجاز اليوم', category: 'عمل', isCompleted: false, streak: 7),
        ];
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarms_data', jsonEncode(_alarms.map((e) => e.toMap()).toList()));
    await prefs.setString('tasks_data', jsonEncode(_tasks.map((e) => e.toMap()).toList()));
  }

  // نافذة إضافة/تعديل منبه
  void _showAlarmSheet([AlarmItem? existing, int? editIndex]) {
    TimeOfDay selectedTime = existing != null
        ? TimeOfDay(hour: existing.hour, minute: existing.minute)
        : const TimeOfDay(hour: 6, minute: 0);
    String label = existing?.label ?? '';
    int snooze = existing?.snoozeMinutes ?? 5;
    bool hasMath = existing?.hasMathChallenge ?? false;
    String ringtoneName = existing?.ringtoneName ?? 'نغمة نسيم الفجر';
    String? ringtonePath = existing?.ringtonePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'إضافة منبه ذكي جديد ⏰' : 'تعديل المنبه ⏰',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // اختيار الوقت
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: Colors.black26,
                      leading: const Icon(Icons.access_time_filled, color: Color(0xFFF59E0B)),
                      title: Text(
                        'وقت التنبيه: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      trailing: const Text('تغيير الوقت', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setSheetState(() => selectedTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // اسم المنبه
                    TextField(
                      controller: TextEditingController(text: label)..selection = TextSelection.collapsed(offset: label.length),
                      onChanged: (val) => label = val,
                      decoration: InputDecoration(
                        labelText: 'اسم المنبه',
                        hintText: 'مثال: صلاة الفجر، العمل، الرياضة',
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // زر اختيار نغمة من ملفات الهاتف
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.music_note, color: Color(0xFFF59E0B)),
                      label: Text(
                        'النغمة: $ringtoneName 🎵',
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(type: FileType.audio);
                          if (result != null && result.files.single.path != null) {
                            setSheetState(() {
                              ringtonePath = result.files.single.path;
                              ringtoneName = result.files.single.name;
                            });
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم اختيار النغمة المدمجة')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // مدة الغفوة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('مدة الغفوة:', style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<int>(
                          value: snooze,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('5 دقائق')),
                            DropdownMenuItem(value: 10, child: Text('10 دقائق')),
                            DropdownMenuItem(value: 15, child: Text('15 دقيقة')),
                          ],
                          onChanged: (v) {
                            if (v != null) setSheetState(() => snooze = v);
                          },
                        ),
                      ],
                    ),
                    // تحدي الاستيقاظ
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تحدي الاستيقاظ (حل مسألة حسابية)', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('حل مسألة لإيقاف المنبه للتأكد من اليقظة', style: TextStyle(fontSize: 12)),
                      value: hasMath,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (val) => setSheetState(() => hasMath = val),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        setState(() {
                          final newItem = AlarmItem(
                            hour: selectedTime.hour,
                            minute: selectedTime.minute,
                            label: label.isEmpty ? 'منبه' : label,
                            snoozeMinutes: snooze,
                            ringtoneName: ringtoneName,
                            ringtonePath: ringtonePath,
                            hasMathChallenge: hasMath,
                          );
                          if (editIndex != null) {
                            _alarms[editIndex] = newItem;
                          } else {
                            _alarms.add(newItem);
                          }
                          _saveData();
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('حفظ المنبه وتفعيله', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // محاكاة شاشة رنين المنبه مع التحدي الرياضي
  void _testAlarmRing(AlarmItem alarm) {
    int num1 = Random().nextInt(30) + 10;
    int num2 = Random().nextInt(20) + 5;
    int solution = num1 + num2;
    String answer = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Column(
            children: [
              const Icon(Icons.alarm, color: Color(0xFFF59E0B), size: 48),
              const SizedBox(height: 8),
              Text(alarm.label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text(alarm.formattedTime, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
            ],
          ),
        ),
        content: alarm.hasMathChallenge
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('حل المسألة التالية لإيقاف الرنين:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('$num1 + $num2 = ؟', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 10),
                  TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'اكتب الناتج هنا',
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (val) => answer = val.trim(),
                  ),
                ],
              )
            : const Text('حان وقت الاستيقاظ! صباح الهمة والإنجاز ☀️', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('غفوة (${alarm.snoozeMinutes} د)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
            onPressed: () {
              if (alarm.hasMathChallenge && answer != solution.toString()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('إجابة خاطئة! ركز وحاول مجدداً')),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إيقاف المنبه بنجاح! يومك مبارك')),
              );
            },
            child: const Text('إيقاف المنبه'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildAlarmsPage(),
      _buildTasksPage(),
      _buildStatsPage(),
      _buildSettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('صحوة • المنبه والمهام', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.alarm), label: 'المنبهات'),
          NavigationDestination(icon: Icon(Icons.task_alt), label: 'المهام'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'الإحصائيات'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
      floatingActionButton: _currentIndex < 2
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              child: const Icon(Icons.add),
              onPressed: () {
                if (_currentIndex == 0) {
                  _showAlarmSheet();
                } else {
                  _showAddTaskDialog();
                }
              },
            )
          : null,
    );
  }

  // تبويب المنبهات
  Widget _buildAlarmsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // بطاقة المنبه القادم
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color(0xFF1E293B),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المنبه القادم', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4