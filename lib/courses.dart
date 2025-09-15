import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------
// Model Class for Course
// ----------------------------
class Course {
  final String id;
  final String name;
  final String? description;
  final List<String>? technologies;
  final String? duration;
  final String? mode;
  final double? fees;
  final String? demoVideo;

  Course({
    required this.id,
    required this.name,
    this.description,
    this.technologies,
    this.duration,
    this.mode,
    this.fees,
    this.demoVideo,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? '',
      description: json['description'],
      technologies: (json['technologies'] != null)
          ? List<String>.from(json['technologies'])
          : [],
      duration: json['duration'],
      mode: json['mode'],
      fees: (json['fees'] != null)
          ? double.tryParse(json['fees'].toString())
          : null,
      demoVideo: json['demoVideo'],
    );
  }
}

// ----------------------------
// Courses Screen
// ----------------------------
class Courses extends StatefulWidget {
  const Courses({Key? key}) : super(key: key);

  @override
  State<Courses> createState() => _CoursesState();
}

class _CoursesState extends State<Courses> {
  late Future<List<Course>> _coursesFuture;
  static const String apiUrl =
      "https://teched-backend-liqn.onrender.com/api/course";

  String? _userRole;

  @override
  void initState() {
    super.initState();
    _coursesFuture = fetchCourses();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // ✅ Load the saved role from login API
      _userRole = prefs.getString('role') ?? "";
    });
  }

  Future<List<Course>> fetchCourses() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body);
      return list.map((item) => Course.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch courses');
    }
  }

  Future<void> addCourse(Map<String, dynamic> courseData) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(courseData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      setState(() {
        _coursesFuture = fetchCourses();
      });
    } else {
      throw Exception("Failed to add course: ${response.body}");
    }
  }

  void _openAddCourseDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();
    final TextEditingController techCtrl = TextEditingController();
    final TextEditingController durationCtrl = TextEditingController();
    final TextEditingController modeCtrl = TextEditingController();
    final TextEditingController feesCtrl = TextEditingController();
    final TextEditingController videoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Add Course"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Course Name"),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  TextFormField(
                    controller: techCtrl,
                    decoration: const InputDecoration(
                        labelText: "Technologies (comma separated)"),
                  ),
                  TextFormField(
                    controller: durationCtrl,
                    decoration: const InputDecoration(labelText: "Duration"),
                  ),
                  TextFormField(
                    controller: modeCtrl,
                    decoration: const InputDecoration(labelText: "Mode"),
                  ),
                  TextFormField(
                    controller: feesCtrl,
                    decoration: const InputDecoration(labelText: "Fees"),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: videoCtrl,
                    decoration:
                        const InputDecoration(labelText: "Demo Video URL"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              child: const Text("Add"),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newCourse = {
                    "name": nameCtrl.text,
                    "description": descCtrl.text,
                    "technologies": techCtrl.text
                        .split(",")
                        .map((e) => e.trim())
                        .toList(),
                    "duration": durationCtrl.text,
                    "mode": modeCtrl.text,
                    "fees": double.tryParse(feesCtrl.text) ?? 0,
                    "demoVideo": videoCtrl.text,
                  };
                  addCourse(newCourse).then((_) {
                    Navigator.of(ctx).pop();
                  }).catchError((err) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $err")),
                    );
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.yellowAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Courses",
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading courses\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }
          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return const Center(
              child: Text(
                "No courses available.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final course = courses[i];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ExpansionTile(
                  leading: const Icon(Icons.book_rounded,
                      color: Colors.green, size: 32),
                  title: Text(
                    course.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: (course.description != null &&
                          course.description!.trim().isNotEmpty)
                      ? Text(course.description!)
                      : null,
                  children: [
                    if (course.duration != null)
                      ListTile(
                        leading: const Icon(Icons.timer, color: Colors.blue),
                        title: Text("Duration: ${course.duration}"),
                      ),
                    if (course.mode != null)
                      ListTile(
                        leading: const Icon(Icons.computer, color: Colors.purple),
                        title: Text("Mode: ${course.mode}"),
                      ),
                    if (course.fees != null)
                      ListTile(
                        leading: const Icon(Icons.currency_rupee,
                            color: Colors.orange),
                        title: Text("Fees: ₹${course.fees!.toStringAsFixed(0)}"),
                      ),
                    if (course.technologies != null &&
                        course.technologies!.isNotEmpty)
                      ListTile(
                        leading:
                            const Icon(Icons.build_circle, color: Colors.teal),
                        title: Text(
                            "Technologies: ${course.technologies!.join(", ")}"),
                      ),
                    if (course.demoVideo != null &&
                        course.demoVideo!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Demo Video:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 8),
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: Colors.black12,
                                  child: Center(
                                    child: Text(
                                      "Video Player Placeholder\n${course.demoVideo}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: (_userRole != null &&
              (_userRole!.toLowerCase() == "admin" ||
                  _userRole!.toLowerCase() == "head"))
          ? FloatingActionButton(
              onPressed: _openAddCourseDialog,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null, // ✅ Only visible for Admin & Head
    );
  }
}
