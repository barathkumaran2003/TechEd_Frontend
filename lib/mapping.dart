import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Replace with your actual base URL
const String BASE_URL = "https://teched-backend-liqn.onrender.com";

class Mapping extends StatefulWidget {
  const Mapping({super.key});

  @override
  State<Mapping> createState() => _TrainerStudentMappingPageState();
}

class _TrainerStudentMappingPageState extends State<Mapping> {
  // Data lists
  List<String> courses = [];
  List<Map<String, dynamic>> trainers = []; // fullName, trainerId
  List<String> students = [];
  List<Map<String, dynamic>> mappings = [];

  // Form fields
  String selectedCourse = "";
  String selectedTrainer = "";
  int? selectedTrainerId;
  TextEditingController studentController = TextEditingController();

  // Filter
  TextEditingController filterController = TextEditingController();
  String debouncedFilter = "";

  int? editingIndex;
  String userRole = "";

  @override
  void initState() {
    super.initState();
    loadUserRole();
    fetchCourses();
    fetchTrainers();
    fetchStudents();
    fetchMappings();

    filterController.addListener(() {
      setState(() {
        debouncedFilter = filterController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString("role") ?? "";
    });
  }

  // ===== API Calls =====
  Future<void> fetchCourses() async {
    try {
      final res = await http.get(Uri.parse("$BASE_URL/api/course"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          courses = (data as List)
              .map((c) => c['name'] ?? c['title'] ?? "Unnamed Course")
              .cast<String>()
              .toList();
        });
      }
    } catch (_) {
      setState(() {
        courses = ["Full Stack", "React JS", "3D Design"];
      });
    }
  }

  Future<void> fetchTrainers() async {
    try {
      final res = await http.get(Uri.parse("$BASE_URL/api/trainer"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          trainers = (data as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
      setState(() {
        trainers = [
          {"fullName": "Alice Johnson", "trainerId": 5000},
          {"fullName": "Bob Smith", "trainerId": 5001},
        ];
      });
    }
  }

  Future<void> fetchStudents() async {
    try {
      final res = await http.get(Uri.parse("$BASE_URL/api/student"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          students = (data as List)
              .map((s) => s['name'] ?? "Unknown")
              .cast<String>()
              .toList();
        });
      }
    } catch (_) {
      setState(() {
        students = ["Ram", "Priya", "Sita"];
      });
    }
  }

  Future<void> fetchMappings() async {
    try {
      final res = await http.get(Uri.parse("$BASE_URL/api/mapping"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          mappings = (data as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
      setState(() {
        mappings = [];
      });
    }
  }

  // ===== Helpers =====
  List<String> getSelectedStudents() {
    return studentController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void resetForm() {
    setState(() {
      selectedCourse = "";
      selectedTrainer = "";
      selectedTrainerId = null;
      studentController.clear();
      editingIndex = null;
    });
  }

  Future<void> assignTrainer() async {
    final trimmedCourse = selectedCourse.trim();
    final trimmedTrainer = selectedTrainer.trim();
    final studentsArray = getSelectedStudents();

    if (trimmedCourse.isEmpty ||
        trimmedTrainer.isEmpty ||
        selectedTrainerId == null ||
        studentsArray.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select a course, trainer, and students.")));
      return;
    }

    final mapping = {
      "course": trimmedCourse,
      "trainer": trimmedTrainer,
      "trainerId": selectedTrainerId,
      "students": studentsArray,
      "date": DateTime.now().toString().split(" ").first,
      "status": "Active",
    };

    try {
      http.Response res;
      if (editingIndex != null) {
        final existingMapping = mappings[editingIndex!];
        res = await http.put(
          Uri.parse("$BASE_URL/api/mapping/${existingMapping['id']}"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({...mapping, "id": existingMapping['id']}),
        );
      } else {
        res = await http.post(
          Uri.parse("$BASE_URL/api/mapping"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(mapping),
        );
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await fetchMappings();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(editingIndex != null
                ? "Mapping updated!"
                : "Mapping saved!")));
        resetForm();
      }
    } catch (err) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $err")));
    }
  }

  void handleEdit(int index) {
    final mapping = mappings[index];
    setState(() {
      selectedCourse = mapping["course"];
      selectedTrainer = mapping["trainer"];
      selectedTrainerId = mapping["trainerId"];
      studentController.text = (mapping["students"] as List).join(", ");
      editingIndex = index;
    });
  }

  Future<void> handleRemove(int index) async {
    final mapping = mappings[index];
    if (mapping["id"] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid mapping id.")));
      return;
    }
    try {
      final res = await http.delete(
        Uri.parse("$BASE_URL/api/mapping/${mapping['id']}"),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await fetchMappings();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Mapping removed!")));
        resetForm();
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting mapping: $err")));
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final filteredMappings = debouncedFilter.isEmpty
        ? mappings
        : mappings
            .where((m) => (m["students"] as List)
                .any((s) => (s as String)
                    .toLowerCase()
                    .contains(debouncedFilter.toLowerCase())))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trainer-Student Mapping"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ✅ Show Assign Trainer Form only for admin, head, trainer
              if (userRole == "admin" ||
                  userRole == "head" ||
                  userRole == "trainer") ...[
                TextField(
                  controller: studentController,
                  decoration: const InputDecoration(
                    labelText: "Students (comma separated)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCourse.isEmpty ? null : selectedCourse,
                  items: courses
                      .map((c) => DropdownMenuItem<String>(
                          value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedCourse = val ?? "";
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Course",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTrainer.isEmpty ? null : selectedTrainer,
                  items: trainers
                      .map((t) => DropdownMenuItem<String>(
                            value: t["fullName"].toString(),
                            child: Text(
                                "${t["fullName"]} (ID: ${t["trainerId"]})"),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedTrainer = val ?? "";
                      final trainer = trainers.firstWhere(
                          (t) => t["fullName"].toString() == val,
                          orElse: () => {});
                      selectedTrainerId = trainer["trainerId"];
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Trainer",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: assignTrainer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            editingIndex != null ? Colors.green : Colors.blue,
                      ),
                      child: Text(editingIndex != null
                          ? "Save Changes"
                          : "Assign Trainer"),
                    ),
                    if (editingIndex != null) const SizedBox(width: 8),
                    if (editingIndex != null)
                      ElevatedButton(
                        onPressed: resetForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text("Cancel"),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              TextField(
                controller: filterController,
                decoration: const InputDecoration(
                  labelText: "Filter by student name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DataTable(
                columns: const [
                  DataColumn(label: Text("Course")),
                  DataColumn(label: Text("Trainer")),
                  DataColumn(label: Text("Trainer ID")),
                  DataColumn(label: Text("Students")),
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: filteredMappings.isEmpty
                    ? [
                        const DataRow(cells: [
                          DataCell(Text("No matching records found.",
                              style: TextStyle(color: Colors.grey))),
                          DataCell.empty,
                          DataCell.empty,
                          DataCell.empty,
                          DataCell.empty,
                          DataCell.empty,
                          DataCell.empty,
                        ])
                      ]
                    : filteredMappings.asMap().entries.map((entry) {
                        final i = entry.key;
                        final m = entry.value;
                        return DataRow(cells: [
                          DataCell(Text(m["course"] ?? "")),
                          DataCell(Text(m["trainer"] ?? "")),
                          DataCell(Text("${m["trainerId"] ?? "N/A"}")),
                          DataCell(Text((m["students"] as List).join(", "))),
                          DataCell(Text(m["date"] ?? "")),
                          DataCell(Text(m["status"] ?? "Active")),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => handleEdit(i),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => handleRemove(i),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
