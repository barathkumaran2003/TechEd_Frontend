import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// import '../images/person.png'; // Your placeholder image path

class StudentDetail extends StatefulWidget {
  final dynamic studentId;

  const StudentDetail({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentDetail> createState() => _StudentDetailState();
}

class _StudentDetailState extends State<StudentDetail> {
  Map<String, dynamic>? studentInfo;
  bool isLoading = true;
  bool isError = false;

  final String baseUrl = 'https://teched-backend-liqn.onrender.com'; // Your backend URL

  @override
  void initState() {
    super.initState();
    fetchStudent();
  }

  Future<void> fetchStudent() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/student/${widget.studentId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          studentInfo = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (isError || studentInfo == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Student Profile"),
        ),
        body: const Center(child: Text("Failed to load student information.")),
      );
    }

    String name = studentInfo!['name'] ?? 'Unknown';
    String email = studentInfo!['email'] ?? 'N/A';
    String phone = studentInfo!['phone'] ?? 'N/A';
    String studentId = studentInfo!['studentId']?.toString() ?? 'N/A';
    List<dynamic> courses = studentInfo!['courses'] ?? [];
    List<dynamic> trainers = studentInfo!['trainers'] ?? [];
    String? profileUrl = studentInfo!['profilePicUrl'];

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                  ? NetworkImage(profileUrl)
                  : const AssetImage('assets/images/person.png') as ImageProvider,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(email),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(phone),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: Text('ID: $studentId'),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...courses.map((course) => Chip(
                      label: Text(course.toString()),
                      backgroundColor: Colors.lightBlueAccent.shade100,
                    )),
                ...trainers.map((trainer) => Chip(
                      label: Text(trainer.toString()),
                      backgroundColor: Colors.greenAccent.shade100,
                    )),
              ],
            ),
            // Add more details if needed...
          ],
        ),
      ),
    );
  }
}