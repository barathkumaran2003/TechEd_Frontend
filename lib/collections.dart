import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:open_filex/open_filex.dart';

const String BASE_URL = 'https://teched-backend-liqn.onrender.com/api';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});
  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController trainerController = TextEditingController();
  final TextEditingController comboController = TextEditingController();
  final TextEditingController feesController = TextEditingController();
  final TextEditingController couponController = TextEditingController();
  final TextEditingController paymentDateController = TextEditingController();
  File? selectedImageFile;
  Uint8List? selectedImageBytes;
  List<String> courses = [];
  List<String> trainers = [];
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];
  String reportFilter = 'month';
  DateTime? customStart;
  DateTime? customEnd;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchCourses();
    fetchTrainers();
    fetchStudents();
  }

  Future<void> fetchCourses() async {
    try {
      final res = await http.get(Uri.parse('$BASE_URL/course'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data =
            decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
        setState(() {
          courses =
              data.map<String>((c) => c['name'] ?? c['title'] ?? '').toList();
        });
      }
    } catch (_) {
      setState(() => courses = []);
    }
  }

  Future<void> fetchTrainers() async {
    try {
      final res = await http.get(Uri.parse('$BASE_URL/trainer'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data =
            decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
        setState(() {
          trainers =
              data.map<String>((t) => t['fullName'] ?? t['name'] ?? '').toList();
        });
      }
    } catch (_) {
      setState(() => trainers = []);
    }
  }

  Future<void> fetchStudents() async {
    try {
      final res = await http.get(Uri.parse('$BASE_URL/student'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data =
            decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
        setState(() {
          students =
              data.map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s)).toList();
          filterStudents();
        });
      }
    } catch (_) {
      setState(() {
        students = [];
        filteredStudents = [];
      });
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => selectedImageBytes = bytes);
      } else {
        setState(() => selectedImageFile = File(picked.path));
      }
    }
  }

  Future<String> uploadImage() async {
    if (selectedImageFile == null && selectedImageBytes == null) return '';
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$BASE_URL/upload-profile'));
      if (kIsWeb && selectedImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          selectedImageBytes!,
          filename: 'profile.png',
        ));
      } else if (selectedImageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          selectedImageFile!.path,
        ));
      }
      final res = await request.send();
      if (res.statusCode == 200) {
        return await res.stream.bytesToString();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return '';
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final imageUrl = await uploadImage();

    // Parsing fees
    final fees = int.tryParse(feesController.text.trim()) ?? 0;

    // Ensuring paymentDate in 'YYYY-MM-DD'
    String paymentDate = paymentDateController.text.trim();
    try {
      final parsedDate = DateTime.parse(paymentDate);
      paymentDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (_) {}

    final payload = {
      "name": nameController.text.trim(),
      "course": courseController.text.trim(),
      "combo": comboController.text.trim(),
      "trainer": trainerController.text.trim(),
      "fees": fees,
      "couponOrReferral": couponController.text.trim(),
      "paymentDate": paymentDate,
      "contact": contactController.text.trim(),
      "email": emailController.text.trim(),
      "profilePicUrl": imageUrl,
      "paymentMode": "Cash",
    };
    debugPrint(jsonEncode(payload));
    try {
      final res = await http.post(
        Uri.parse('$BASE_URL/student'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student registered successfully')));
        resetForm();
        fetchStudents();
      } else {
        debugPrint("Failed Response: ${res.statusCode} ${res.body}");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${res.statusCode}\n${res.body}')));
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error while registering student')));
    }
  }

  void resetForm() {
    _formKey.currentState?.reset();
    nameController.clear();
    emailController.clear();
    contactController.clear();
    courseController.clear();
    trainerController.clear();
    comboController.clear();
    feesController.clear();
    couponController.clear();
    paymentDateController.clear();
    setState(() {
      selectedImageFile = null;
      selectedImageBytes = null;
    });
  }

  void filterStudents() {
    DateTime now = DateTime.now();
    List<Map<String, dynamic>> filtered = [];
    switch (reportFilter) {
      case 'week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        filtered = students.where((s) {
          final date = DateTime.tryParse(s['paymentDate'] ?? '');
          return date != null && date.isAfter(start) && date.isBefore(end);
        }).toList();
        break;
      case 'month':
        filtered = students.where((s) {
          final date = DateTime.tryParse(s['paymentDate'] ?? '');
          return date != null &&
              date.month == now.month &&
              date.year == now.year;
        }).toList();
        break;
      case 'year':
        filtered = students.where((s) {
          final date = DateTime.tryParse(s['paymentDate'] ?? '');
          return date != null && date.year == now.year;
        }).toList();
        break;
      case 'custom':
        if (customStart != null && customEnd != null) {
          filtered = students.where((s) {
            final date = DateTime.tryParse(s['paymentDate'] ?? '');
            return date != null &&
                date.isAfter(customStart!) &&
                date.isBefore(customEnd!);
          }).toList();
        }
        break;
      default:
        filtered = students;
    }
    setState(() => filteredStudents = filtered);
  }

  Future<void> exportPdf() async {
    if (filteredStudents.isEmpty) return;
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (_) => pw.Column(
        children: [
          pw.Text('Collections Report', style: pw.TextStyle(fontSize: 20)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'Name',
              'Course',
              'Trainer',
              'Fees',
              'Email',
              'Contact',
              'Payment Date'
            ],
            data: filteredStudents.map((s) {
              return [
                s['name'] ?? '',
                s['course'] ?? '',
                s['trainer'] ?? '',
                s['fees']?.toString() ?? '',
                s['email'] ?? '',
                s['contact'] ?? '',
                s['paymentDate'] ?? ''
              ];
            }).toList(),
          ),
        ],
      ),
    ));
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/collections_report.pdf');
    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('PDF exported')));
  }

  Future<void> exportExcel() async {
    if (filteredStudents.isEmpty) return;
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.getRangeByIndex(1, 1).setText('Name');
    sheet.getRangeByIndex(1, 2).setText('Course');
    sheet.getRangeByIndex(1, 3).setText('Trainer');
    sheet.getRangeByIndex(1, 4).setText('Fees');
    sheet.getRangeByIndex(1, 5).setText('Email');
    sheet.getRangeByIndex(1, 6).setText('Contact');
    sheet.getRangeByIndex(1, 7).setText('Payment Date');
    for (var i = 0; i < filteredStudents.length; i++) {
      final s = filteredStudents[i];
      sheet.getRangeByIndex(i + 2, 1).setText(s['name'] ?? '');
      sheet.getRangeByIndex(i + 2, 2).setText(s['course'] ?? '');
      sheet.getRangeByIndex(i + 2, 3).setText(s['trainer'] ?? '');
      sheet.getRangeByIndex(i + 2, 4).setText(s['fees']?.toString() ?? '');
      sheet.getRangeByIndex(i + 2, 5).setText(s['email'] ?? '');
      sheet.getRangeByIndex(i + 2, 6).setText(s['contact'] ?? '');
      sheet.getRangeByIndex(i + 2, 7).setText(s['paymentDate'] ?? '');
    }
    final bytes = workbook.saveAsStream();
    workbook.dispose();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/collections_report.xlsx');
    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Excel exported')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management System'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Registration'),
            Tab(text: 'Collections Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Registration Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: kIsWeb
                          ? (selectedImageBytes != null
                              ? Image.memory(selectedImageBytes!,
                                  fit: BoxFit.cover)
                              : const Center(child: Text('Tap to upload')))
                          : (selectedImageFile != null
                              ? Image.file(selectedImageFile!,
                                  fit: BoxFit.cover)
                              : const Center(child: Text('Tap to upload'))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter name' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: courseController.text.isEmpty
                        ? null
                        : courseController.text,
                    items: courses
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => courseController.text = v ?? ''),
                    decoration: const InputDecoration(labelText: 'Course'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Select course' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: trainerController.text.isEmpty
                        ? null
                        : trainerController.text,
                    items: trainers
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => trainerController.text = v ?? ''),
                    decoration: const InputDecoration(labelText: 'Trainer'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Select trainer' : null,
                  ),
                  TextFormField(
                    controller: feesController,
                    decoration: const InputDecoration(labelText: 'Fees'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter fees' : null,
                  ),
                  TextFormField(
                    controller: couponController,
                    decoration:
                        const InputDecoration(labelText: 'Coupon/Referral'),
                  ),
                  TextFormField(
                    controller: paymentDateController,
                    decoration: const InputDecoration(
                        labelText: 'Payment Date (YYYY-MM-DD)'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter date' : null,
                  ),
                  TextFormField(
                    controller: contactController,
                    decoration: const InputDecoration(labelText: 'Contact'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter contact' : null,
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: submitForm, child: const Text('Register')),
                      ElevatedButton(
                          onPressed: resetForm, child: const Text('Reset')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Collections Report
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButton<String>(
                  value: reportFilter,
                  items: const [
                    DropdownMenuItem(value: 'week', child: Text('Week')),
                    DropdownMenuItem(value: 'month', child: Text('Month')),
                    DropdownMenuItem(value: 'year', child: Text('Year')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  ],
                  onChanged: (v) {
                    setState(() => reportFilter = v!);
                    filterStudents();
                  },
                ),
              ),
              if (reportFilter == 'custom')
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                              context: context,
                              initialDate: customStart ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100));
                          if (date != null) setState(() => customStart = date);
                        },
                        child: Text(
                            'Start: ${customStart != null ? DateFormat('yyyy-MM-dd').format(customStart!) : ''}')),
                    TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                              context: context,
                              initialDate: customEnd ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100));
                          if (date != null) setState(() => customEnd = date);
                        },
                        child: Text(
                            'End: ${customEnd != null ? DateFormat('yyyy-MM-dd').format(customEnd!) : ''}')),
                    IconButton(
                        onPressed: filterStudents,
                        icon: const Icon(Icons.filter_alt)),
                  ],
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, i) {
                    final s = filteredStudents[i];
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text("${s['name'] ?? ''} (${s['course'] ?? ''})"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Trainer: ${s['trainer'] ?? ''}"),
                            Text("Fees: ${s['fees']?.toString() ?? ''}"),
                            Text("Email: ${s['email'] ?? ''}"),
                            Text("Contact: ${s['contact'] ?? ''}"),
                            Text("Date: ${s['paymentDate'] ?? ''}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: exportPdf, child: const Text('Export PDF')),
                  ElevatedButton(
                      onPressed: exportExcel, child: const Text('Export Excel')),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ],
      ),
    );
  }
}
