import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SahwaApp());
}

// نموذج المنبه
class AlarmModel {
  int hour;
  int minute;
  String label;
  bool isEnabled;
  int snoozeMinutes;
  String ringtoneName;
  String? ringtonePath;
  bool hasMathChallenge;

  AlarmModel({
    required this.hour,
    required this.minute,
    required this.label,
    this.isEnabled = true,
    this.snoozeMinutes = 5,
    this.ringtoneName = 'نغمة الصحوة الهادئة',
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

  factory AlarmModel.fromMap(Map<String, dynamic> map) => AlarmModel(
        hour: map['hour'],
        minute: map['minute'],
        label: map['label'],
        isEnabled: map['isEnabled'] ?? true,
        snoozeMinutes: map['snoozeMinutes'] ?? 5,
        ringtoneName: map['ringtoneName'] ?? 'نغمة الصحوة الهادئة',
        ringtonePath: map['ringtonePath'],
        hasMathChallenge: map['hasMathChallenge'] ?? false,
      );
}

// نموذج المهمة اليومية
class TaskModel {
  String title;
  String category;
  bool isCompleted;
  int streak;

  TaskModel({
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

  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
        title: map['title'],
        category: map['category'] ?? 'عادات',
        isCompleted: map['isCompleted'] ?? false,
        streak: map['streak'] ?? 1,
      );
}

class SahwaApp extends StatefulWidget {
  const SahwaApp({super.key});

  @override
  State<SahwaApp> createState() => _SahwaAppState();
}

class _SahwaAppState extends State<SahwaApp> {
  ThemeMode _themeMode = ThemeMode.dark; // الوضع الليلي المريح للعين افتراضياً

  void toggleTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'صحوة - المنبه الذكي',
      debugShowCheckedModeBanner: false,
      // الدعم الكامل للغة العربية
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFF59E0B),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF59E0B),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFF59E0B),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // كحلي مريح للعين
        cardColor: const Color(0xFF1E293B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF59E0B),
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(onThemeChanged: toggleTheme, currentTheme: _themeMode),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentTheme;

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<AlarmModel> _alarms = [];
  List<TaskModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // تحميل البيانات المحفوظة محلياً
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getString('saved_alarms');
    final tasksJson = prefs.getString('saved_tasks');

    setState(() {
      if (alarmsJson != null) {
        final List decoded = jsonDecode(alarmsJson);
        _alarms = decoded.map((e) => AlarmModel.fromMap(e)).toList();
      } else {
        // منبهات افتراضية
        _alarms = [
          AlarmModel(hour: 5, minute: 15, label: 'صلاة الفجر وبداية البركة'),
          AlarmModel(hour: 7, minute: 30, label: 'الاستعداد للعمل والدراسة', hasMathChallenge: true),
        ];
      }

      if (tasksJson != null) {
        final List decoded = jsonDecode(tasksJson);
        _tasks = decoded.map((e) => TaskModel.fromMap(e)).toList();
      } else {
        // مهام افتراضية
        _tasks = [
          TaskModel(title: 'أذكار الصباح والورد القرآني', category: 'عبادات', isCompleted: true, streak: 5),
          TaskModel(title: 'مشي 20 دقيقة وشرب لتر ماء', category: 'صحة', streak: 3),
          TaskModel(title: 'مراجعة أولويات اليوم', category: 'عمل', streak: 7),
        ];
      }
    });
  }

  // حفظ البيانات
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_alarms', jsonEncode(_alarms.map((e) => e.toMap()).toList()));
    await prefs.setString('saved_tasks', jsonEncode(_tasks.map((e) => e.toMap()).toList()));
  }

  // إضافة أو تعديل منبه
  void _openAlarmBottomSheet([AlarmModel? existing, int? index]) {
    TimeOfDay selectedTime = existing != null
        ? TimeOfDay(hour: existing.hour, minute: existing.minute)
        : const TimeOfDay(hour: 6, minute: 0);
    String label = existing?.label ?? '';
    int snooze = existing?.snoozeMinutes ?? 5;
    bool hasMath = existing?.hasMathChallenge ?? false;
    String ringtoneName = existing?.ringtoneName ?? 'نغمة الصحوة الهادئة';
    String? ringtonePath = existing?.ringtonePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedCornerShape(topRight: Radius.circular(24), topLeft: Radius.circular(24)),
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
                      existing == null ? 'إضافة منبه جديد ⏰' : 'تعديل المنبه ⏰',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // اختيار الوقت
                    ListTile(
                      shape: RoundedCornerShape(12),
                      tileColor: Colors.black26,
                      leading: const Icon(Icons.access_time, color: Color(0xFFF59E0B)),
                      title: Text(
                        'وقت التنبيه: ${selectedTime.format(context)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      trailing: const Text('تغيير', style: TextStyle(color: Color(0xFFF59E0B))),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // زر اختيار نغمة من ملفات الهاتف
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.audiotrack, color: Color(0xFFF59E0B)),
                      label: Text(
                        'نغمة التنبيه: $ringtoneName 🎵',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
                        if (result != null && result.files.single.path != null) {
                          setSheetState(() {
                            ringtonePath = result.files.single.path;
                            ringtoneName = result.files.single.name;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // خيارات الغفوة وتحدي الاستيقاظ
                    SwitchListTile(
                      title: const Text('تحدي الاستيقاظ (حل مسألة حسابية)'),
                      subtitle: const Text('يضمن استيقاظك التام قبل إيقاف الرنين'),
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
                        shape: RoundedCornerShape(12),
                      ),
                      child: const Text('حفظ المنبه وتفعيله', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () {
                        setState(() {
                          final alarm = AlarmModel(
                            hour: selectedTime.hour,
                            minute: selectedTime.minute,
                            label: label.isEmpty ? 'منبه' : label,
                            snoozeMinutes: snooze,
                            hasMathChallenge: hasMath,
                            ringtoneName: ringtoneName,
                            ringtonePath: ringtonePath,
                          );
                          if (index != null) {
                            _alarms[index] = alarm;
                          } else {
                            _alarms.add(alarm);
                          }
                          _saveData();
                        });
                        Navigator.pop(context);
                      },
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

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildAlarmsTab(),
      _buildTasksTab(),
      _buildStatsTab(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('صحوة • المنبه والمهام الذكية', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.alarm), label: 'المنبهات'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'المهام'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'الإحصائيات'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
      floatingActionButton: _currentIndex < 2
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFF59E0B),
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () {
                if (_currentIndex == 0) {
                  _openAlarmBottomSheet();
                } else {
                  _openAddTaskDialog();
                }
              },
            )
          : null,
    );
  }

  // تبويب المنبهات
  Widget _buildAlarmsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // بطاقة المنبه القادم
        Card(
          shape: RoundedCornerShape(20),
          color: const Color(0xFF1E293B),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المنبه القادم', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      _alarms.isNotEmpty ? _alarms.first.formattedTime : '--:--',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _alarms.isNotEmpty ? _alarms.first.label : 'لا توجد منبهات مضافة',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0x33F59E0B),
                  child: Icon(Icons.notifications_active, color: Color(0xFFF59E0B), size: 28),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('المنبهات النشطة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ..._alarms.asMap().entries.map((entry) {
          final idx = entry.key;
          final alarm = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedCornerShape(16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () => _openAlarmBottomSheet(alarm, idx),
              title: Text(alarm.formattedTime, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              subtitle: Text('${alarm.label} • ${alarm.ringtoneName}'),
              trailing: Switch(
                value: alarm.isEnabled,
                activeColor: const Color(0xFFF59E0B),
                onChanged: (val) {
                  setState(() {
                    alarm.isEnabled = val;
                    _saveData();
                  });
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  // تبويب المهام
  Widget _buildTasksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._tasks.map((task) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedCornerShape(14),
            child: CheckboxListTile(
              activeColor: const Color(0xFFF59E0B),
              value: task.isCompleted,
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('${task.category}  •  سلسلة: ${task.streak} أيام 🔥'),
              onChanged: (val) {
                setState(() {
                  task.isCompleted = val ?? false;
                  if (task.isCompleted) task.streak += 1;
                  _saveData();
                });
              },
            ),
          );
        }),
      ],
    );
  }

  void _openAddTaskDialog() {
    String taskTitle = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مهمة يومية جديدة'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'اكتب اسم المهمة أو العادة...'),
          onChanged: (val) => taskTitle = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (taskTitle.isNotEmpty) {
                setState(() {
                  _tasks.add(TaskModel(title: taskTitle, category: 'عادات'));
                  _saveData();
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  // تبويب الإحصائيات
  Widget _buildStatsTab() {
    int completed = _tasks.where((t) => t.isCompleted).length;
    int score = _tasks.isNotEmpty ? ((completed / _tasks.length) * 100).toInt() : 85;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.Center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    color: const Color(0xFFF59E0B),
                    backgroundColor: Colors.white10,
                  ),
                ),
                Text('$score%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('معدل الانضباط والإنتاجية الأسبوعي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('أنجزت $completed من أصل ${_tasks.length} مه