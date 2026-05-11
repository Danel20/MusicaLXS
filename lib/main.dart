import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:collection/collection.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const String supabaseUrl = 'https://yhmasnxfrzzbqdhgqbhj.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlobWFzbnhmcnp6YnFkaGdxYmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3NjYwNzUsImV4cCI6MjA5MTM0MjA3NX0.n-5TUpfB11thBVsa9m--4qAeKBVSdOkd8IuHZs9rBsM';
const String asistencixs_sebipca_version = "1.0.5";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('es_ES', null);
    await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        realtimeClientOptions: const RealtimeClientOptions(
          timeout: Duration(seconds: 20),
        ),

    );
    /*

    Supabase.instance.client.realtime.setAuth(
      supabaseAnonKey,
    );
    Supabase.instance.client.realtime.connect();

     */
  } catch (e) {
    debugPrint("Error inicializando Supabase y localización: $e");
  }
  runApp(const AttendanceApp());
}

enum AttendanceStatus { none, present, absent, reported }
enum AppSection { alimentacion, lavado }

/*
class RealtimeService {
  static final RealtimeService _instance =
  RealtimeService._internal();

  factory RealtimeService() => _instance;

  RealtimeService._internal();

  final client = Supabase.instance.client;

  RealtimeChannel? _channel;

  void start(VoidCallback onChange) {
    _channel ??=
    client.channel("global-db")
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: "public",
        callback: (_) => onChange(),
      )
      ..subscribe();
  }

  void stop() {
    _channel?.unsubscribe();
    _channel = null;
  }
}

*/

class AttendanceRepository {
  final client = Supabase.instance.client;

  Future<void> save(
      String personId,
      DateTime date,
      AttendanceStatus status,
      ) async {
    final key = DateFormat("yyyy-MM-dd").format(date);

    await client.from("attendance").upsert({
      "person_id": personId,
      "date": key,
      "status": status.name,
    });
  }
}

class Person {
  final String id;
  String firstName;
  String lastName;
  DateTime? birthday;
  Map<String, AttendanceStatus> attendance;

  Person({required this.id, required this.firstName, required this.lastName, this.birthday, Map<String, AttendanceStatus>? attendance})
      : attendance = attendance ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'birthday': birthday?.toIso8601String(),
    'attendance': attendance.map((k, v) => MapEntry(k, v.name)),
  };
}

class AttendanceGroup {
  final String id;
  String name;
  String section;
  String? password;
  List<Person> people;
  AttendanceGroup({required this.id, required this.name, required this.section, this.password, List<Person>? people}) : people = people ?? [];
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'section': section, 'password': password, 'people': people.map((p) => p.toJson()).toList()};
}

class SupabaseService {
  static final client = Supabase.instance.client;

  static Future<List<AttendanceGroup>> fetchGroupsBySection(String section) async {
    final List<AttendanceGroup> groups = [];
    try {
      final groupsData = await client.from('groups').select('*, people(*, attendance(*))').eq('section', section);
      for (var g in groupsData) {
        final group = AttendanceGroup(
            id: g['id'],
            name: g['name'],
            section: g['section'] ?? 'alimentacion',
            password: g['password']
        );
        for (var p in g['people']) {
          final person = Person(
            id: p['id'],
            firstName: p['first_name'],
            lastName: p['last_name'],
            birthday: p['birthday'] != null ? DateTime.parse(p['birthday']) : null,
          );
          for (var att in p['attendance']) {
            person.attendance[att['date']] = AttendanceStatus.values.byName(att['status']);
          }
          group.people.add(person);
        }
        groups.add(group);
      }

      groups.sort((a, b) => _naturalCompare(a.name, b.name));

    } catch (e) {
      debugPrint("Error en SupabaseService.fetchGroupsBySection: $e");
      rethrow;
    }
    return groups;
  }

  static int _naturalCompare(String a, String b) {
    final alphanumeric = RegExp(r'(\d+)|(\D+)');
    final aMatches = alphanumeric.allMatches(a.toLowerCase()).map((m) => m.group(0)!).toList();
    final bMatches = alphanumeric.allMatches(b.toLowerCase()).map((m) => m.group(0)!).toList();

    for (var i = 0; i < aMatches.length && i < bMatches.length; i++) {
      final aPart = aMatches[i];
      final bPart = bMatches[i];

      if (aPart != bPart) {
        final aNum = int.tryParse(aPart);
        final bNum = int.tryParse(bPart);

        if (aNum != null && bNum != null) {
          return aNum.compareTo(bNum);
        }
        return aPart.compareTo(bPart);
      }
    }
    return aMatches.length.compareTo(bMatches.length);
  }

  static Future<void> saveAttendance(String personId, DateTime date, AttendanceStatus status) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      if (status == AttendanceStatus.none) {
        await client.from('attendance').delete().match({'person_id': personId, 'date': dateStr});
      } else {
        await client.from('attendance').upsert({'person_id': personId, 'date': dateStr, 'status': status.name});
      }
    } catch (e) {
      debugPrint("Error en SupabaseService.saveAttendance: $e");
      rethrow;
    }
  }

  static Future<void> saveDailyComment(String section, DateTime date, String comment) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      if (comment.isEmpty) {
        await client.from('daily_comments').delete().match({'section': section, 'date': dateStr});
      } else {
        await client.from('daily_comments').upsert({'section': section, 'date': dateStr, 'comment': comment});
      }
    } catch (e) {
      debugPrint("Error en SupabaseService.saveDailyComment: $e");
      rethrow;
    }
  }

  static Future<Map<String, String>> fetchDailyComments(String section) async {
    try {
      final data = await client.from('daily_comments').select('date, comment').eq('section', section);
      final Map<String, String> comments = {};
      for (var item in data) {
        comments[item['date']] = item['comment'];
      }
      return comments;
    } catch (e) {
      debugPrint("Error en SupabaseService.fetchDailyComments: $e");
      return {};
    }
  }

  static Future<bool> verifySectionPassword(String section, String password) async {
    if (section == 'alimentacion') return password == "Alimentos2026";
    if (section == 'lavado') return password == "Lavado2026";
    return false;
  }
}

class StorageService {
  static Future<void> saveLocalJson(List<AttendanceGroup> groups) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/attendance_backup.json');
      await file.writeAsString(jsonEncode(groups.map((g) => g.toJson()).toList()));
    } catch (e) {
      debugPrint("Error en StorageService.saveLocalJson: $e");
    }
  }

  static Future<void> exportExcel(AttendanceGroup group, List<DateTime> days, [List<AttendanceGroup>? allGroups]) async {
    try {
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.getRangeByIndex(1, 1).setText("Persona");

      bool isAlim = group.section == 'alimentacion' && allGroups != null;
      int colOffset = 2;

      for (int i = 0; i < days.length; i++) {
        String dateStr = DateFormat('dd/MM/yy').format(days[i]);
        if (isAlim) {
          sheet.getRangeByIndex(1, colOffset).setText("$dateStr (D)");
          sheet.getRangeByIndex(1, colOffset + 1).setText("$dateStr (A)");
          sheet.getRangeByIndex(1, colOffset + 2).setText("$dateStr (C)");
          colOffset += 3;
        } else {
          sheet.getRangeByIndex(1, colOffset).setText(dateStr);
          colOffset++;
        }
      }

      group.people.sort((a, b) => a.firstName.compareTo(b.firstName));

      AttendanceGroup? dGroup = isAlim ? allGroups.firstWhereOrNull((g) => g.name.toLowerCase().contains('desayuno')) : null;
      AttendanceGroup? aGroup = isAlim ? allGroups.firstWhereOrNull((g) => g.name.toLowerCase().contains('almuerzo')) : null;
      AttendanceGroup? cGroup = isAlim ? allGroups.firstWhereOrNull((g) => g.name.toLowerCase().contains('cena')) : null;

      for (int i = 0; i < group.people.length; i++) {
        final p = group.people[i];
        sheet.getRangeByIndex(i + 2, 1).setText("${p.firstName} ${p.lastName}");
        colOffset = 2;
        for (int j = 0; j < days.length; j++) {
          final key = DateFormat('yyyy-MM-dd').format(days[j]);
          if (isAlim) {
            Person? pInD = dGroup?.people.firstWhereOrNull((x) => x.firstName == p.firstName && x.lastName == p.lastName);
            Person? pInA = aGroup?.people.firstWhereOrNull((x) => x.firstName == p.firstName && x.lastName == p.lastName);
            Person? pInC = cGroup?.people.firstWhereOrNull((x) => x.firstName == p.firstName && x.lastName == p.lastName);

            AttendanceStatus statusD = pInD?.attendance[key] ?? AttendanceStatus.none;
            AttendanceStatus statusA = pInA?.attendance[key] ?? AttendanceStatus.none;
            AttendanceStatus statusC = pInC?.attendance[key] ?? AttendanceStatus.none;

            sheet.getRangeByIndex(i + 2, colOffset).setText(statusD == AttendanceStatus.none ? "-" : statusD.name[0].toUpperCase());
            sheet.getRangeByIndex(i + 2, colOffset + 1).setText(statusA == AttendanceStatus.none ? "-" : statusA.name[0].toUpperCase());
            sheet.getRangeByIndex(i + 2, colOffset + 2).setText(statusC == AttendanceStatus.none ? "-" : statusC.name[0].toUpperCase());
            colOffset += 3;
          } else {
            final status = p.attendance[key] ?? AttendanceStatus.none;
            sheet.getRangeByIndex(i + 2, colOffset).setText(status == AttendanceStatus.none ? "-" : status.name[0].toUpperCase());
            colOffset++;
          }
        }
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      if (kIsWeb) {
        final content = base64Encode(bytes);
        html.AnchorElement(href: "data:application/octet-stream;charset=utf-16le;base64,$content")
          ..setAttribute("download", "${group.name}_Reporte.xlsx")
          ..click();
      } else if (!kIsWeb && Platform.isWindows) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar Reporte',
          fileName: '${group.name}_Reporte.xlsx',
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );
        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
        }
      } else {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/${group.name}_Reporte.xlsx';
        final file = File(path);
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(path)], text: 'Reporte de Asistencia');
      }
    } catch (e) {
      debugPrint("Error en StorageService.exportExcel: $e");
    }
  }
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AsistenciXS SEBIPCA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), useMaterial3: true),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
      ],
      home: const VersionCheckWrapper(),
    );
  }
}

class VersionCheckWrapper extends StatefulWidget {
  const VersionCheckWrapper({super.key});

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  bool isLoading = true;
  bool needsUpdate = false;
  String remoteVersion = "";

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  bool isNewerVersion(String local, String remote) {
    List<int> localParts =
    local.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    List<int> remoteParts =
    remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    int maxLength =
    localParts.length > remoteParts.length
        ? localParts.length
        : remoteParts.length;

    while (localParts.length < maxLength) {
      localParts.add(0);
    }

    while (remoteParts.length < maxLength) {
      remoteParts.add(0);
    }

    for (int i = 0; i < maxLength; i++) {
      if (remoteParts[i] > localParts[i]) {
        return true;
      } else if (remoteParts[i] < localParts[i]) {
        return false;
      }
    }

    return false;
  }

  Future<void> _checkVersion() async {
    try {
      final url1 = 'https://raw.githubusercontent.com/Danel20/Proyectos_SEBIPCA/main/AsistenciXS_SEBIPCA_version.json';
      final response = await http.get(Uri.parse(url1));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        remoteVersion = data['version'] ?? asistencixs_sebipca_version;
        if (isNewerVersion(asistencixs_sebipca_version, remoteVersion)) {
          setState(() {
            needsUpdate = true;
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error comprobando versión: $e");
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (needsUpdate) {
      return UpdateScreen(remoteVersion: remoteVersion);
    }
    return const LandingPage();
  }
}

class UpdateScreen extends StatelessWidget {
  final String remoteVersion;
  const UpdateScreen({super.key, required this.remoteVersion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.red.shade900, Colors.red.shade600], begin: Alignment.topCenter)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.update, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text("Nueva Versión Disponible", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            Text("Versión actual: $asistencixs_sebipca_version | Nueva: $remoteVersion", style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse('https://github.com/Danel20/Proyectos_SEBIPCA')),
              icon: const Icon(Icons.download),
              label: const Text("Descargar Actualización"),
              style: ElevatedButton.styleFrom(fixedSize: const Size(280, 60)),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text("Por favor, descarga la última versión para continuar usando AsistenciXS SEBIPCA correctamente.",
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;

  const PasswordInputField({super.key, required this.controller, required this.hintText});

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        hintText: widget.hintText,
        suffixIcon: GestureDetector(
          onTapDown: (_) => setState(() => _obscureText = false),
          onTapUp: (_) => setState(() => _obscureText = true),
          onTapCancel: () => setState(() => _obscureText = true),
          child: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
        ),
      ),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  Future<void> _promptSectionPassword(BuildContext context, AppSection section) async {
    final controller = TextEditingController();
    final String sectionId = section == AppSection.alimentacion ? "alimentacion" : "lavado";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Contraseña ${section == AppSection.alimentacion ? 'Alimentación' : 'Lavado'}"),
        content: PasswordInputField(controller: controller, hintText: "Ingrese la contraseña"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              bool isValid = await SupabaseService.verifySectionPassword(sectionId, controller.text);
              if (isValid) {
                if (context.mounted) {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GroupsScreen(section: section)));
                }
              } else {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contraseña incorrecta"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Entrar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade900, Colors.teal.shade600], begin: Alignment.topCenter)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text("AsistenciXS SEBIPCA", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 60),
            _buildSectionButton(context, "ALIMENTOS", Icons.restaurant, () => _promptSectionPassword(context, AppSection.alimentacion)),
            const SizedBox(height: 20),
            _buildSectionButton(context, "LAVADO", Icons.local_laundry_service, () => _promptSectionPassword(context, AppSection.lavado)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(260, 60),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class GroupsScreen extends StatefulWidget {
  final AppSection section;
  const GroupsScreen({super.key, required this.section});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<AttendanceGroup> groups = [];
  bool isLoading = true;
  RealtimeChannel? groupsChannel;

  Timer? _refreshDebounce;

  @override
  void initState() {
    super.initState();
    _refresh();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    groupsChannel?.unsubscribe();

    groupsChannel =
        SupabaseService.client.channel(
          'groups-${widget.section.name}',
        );

    groupsChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'groups',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'section',
        value: widget.section == AppSection.alimentacion
            ? 'alimentacion'
            : 'lavado',
      ),
      callback: (_) => _safeRefresh(_refresh),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'people',
      callback: (_) => _safeRefresh(_refresh),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'attendance',
      callback: (_) => _safeRefresh(_refresh),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'daily_comments',
      callback: (_) => _safeRefresh(_refresh),
    )
        .subscribe();
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    groupsChannel?.unsubscribe();
    super.dispose();
  }

  void _safeRefresh(Future<void> Function() fn) {
    _refreshDebounce?.cancel();

    _refreshDebounce = Timer(
      const Duration(milliseconds: 250),
          () => fn(),
    );
  }

  Future<void> _refresh() async {
    setState(() => isLoading = true);
    try {
      final sectionName = widget.section == AppSection.alimentacion ? "alimentacion" : "lavado";
      final data = await SupabaseService.fetchGroupsBySection(sectionName);
      setState(() {
        groups = data;
        isLoading = false;
      });
      await StorageService.saveLocalJson(groups);
      _checkBirthdays();
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _checkBirthdays() {
    final now = DateTime.now();
    final Map<String, Person> uniquePeople = {};

    for (var group in groups) {
      for (var person in group.people) {
        if (person.birthday != null) {
          final bday = person.birthday!;
          final today = DateTime(now.year, now.month, now.day);

          final nextBdayThisYear = DateTime(now.year, bday.month, bday.day);
          final nextBdayNextYear = DateTime(now.year + 1, bday.month, bday.day);

          int diff = nextBdayThisYear.difference(today).inDays;

          if (diff < 0) {
            diff = nextBdayNextYear.difference(today).inDays;
          }

          if (diff >= 0 && diff <= 7) {
            // 🔑 clave única (puedes usar ID si es global)
            final key = "${person.firstName}-${person.lastName}-${person.birthday}";

            uniquePeople[key] = person;
          }
        }
      }
    }

    final bdayPeople = uniquePeople.values.toList();

    if (bdayPeople.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("🎂 Cumpleaños Próximos"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: bdayPeople.length,
              itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.cake, color: Colors.pink),
                title: Text("${bdayPeople[i].firstName} ${bdayPeople[i].lastName}"),
                subtitle: Text(DateFormat('dd de MMMM').format(bdayPeople[i].birthday!)),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar"))
          ],
        ),
      );
    }
  }

  Future<void> _onGroupTap(AttendanceGroup group) async {
    if (widget.section == AppSection.lavado && group.password != null && group.password!.isNotEmpty) {
      final passController = TextEditingController();
      bool? authorized = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Contraseña: ${group.name}"),
          content: PasswordInputField(controller: passController, hintText: "Password del grupo"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, passController.text == group.password), child: const Text("Entrar"))
          ],
        ),
      );
      if (authorized != true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Acceso Denegado")));
        return;
      }
    }
    if (mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceTableScreen(group: group, allGroups: groups)));
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Asistencia - ${widget.section == AppSection.alimentacion ? 'Alimentación' : 'Lavado'}"),
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)]
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, i) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.group)),
          title: Text(groups[i].name),
          subtitle: Text("${groups[i].people.length} integrantes"),
          onTap: () => _onGroupTap(groups[i]),
        ),
      ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // BOTÓN NUEVO (SOLO ALIMENTACIÓN)
            if (widget.section == AppSection.alimentacion)
              FloatingActionButton(
                heroTag: "summaryBtn",
                backgroundColor: Colors.orange,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeeklySummaryScreen(allGroups: groups),
                    ),
                  );
                },
                child: const Icon(Icons.bar_chart),
              ),

            const SizedBox(height: 10),

            // BOTÓN ORIGINAL
            FloatingActionButton(
              heroTag: "addBtn",
              onPressed: () async {
                final nameC = TextEditingController();
                final passC = TextEditingController();

                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Nueva Lista"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(controller: nameC, decoration: const InputDecoration(hintText: "Nombre")),
                        if (widget.section == AppSection.lavado)
                          PasswordInputField(controller: passC, hintText: "Contraseña del grupo (opcional)"),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameC.text.isNotEmpty) {
                            await SupabaseService.client.from('groups').insert({
                              'name': nameC.text,
                              'section': widget.section == AppSection.alimentacion ? 'alimentacion' : 'lavado',
                              'password': widget.section == AppSection.lavado ? passC.text : null,
                            });
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              _refresh();
                            }
                          }
                        },
                        child: const Text("Crear"),
                      )
                    ],
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
    );
  }
}

class WeeklySummaryScreen extends StatefulWidget {
  final List<AttendanceGroup> allGroups;

  const WeeklySummaryScreen({super.key, required this.allGroups});

  @override
  State<WeeklySummaryScreen> createState() =>
      _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState
    extends State<WeeklySummaryScreen> {

  Map<String, String> comments = {};

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final data =
    await SupabaseService.fetchDailyComments('alimentacion');

    if (mounted) {
      setState(() {
        comments = data;
      });
    }
  }

  List<DateTime> _getWeekDates(DateTime base) {
    final start =
    base.subtract(Duration(days: base.weekday - 1));

    return List.generate(
      7,
          (i) => start.add(Duration(days: i)),
    );
  }

  Map<String, List<String>> _getAbsences(
      List<DateTime> dates,
      ) {
    Map<String, List<String>> result = {};

    for (var group in widget.allGroups) {

      String mealType = "";

      final lower = group.name.toLowerCase();

      if (lower.contains("desayuno")) {
        mealType = "Desayuno";
      } else if (lower.contains("almuerzo")) {
        mealType = "Almuerzo";
      } else if (lower.contains("cena")) {
        mealType = "Cena";
      } else {
        mealType = group.name;
      }

      for (var person in group.people) {
        for (var date in dates) {

          final key =
          DateFormat('yyyy-MM-dd').format(date);

          final status = person.attendance[key];

          if (status == AttendanceStatus.absent) {

            final name =
                "${person.firstName} ${person.lastName}";

            final formattedDate =
            DateFormat('dd/MM').format(date);

            result.putIfAbsent(name, () => []);

            result[name]!
                .add("$formattedDate ($mealType)");
          }
        }
      }
    }

    return result;
  }

  List<Widget> _buildCommentsSection(
      String title,
      List<DateTime> dates,
      ) {

    List<Widget> items = [];

    for (var date in dates) {

      final key =
      DateFormat('yyyy-MM-dd').format(date);

      final comment = comments[key];

      if (comment != null && comment.trim().isNotEmpty) {

        items.add(
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.sticky_note_2,
                color: Colors.teal,
              ),
              title: Text(
                DateFormat('EEEE dd/MM', 'es')
                    .format(date),
              ),
              subtitle: Text(comment),
            ),
          ),
        );
      }
    }

    if (items.isEmpty) {
      items.add(
        const Text("Sin comentarios"),
      );
    }

    return [
      const SizedBox(height: 20),

      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 10),

      ...items,
    ];
  }

  List<Widget> _buildList(
      Map<String, List<String>> data,
      ) {

    if (data.isEmpty) {
      return [const Text("Sin faltas 🎉")];
    }

    return data.entries.map((e) {

      return Card(
        child: ListTile(
          leading: const Icon(
            Icons.cancel,
            color: Colors.red,
          ),
          title: Text(e.key),
          subtitle: Text(
            "Fechas: ${e.value.join(", ")}",
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    final now = DateTime.now();

    final currentWeek = _getWeekDates(now);

    final lastWeek = _getWeekDates(
      now.subtract(const Duration(days: 7)),
    );

    final currentAbsences =
    _getAbsences(currentWeek);

    final lastAbsences =
    _getAbsences(lastWeek);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resumen Semanal"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),

        children: [

          const Text(
            "Semana Actual",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          ..._buildList(currentAbsences),

          ..._buildCommentsSection(
            "Comentarios Semana Actual",
            currentWeek,
          ),

          const SizedBox(height: 20),

          const Text(
            "Semana Anterior",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          ..._buildList(lastAbsences),

          ..._buildCommentsSection(
            "Comentarios Semana Anterior",
            lastWeek,
          ),
        ],
      ),
    );
  }
}

class AttendanceTableScreen extends StatefulWidget {
  final AttendanceGroup group;
  final List<AttendanceGroup> allGroups;
  const AttendanceTableScreen({super.key, required this.group, required this.allGroups});
  @override
  State<AttendanceTableScreen> createState() => _AttendanceTableScreenState();
}

class _AttendanceTableScreenState extends State<AttendanceTableScreen> {
  late DateTime startDate;
  late DateTime endDate;
  bool isEditMode = false;
  bool isImporting = false;
  late List<Person> currentPeople;
  Map<String, String> _dailyComments = {};

  RealtimeChannel? attendanceChannel;

  late LinkedScrollControllerGroup _verticalScrollControllers;
  late ScrollController _nameVerticalController;
  late ScrollController _attendanceVerticalController;

  late LinkedScrollControllerGroup _horizontalScrollControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _attendanceHorizontalController;

  Timer? _refreshDebounce;

  void _safeRefresh(Future<void> Function() fn) {
    _refreshDebounce?.cancel();

    _refreshDebounce = Timer(
      const Duration(milliseconds: 250),
          () => fn(),
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day);
    endDate = DateTime(now.year, now.month, now.day);
    _sortAndAssign(widget.group.people);

    _verticalScrollControllers = LinkedScrollControllerGroup();
    _nameVerticalController = _verticalScrollControllers.addAndGet();
    _attendanceVerticalController = _verticalScrollControllers.addAndGet();

    _horizontalScrollControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _horizontalScrollControllers.addAndGet();
    _attendanceHorizontalController = _horizontalScrollControllers.addAndGet();

    _loadComments();
    _subscribeAttendanceRealtime();
  }

  void _subscribeAttendanceRealtime() {
    attendanceChannel?.unsubscribe();

    attendanceChannel =
        SupabaseService.client.channel(
          'attendance-${widget.group.id}',
        );

    attendanceChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'attendance',
      callback: (_) => _safeRefresh(_refreshPeople),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'daily_comments',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'section',
        value: widget.group.section,
      ),
      callback: (_) => _safeRefresh(_loadComments),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'people',

      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'group_id',
        value: widget.group.id,
      ),
      callback: (_) => _safeRefresh(_refreshPeople),
    )
        .subscribe();
  }

  Future<void> _loadComments() async {
    final comments = await SupabaseService.fetchDailyComments(widget.group.section);
    if (mounted) {
      setState(() {
        _dailyComments = comments;
      });
    }
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    attendanceChannel?.unsubscribe();

    _nameVerticalController.dispose();
    _attendanceVerticalController.dispose();
    _headerHorizontalController.dispose();
    _attendanceHorizontalController.dispose();
    super.dispose();
  }

  void _sortAndAssign(List<Person> list) {
    list.sort((a, b) => a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()));
    currentPeople = list;
  }

  List<DateTime> get daysInRange {
    List<DateTime> days = [];
    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      days.add(startDate.add(Duration(days: i)));
    }
    return days;
  }

  Future<void> _refreshPeople() async {
    try {
      final data = await SupabaseService.client.from('people').select('*, attendance(*)').eq('group_id', widget.group.id);
      List<Person> updated = [];
      for (var p in data) {
        final person = Person(id: p['id'], firstName: p['first_name'], lastName: p['last_name'], birthday: p['birthday'] != null ? DateTime.parse(p['birthday']) : null);
        for (var att in p['attendance']) { person.attendance[att['date']] = AttendanceStatus.values.byName(att['status']); }
        updated.add(person);
      }
      setState(() => _sortAndAssign(updated));
      await _loadComments();
    } catch (e) { debugPrint("Error: $e"); }
  }

  Future<void> _importCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null) {
        setState(() => isImporting = true);
        String csvString;
        final List<int>? bytes = result.files.single.bytes;

        if (kIsWeb) {
          if (bytes == null) throw "No se pudieron leer los datos";
          try { csvString = utf8.decode(bytes); } catch (_) { csvString = latin1.decode(bytes); }
        } else {
          if (bytes != null) {
            try { csvString = utf8.decode(bytes); } catch (_) { csvString = latin1.decode(bytes); }
          } else {
            final file = File(result.files.single.path!);
            final fileBytes = await file.readAsBytes();
            try { csvString = utf8.decode(fileBytes); } catch (_) { csvString = latin1.decode(fileBytes); }
          }
        }

        String delimiter = csvString.contains(';') ? ';' : ',';
        List<List<dynamic>> fields = const CsvToListConverter().convert(csvString, fieldDelimiter: delimiter);

        int count = 0;
        for (var row in fields) {
          if (row.isNotEmpty && row[0].toString().trim().isNotEmpty) {
            if (row[0].toString().toLowerCase().contains("nombre")) continue;
            String fullName = row[0].toString().trim();
            String? rawBirthday = row.length > 1 ? row[1].toString().trim() : null;
            List<String> parts = fullName.split(" ");
            String firstName = parts[0];
            String lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";
            String? formattedBirthday;
            if (rawBirthday != null && rawBirthday.isNotEmpty) {
              try {
                if (rawBirthday.contains("/")) {
                  List<String> dParts = rawBirthday.split("/");
                  if (dParts.length == 3) {
                    String year = dParts[2].length == 2 ? "19${dParts[2]}" : dParts[2];
                    formattedBirthday = "$year-${dParts[1].padLeft(2, '0')}-${dParts[0].padLeft(2, '0')}";
                  }
                } else if (rawBirthday.contains("-")) {
                  formattedBirthday = rawBirthday;
                }
              } catch (_) {}
            }
            await SupabaseService.client.from('people').insert({
              'group_id': widget.group.id,
              'first_name': firstName,
              'last_name': lastName,
              'birthday': formattedBirthday
            });
            count++;
          }
        }
        await _refreshPeople();
        setState(() => isImporting = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Se agregaron $count personas correctamente"), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => isImporting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al importar: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _editPerson(Person p) async {
    final fn = TextEditingController(text: p.firstName);
    final ln = TextEditingController(text: p.lastName);
    final bd = TextEditingController(text: p.birthday != null ? DateFormat('yyyy-MM-dd').format(p.birthday!) : "");
    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text("Editar Persona"),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: fn, decoration: const InputDecoration(labelText: "Nombre")),
              TextField(controller: ln, decoration: const InputDecoration(labelText: "Apellido")),
              TextField(controller: bd, decoration: const InputDecoration(labelText: "Cumpleaños (YYYY-MM-DD)"))
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
              ElevatedButton(
                  onPressed: () async {
                    try {
                      await SupabaseService.client.from('people').update({'first_name': fn.text, 'last_name': ln.text, 'birthday': bd.text.isEmpty ? null : bd.text}).eq('id', p.id);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _refreshPeople();
                      }
                    } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Error: $e"))); }
                  },
                  child: const Text("Guardar"))
            ]));
  }

  Future<void> _showCommentDialog(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final controller = TextEditingController(text: _dailyComments[dateKey] ?? "");
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Comentario - ${DateFormat('dd/MM/yyyy').format(date)}"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Escriba un comentario para esta sección..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.saveDailyComment(widget.group.section, date, controller.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _loadComments();
              }
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = daysInRange;
    const double indexWidth = 40.0;
    const double personWidth = 180.0;
    const double rowHeight = 52.0;
    final bool isAlim = widget.group.section == 'alimentacion';
    final double dayWidth = isAlim ? 130.0 : 60.0;
    final double leftPinnedWidth = indexWidth + personWidth + 24;

    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name), actions: [
        if (isEditMode) IconButton(icon: const Icon(Icons.upload_file), onPressed: isImporting ? null : _importCsv),
        IconButton(icon: Icon(isEditMode ? Icons.edit : Icons.visibility, color: isEditMode ? Colors.orange : null), onPressed: () => setState(() => isEditMode = !isEditMode)),
        IconButton(icon: const Icon(Icons.file_download), onPressed: () => StorageService.exportExcel(widget.group, days, widget.allGroups)),
      ]),
      body: isImporting ? const Center(child: CircularProgressIndicator()) : Column(children: [
        _buildDateSelectors(),
        // Table Header
        Row(
          children: [
            // Top Left Corner (Sticky)
            Container(
              width: leftPinnedWidth,
              height: 60,
              padding: const EdgeInsets.only(left: 12),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300), right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: const Row(children: [
                SizedBox(width: indexWidth, child: Text("No.", style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: personWidth, child: Text("Persona", style: TextStyle(fontWeight: FontWeight.bold))),
              ]),
            ),
            // Sticky Header (Horizontal Scroll Sync)
            Expanded(
              child: SingleChildScrollView(
                controller: _headerHorizontalController,
                scrollDirection: Axis.horizontal,
                child: Row(children: days.map((d) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(d);
                  final hasComment = _dailyComments.containsKey(dateKey) && _dailyComments[dateKey]!.isNotEmpty;
                  return Container(
                    width: dayWidth + 12,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.teal.shade50, border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                    child: Stack(
                      children: [
                        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(DateFormat('E', 'es').format(d), style: const TextStyle(fontSize: 10)),
                          Text(DateFormat('dd/MM').format(d), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: Icon(
                              hasComment ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
                              size: 16,
                              color: hasComment ? Colors.teal : Colors.grey,
                            ),
                            onPressed: () => _showCommentDialog(d),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        )
                      ],
                    ),
                  );
                }).toList()),
              ),
            ),
          ],
        ),
        // Table Body
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky Column (Vertical Scroll Sync)
              SizedBox(
                width: leftPinnedWidth,
                child: ListView.builder(
                  controller: _nameVerticalController,
                  itemCount: currentPeople.length,
                  itemExtent: rowHeight,
                  itemBuilder: (context, index) {
                    final p = currentPeople[index];
                    return Container(
                      padding: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200), right: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Row(children: [
                        SizedBox(width: indexWidth, child: Text("${index + 1}.")),
                        SizedBox(width: personWidth, child: Row(children: [
                          Expanded(child: Text("${p.firstName} ${p.lastName}", overflow: TextOverflow.ellipsis)),
                          if (isEditMode) IconButton(icon: const Icon(Icons.edit, size: 14, color: Colors.blue), onPressed: () => _editPerson(p), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        ])),
                      ]),
                    );
                  },
                ),
              ),
              // Attendance Grid (Both Sync)
              Expanded(
                child: Scrollbar(
                  controller: _attendanceHorizontalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _attendanceHorizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: days.length * (dayWidth + 12),
                      child: Scrollbar(
                        controller: _attendanceVerticalController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: ListView.builder(
                          controller: _attendanceVerticalController,
                          itemCount: currentPeople.length,
                          itemExtent: rowHeight,
                          itemBuilder: (context, rowIndex) {
                            final p = currentPeople[rowIndex];
                            return Container(
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                              child: Row(children: days.map((d) => Container(
                                width: dayWidth + 12,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Colors.teal.shade100), // línea vertical
                                  ),
                                ),
                                child: _buildCell(p, d),
                              )).toList()),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
      floatingActionButton: isEditMode ? FloatingActionButton(
        mini: true,
        onPressed: () async {
          final fn = TextEditingController();
          final ln = TextEditingController();
          final bd = TextEditingController();
          await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                  title: const Text("Nueva Persona"),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(controller: fn, decoration: const InputDecoration(labelText: "Nombre")),
                    TextField(controller: ln, decoration: const InputDecoration(labelText: "Apellido")),
                    TextField(controller: bd, decoration: const InputDecoration(labelText: "Cumpleaños (YYYY-MM-DD)"))
                  ]),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                    ElevatedButton(onPressed: () async {
                      if (fn.text.isNotEmpty) {
                        try {
                          await SupabaseService.client.from('people').insert({'group_id': widget.group.id, 'first_name': fn.text, 'last_name': ln.text, 'birthday': bd.text.isEmpty ? null : bd.text});
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _refreshPeople();
                          }
                        } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Error: $e"))); }
                      }
                    }, child: const Text("Agregar"))
                  ]));
        },
        child: const Icon(Icons.person_add),
      ) : null,
    );
  }

  Widget _buildCell(Person person, DateTime date) {
    if (widget.group.section == 'alimentacion') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCircle(person, date, 'D'),
          const SizedBox(width: 4),
          _buildCircle(person, date, 'A'),
          const SizedBox(width: 4),
          _buildCircle(person, date, 'C'),
        ],
      );
    } else {
      return _buildCircle(person, date, null);
    }
  }

  Widget _buildCircle(Person person, DateTime date, String? type) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    AttendanceStatus status = AttendanceStatus.none;
    bool isEditable = isEditMode;
    Person activePerson = person;

    if (type == null) {
      status = person.attendance[dateKey] ?? AttendanceStatus.none;
    } else {
      String currentGroupName = widget.group.name.toLowerCase();
      bool isDesayunoGroup = currentGroupName.contains('desayuno');
      bool isAlmuerzoGroup = currentGroupName.contains('almuerzo');
      bool isCenaGroup = currentGroupName.contains('cena');

      if (type == 'D') {
        if (isDesayunoGroup) {
          status = person.attendance[dateKey] ?? AttendanceStatus.none;
        } else {
          final dGroup = widget.allGroups.firstWhereOrNull((g) => g.name.toLowerCase().contains('desayuno'));
          final pInD = dGroup?.people.firstWhereOrNull((p) =>
          p.firstName.trim().toLowerCase() == person.firstName.trim().toLowerCase() &&
              p.lastName.trim().toLowerCase() == person.lastName.trim().toLowerCase()
          );
          status = pInD?.attendance[dateKey] ?? AttendanceStatus.none;
          isEditable = false;
        }
      } else if (type == 'A') {
        if (isAlmuerzoGroup) {
          status = person.attendance[dateKey] ?? AttendanceStatus.none;
        } else {
          final aGroup = widget.allGroups.firstWhereOrNull((g) => g.name.toLowerCase().contains('almuerzo'));
          final pInA = aGroup?.people.firstWhereOrNull((p) =>
          p.firstName.trim().toLowerCase() == person.firstName.trim().toLowerCase() &&
              p.lastName.trim().toLowerCase() == person.lastName.trim().toLowerCase()
          );
          status = pInA?.attendance[dateKey] ?? AttendanceStatus.none;
          isEditable = false;
        }
      } else if (type == 'C') {
        if (isCenaGroup) {
          status = person.attendance[dateKey] ?? AttendanceStatus.none;
        } else {
          final cGroup = widget.allGroups.firstWhereOrNull((g) => g.name.toLowerCase().contains('cena'));
          final pInC = cGroup?.people.firstWhereOrNull((p) =>
          p.firstName.trim().toLowerCase() == person.firstName.trim().toLowerCase() &&
              p.lastName.trim().toLowerCase() == person.lastName.trim().toLowerCase()
          );
          status = pInC?.attendance[dateKey] ?? AttendanceStatus.none;
          isEditable = false;
        }
      }
    }

    IconData icon = Icons.circle_outlined;
    Color color = Colors.grey.shade100;
    Color iconColor = Colors.grey.shade400;
    if (status == AttendanceStatus.present) { icon = Icons.check_circle; color = Colors.green.shade100; iconColor = Colors.green; }
    else if (status == AttendanceStatus.absent) { icon = Icons.cancel; color = Colors.red.shade100; iconColor = Colors.red; }
    else if (status == AttendanceStatus.reported) { icon = Icons.info; color = Colors.yellow.shade100; iconColor = Colors.orange; }

    return InkWell(
        onTap: isEditable ? () => _cycleStatus(activePerson, date) : null,
        child: Container(
            width: type == null ? 45 : 35,
            height: type == null ? 45 : 35,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: iconColor, size: type == null ? 24 : 18),
                if (type != null) Positioned(top: 0, right: 0, child: Text(type, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black54))),
              ],
            )
        )
    );
  }

  void _cycleStatus(Person person, DateTime date) async {
    if (!isEditMode) return;

    final key = DateFormat('yyyy-MM-dd').format(date);
    final old = person.attendance[key] ?? AttendanceStatus.none;

    if (DateFormat('yyyy-MM-dd').format(date) != DateFormat('yyyy-MM-dd').format(DateTime.now())) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solo puedes editar el día de hoy"), duration: Duration(seconds: 1)));
      return;
    }

    setState(() {
      if (old == AttendanceStatus.none) {
        person.attendance[key] = AttendanceStatus.present;
      } else if (old == AttendanceStatus.present) {
        person.attendance[key] = AttendanceStatus.absent;
      } else if (old == AttendanceStatus.absent) {
        person.attendance[key] = AttendanceStatus.reported;
      } else {
        person.attendance[key] = AttendanceStatus.none;
      }
    });
    try {
      await SupabaseService.saveAttendance(
        person.id,
        date,
        person.attendance[key]!,
      );
    } catch (_) {
      setState(() {
        person.attendance[key] = old;
      });
    }
  }

  Widget _buildDateSelectors() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.teal.withValues(alpha: 0.05),
      child: Row(children: [
        Expanded(child: OutlinedButton(onPressed: () async {
          final d = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2023), lastDate: DateTime(2030));
          if (d != null) setState(() => startDate = d);
        }, child: Text("Desde: ${DateFormat('dd/MM').format(startDate)}"))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(onPressed: () async {
          final d = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2023), lastDate: DateTime(2030));
          if (d != null) setState(() => endDate = d);
        }, child: Text("Hasta: ${DateFormat('dd/MM').format(endDate)}"))),
      ]),
    );
  }
}
