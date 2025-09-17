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

  final List<List<Color>> cardGradients = [
    [Color(0xFFD2F6C5), Color(0xFF7BD5C1)],
    [Color(0xFFF8E2CF), Color(0xFFE3B04B)],
    [Color(0xFFB4B8F8), Color(0xFFE3A1F7)],
    [Color(0xFFFFBCA7), Color(0xFFE17A7A)],
    [Color(0xFFCCE2FF), Color(0xFFAECFFF)],
    [Color(0xFFFFE597), Color(0xFFE58080)],
    [Color(0xFFFFF3B0), Color(0xFFCAFFD0)],
    [Color(0xFFFDD2FA), Color(0xFFFDEFC2)],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF27AE60), Color(0xFFFCF6BA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Ready to reimagine your career?",
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: const Text(
              "Join Career Accelerators and get the structure, skills, and real-world experience to become an exceptional candidate.",
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Course>>(
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
                return GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: courses.length,
                  itemBuilder: (context, i) {
                    final course = courses[i];
                    final gradientColors =
                        cardGradients[i % cardGradients.length];
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Card(
                        color: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.88),
                                radius: 30,
                                child: Icon(
                                  Icons.book_rounded,
                                  size: 30,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                course.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Colors.black87),
                              ),
                              if (course.description != null &&
                                  course.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 7.0),
                                  child: Text(
                                    course.description!,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontSize: 13),
                                  ),
                                ),
                              const Spacer(),
                              if (course.fees != null && course.fees != 0)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(.06),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    "Fees: ₹${course.fees!.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87),
                                  ),
                                ),
                              if (course.duration != null &&
                                  course.duration!.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(.06),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    "Duration: ${course.duration}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black87),
                                  ),
                                ),
                              // Add more pills here, example: mode, tech, video, etc.
                              if (course.technologies != null &&
                                  course.technologies!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3.0),
                                  child: Text(
                                    "Tech: ${course.technologies!.join(', ')}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: (_userRole != null &&
              (_userRole!.toLowerCase() == "admin" ||
                  _userRole!.toLowerCase() == "head"))
          ? FloatingActionButton(
              onPressed: _openAddCourseDialog,
              backgroundColor: const Color(0xFF27AE60),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
