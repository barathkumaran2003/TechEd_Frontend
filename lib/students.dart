import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'student_detail.dart'; // Make sure this file exists in your project

const String BASE_URL = "https://teched-backend-liqn.onrender.com";

class StudentsPage extends StatefulWidget {
  const StudentsPage({Key? key}) : super(key: key);

  @override
  _StudentsPageState createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final response = await http.get(Uri.parse("$BASE_URL/api/student"));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> data;

        // Handle both [] and { "students": [...] }
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded.containsKey("students")) {
          data = decoded["students"];
        } else {
          data = [];
        }

        setState(() {
          students = data;
          filteredStudents = data;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load students");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching students: $e");
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      final response =
          await http.delete(Uri.parse("$BASE_URL/api/student/$studentId"));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student deleted successfully")),
        );
        fetchStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete student")),
        );
      }
    } catch (e) {
      print("Error deleting student: $e");
    }
  }

  void filterStudents(String query) {
    final results = students.where((student) {
      final name = (student['name'] ?? "").toLowerCase();
      final id = (student['studentId'] ?? "").toString().toLowerCase();
      final searchLower = query.toLowerCase();
      return name.contains(searchLower) || id.contains(searchLower);
    }).toList();

    setState(() {
      filteredStudents = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Management"),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterStudents,
                    decoration: InputDecoration(
                      hintText: "Search by Name or ID...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredStudents.isEmpty
                      ? const Center(child: Text("No students found"))
                      : ListView.builder(
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              elevation: 4,
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: student['profilePicUrl'] !=
                                              null &&
                                          student['profilePicUrl']
                                              .toString()
                                              .isNotEmpty
                                      ? NetworkImage(
                                          student['profilePicUrl'].toString())
                                      : const AssetImage(
                                              "assets/images/person.png")
                                          as ImageProvider,
                                ),
                                title: Text(student['name'] ?? "N/A"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("ID: GT${student['studentId'] ?? 'N/A'}"),
                                    Text("Email: ${student['email'] ?? 'N/A'}"),
                                    Text("Phone: ${student['contact'] ?? 'N/A'}"),
                                    Text("Course: ${student['course'] ?? ''}"),
                                    Text("Trainer: ${student['trainer'] ?? ''}"),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                      child: const Text("View Profile"),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => StudentDetail(
                                              studentId:
                                                  student['studentId'].toString(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text("Delete"),
                                      onPressed: () {
                                        deleteStudent(
                                            student['studentId'].toString());
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
