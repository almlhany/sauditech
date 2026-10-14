import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmNotifications.initialize();
  runApp(const SahwaApp());
}

class AlarmNotifications {
  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    try {
      final dynamic zone = await FlutterTimezone.getLocalTimezone();
      final String zoneName = zone is String ? zone : zone.name as String;
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      // If the device timezone cannot be read, timezone package default is used.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await notifications.initialize(settings);

    final androidPlugin = notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static Future<void> schedule(AlarmItem alarm, int id) async {
    await notifications.cancel(id);
    if (!alarm.isEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sahwa_alarms',
        'منبهات صحوة',
        channelDescription: 'تنبيهات تطبيق صحوة',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        playSound: true,
        enableVibration: true,
      ),
    );

    await notifications.zonedSchedule(
      id,
      alarm.label.isEmpty ? 'حان وقت الاستيقاظ' : alarm.label,
      alarm.hasMathChallenge
          ? 'حان وقت المنبه. افتح تطبيق صحوة لتحدي الاستيقاظ.'
          : 'حان وقت الاستيقاظ! افتح صحوة لإدارة المنبه.',
      next,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode(alarm.toMap()),
    );
  }

  static Future<void> cancel(int id) => notifications.cancel(id);

  static Future<void> rescheduleAll(List<AlarmItem> alarms) async {
    await notifications.cancelAll();
    for (var i = 0; i < alarms.length; i++) {
      await schedule(alarms[i], 1000 + i);
    }
  }
}

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
    this.ringtoneName = 'نغمة افتراضية',
    this.ringtonePath,
    this.hasMathChallenge = false,
  });

  String get formattedTime {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m ${hour < 12 ? 'ص' : 'م'}';
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
        hour: (map['hour'] as num?)?.toInt() ?? 6,
        minute: (map['minute'] as num?)?.toInt() ?? 0,
        label: map['label'] as String? ?? 'منبه',
        isEnabled: map['isEnabled'] as bool? ?? true,
        snoozeMinutes: (map['snoozeMinutes'] as num?)?.toInt() ?? 5,
        ringtoneName: map['ringtoneName'] as String? ?? 'نغمة افتراضية',
        ringtonePath: map['ringtonePath'] as String?,
        hasMathChallenge: map['hasMathChallenge'] as bool? ?? false,
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
        title: map['title'] as String? ?? '',
        category: map['category'] as String? ?? 'عادات',
        isCompleted: map['isCompleted'] as bool? ?? false,
        streak: (map['streak'] as num?)?.toInt() ?? 1,
      );
}

class SahwaApp extends StatefulWidget {
  const SahwaApp({super.key});

  @override
  State<SahwaApp> createState() => _SahwaAppState();
}

class _SahwaAppState extends State<SahwaApp> {
  ThemeMode themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'صحوة',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF59E0B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF59E0B),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: SahwaHomeScreen(
        themeMode: themeMode,
        onThemeChanged: (value) => setState(() => themeMode = value),
      ),
    );
  }
}

class SahwaHomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const SahwaHomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<SahwaHomeScreen> createState() => _SahwaHomeScreenState();
}

class _SahwaHomeScreenState extends State<SahwaHomeScreen> {
  int currentIndex = 0;
  List<AlarmItem> alarms = [];
  List<TaskItem> tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    List<AlarmItem> loadedAlarms = [];
    List<TaskItem> loadedTasks = [];

    try {
      final raw = prefs.getString('alarms_data');
      if (raw != null) {
        loadedAlarms = (jsonDecode(raw) as List)
            .map((e) => AlarmItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    try {
      final raw = prefs.getString('tasks_data');
      if (raw != null) {
        loadedTasks = (jsonDecode(raw) as List)
            .map((e) => TaskItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    if (loadedAlarms.isEmpty && prefs.getString('alarms_data') == null) {
      loadedAlarms = [
        AlarmItem(hour: 5, minute: 15, label: 'صلاة الفجر وبداية البركة'),
        AlarmItem(
          hour: 7,
          minute: 30,
          label: 'الاستعداد للعمل والدراسة',
          hasMathChallenge: true,
        ),
      ];
    }
    if (loadedTasks.isEmpty && prefs.getString('tasks_data') == null) {
      loadedTasks = [
        TaskItem(title: 'أذكار الصباح والورد القرآني', category: 'عبادات'),
        TaskItem(title: 'تمارين خفيفة وشرب الماء', category: 'صحة'),
        TaskItem(title: 'تحديد أهم 3 أولويات لليوم', category: 'عمل'),
      ];
    }

    if (!mounted) return;
    setState(() {
      alarms = loadedAlarms;
      tasks = loadedTasks;
      loading = false;
    });
    await AlarmNotifications.rescheduleAll(alarms);
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'alarms_data',
      jsonEncode(alarms.map((e) => e.toMap()).toList()),
    );
    await prefs.setString(
      'tasks_data',
      jsonEncode(tasks.map((e) => e.toMap()).toList()),
    );
    await AlarmNotifications.rescheduleAll(alarms);
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> showAlarmEditor({AlarmItem? existing, int? index}) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    TimeOfDay selectedTime = existing == null
        ? const TimeOfDay(hour: 6, minute: 0)
        : TimeOfDay(hour: existing.hour, minute: existing.minute);
    int snooze = existing?.snoozeMinutes ?? 5;
    bool challenge = existing?.hasMathChallenge ?? false;
    String ringtoneName = existing?.ringtoneName ?? 'نغمة افتراضية';
    String? ringtonePath = existing?.ringtonePath;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'إضافة منبه جديد ⏰' : 'تعديل المنبه ⏰',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Color(0xFFF59E0B)),
                  title: Text('الوقت: ${selectedTime.format(context)}'),
                  trailing: const Icon(Icons.edit),
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
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنبه',
                    hintText: 'مثال: صلاة الفجر أو العمل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.music_note),
                  label: Text(
                    'اختيار ملف صوتي: $ringtoneName',
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () async {
                    try {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.audio,
                      );
                      if (result != null && result.files.single.path != null) {
                        setSheetState(() {
                          ringtonePath = result.files.single.path;
                          ringtoneName = result.files.single.name;
                        });
                        showMessage(
                          'تم حفظ اسم الملف. تشغيل الملف المخصص يحتاج إعدادًا إضافيًا.',
                        );
                      }
                    } catch (_) {
                      showMessage('تعذر اختيار الملف الصوتي.');
                    }
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('مدة الغفوة'),
                    DropdownButton<int>(
                      value: snooze,
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 دقائق')),
                        DropdownMenuItem(value: 10, child: Text('10 دقائق')),
                        DropdownMenuItem(value: 15, child: Text('15 دقيقة')),
                      ],
                      onChanged: (value) {
                        if (value != null) setSheetState(() => snooze = value);
                      },
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تحدي حسابي لإيقاف المنبه'),
                  value: challenge,
                  onChanged: (value) =>
                      setSheetState(() => challenge = value),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    final item = AlarmItem(
                      hour: selectedTime.hour,
                      minute: selectedTime.minute,
                      label: labelController.text.trim().isEmpty
                          ? 'منبه'
                          : labelController.text.trim(),
                      isEnabled: existing?.isEnabled ?? true,
                      snoozeMinutes: snooze,
                      ringtoneName: ringtoneName,
                      ringtonePath: ringtonePath,
                      hasMathChallenge: challenge,
                    );
                    setState(() {
                      if (index == null) {
                        alarms.add(item);
                      } else {
                        alarms[index] = item;
                      }
                    });
                    await saveData();
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    showMessage('تم حفظ المنبه وجدولته.');
                  },
                  child: const Text('حفظ المنبه'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    labelController.dispose();
  }

  Future<void> deleteAlarm(int index) async {
    setState(() => alarms.removeAt(index));
    await saveData();
    showMessage('تم حذف المنبه.');
  }

  Future<void> showAddTaskDialog() async {
    final controller = TextEditingController();
    String category = 'عادات';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة مهمة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'اسم المهمة'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: const ['عادات', 'عبادات', 'صحة', 'عمل', 'دراسة']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => category = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                setState(() {
                  tasks.add(TaskItem(
                    title: controller.text.trim(),
                    category: category,
                  ));
                });
                await saveData();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> toggleTask(int index, bool value) async {
    setState(() {
      tasks[index].isCompleted = value;
      if (value) {
        tasks[index].streak++;
      }
    });
    await saveData();
  }

  Future<void> testAlarm(AlarmItem alarm) async {
    int a = Random().nextInt(30) + 10;
    int b = Random().nextInt(20) + 5;
    final answerController = TextEditingController();
    bool stopped = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(alarm.label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(alarm.formattedTime,
                  style: const TextStyle(fontSize: 28, color: Colors.amber)),
              if (alarm.hasMathChallenge) ...[
                Text('$a + $b = ؟',
                    style: const TextStyle(fontSize: 24)),
                TextField(
                  controller: answerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الإجابة'),
                ),
              ] else
                const Text('حان وقت الاستيقاظ!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                showMessage(
                  'الغفوة المحفوظة ${alarm.snoozeMinutes} دقائق. التنبيه الحالي المجدول يومي.',
                );
              },
              child: Text('غفوة ${alarm.snoozeMinutes} د'),
            ),
            FilledButton(
              onPressed: () {
                if (alarm.hasMathChallenge &&
                    int.tryParse(answerController.text.trim()) != a + b) {
                  showMessage('الإجابة غير صحيحة، حاول مرة أخرى.');
                  return;
                }
                stopped = true;
                Navigator.pop(dialogContext);
                showMessage('تم إيقاف التنبيه التجريبي.');
              },
              child: const Text('إيقاف'),
            ),
          ],
        ),
      ),
    );
    answerController.dispose();
    if (stopped) {}
  }

  Widget buildAlarmsPage() {
    if (loading) return const Center(child: CircularProgressIndicator());
    final enabled = alarms.where((a) => a.isEnabled).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('المنبهات النشطة',
                    style: TextStyle(color: Colors.amber)),
                const SizedBox(height: 6),
                Text(
                  enabled.isEmpty
                      ? 'لا توجد منبهات مفعّلة'
                      : '${enabled.length} منبه نشط',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text('تُجدول التنبيهات يوميًا في الوقت المحدد.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (alarms.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('لا توجد منبهات. اضغط + لإضافة منبه.',
                textAlign: TextAlign.center),
          ),
        ...alarms.asMap().entries.map((entry) {
          final index = entry.key;
          final alarm = entry.value;
          return Card(
            child: ListTile(
              leading: Icon(
                alarm.isEnabled ? Icons.alarm_on : Icons.alarm_off,
                color: alarm.isEnabled ? Colors.amber : Colors.grey,
                size: 30,
              ),
              title: Text(alarm.label,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${alarm.formattedTime} • غفوة ${alarm.snoozeMinutes} د'
                '${alarm.hasMathChallenge ? ' • تحدي حسابي' : ''}',
              ),
              onTap: () => testAlarm(alarm),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'toggle') {
                    setState(() => alarm.isEnabled = !alarm.isEnabled);
                    await saveData();
                  } else if (value == 'edit') {
                    await showAlarmEditor(existing: alarm, index: index);
                  } else if (value == 'delete') {
                    await deleteAlarm(index);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(alarm.isEnabled ? 'تعطيل' : 'تفعيل'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  const PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget buildTasksPage() {
    if (loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'أنجزت ${tasks.where((t) => t.isCompleted).length} من ${tasks.length} مهمة',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ...tasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          return Card(
            child: CheckboxListTile(
              value: task.isCompleted,
              onChanged: (value) => toggleTask(index, value ?? false),
              title: Text(task.title),
              subtitle: Text('${task.category} • سلسلة ${task.streak}'),
              secondary: IconButton(
                tooltip: 'حذف المهمة',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  setState(() => tasks.removeAt(index));
                  await saveData();
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget buildStatsPage() {
    final completed = tasks.where((t) => t.isCompleted).length;
    final enabled = alarms.where((a) => a.isEnabled).length;
    final percent = tasks.isEmpty ? 0 : (completed / tasks.length * 100).round();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('إحصائياتك',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _statCard('المنبهات المفعلة', '$enabled', Icons.alarm),
        _statCard('إجمالي المهام', '${tasks.length}', Icons.task_alt),
        _statCard('المهام المكتملة', '$completed', Icons.check_circle),
        _statCard('نسبة الإنجاز', '$percent%', Icons.bar_chart),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.amber, size: 32),
        title: Text(title),
        trailing: Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget buildSettingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('الإعدادات',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            title: const Text('الوضع الليلي'),
            secondary: const Icon(Icons.dark_mode),
            value: widget.themeMode == ThemeMode.dark,
            onChanged: (value) =>
                widget.onThemeChanged(value ? ThemeMode.dark : ThemeMode.light),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('إعادة جدولة المنبهات'),
            subtitle: const Text('إعادة ضبط جميع التنبيهات المحفوظة'),
            onTap: () async {
              await AlarmNotifications.rescheduleAll(alarms);
              showMessage('تمت إعادة جدولة المنبهات.');
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('حول صحوة'),
            subtitle: const Text(
              'منبه ومهام يومية. اسم النغمة المخصصة يُحفظ، لكن تشغيلها يحتاج إعداد موارد صوت Android إضافيًا.',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildAlarmsPage(),
      buildTasksPage(),
      buildStatsPage(),
      buildSettingsPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('صحوة • المنبه والمهام',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: pages[currentIndex],
      floatingActionButton: currentIndex < 2
          ? FloatingActionButton(
              onPressed: () {
                if (currentIndex == 0) {
                  showAlarmEditor();
                } else {
                  showAddTaskDialog();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (value) => setState(() => currentIndex = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.alarm), label: 'المنبهات'),
          NavigationDestination(
              icon: Icon(Icons.task_alt), label: 'المهام'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart), label: 'الإحصائيات'),
          NavigationDestination(
              icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}