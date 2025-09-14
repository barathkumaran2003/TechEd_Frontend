import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

const String BASE_URL = "https://teched-backend-liqn.onrender.com"; // Replace with your API base URL

class Trainers extends StatefulWidget {
  const Trainers({super.key});

  @override
  State<Trainers> createState() => _TrainersState();
}

class _TrainersState extends State<Trainers> {
  bool showForm = false;
  bool loading = false;
  String search = "";

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> formData = {
    "fullName": "",
    "email": "",
    "phone": "",
    "qualification": "",
    "experience": "",
    "skills": "",
    "daysAvailable": "",
    "timeSlots": "",
    "resume": null,
  };

  List<Map<String, dynamic>> trainers = [];

  @override
  void initState() {
    super.initState();
    fetchTrainers();
  }

  Future<void> fetchTrainers() async {
    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse("$BASE_URL/api/trainer"));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body); // <-- Changed here
        setState(() {
          trainers = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        setState(() => trainers = []);
      }
    } catch (e) {
      setState(() => trainers = []);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() {
        formData["resume"] = result.files.single.name;
      });
    }
  }

  void resetForm() {
    setState(() {
      formData = {
        "fullName": "",
        "email": "",
        "phone": "",
        "qualification": "",
        "experience": "",
        "skills": "",
        "daysAvailable": "",
        "timeSlots": "",
        "resume": null,
      };
    });
  }

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> dataToSend = {
        ...formData,
        "date": DateTime.now().toIso8601String().split("T")[0],
        "status": "Approved"
      };
      dataToSend.remove("resume"); // remove resume for now

      try {
        final response = await http.post(
          Uri.parse("$BASE_URL/api/trainer"),
          headers: {"Content-Type": "application/json"},
          body: json.encode(dataToSend),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          await fetchTrainers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trainer registered successfully')),
          );
          resetForm();
          setState(() => showForm = false);
        } else {
          throw Exception("Failed to add trainer");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to register trainer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTrainers = trainers.where((trainer) {
      final lowerSearch = search.toLowerCase();
      return (trainer["fullName"] ?? "").toLowerCase().contains(lowerSearch) ||
          (trainer["email"] ?? "").toLowerCase().contains(lowerSearch);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Management'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & Toggle
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => search = val),
                    decoration: const InputDecoration(
                      hintText: "Search by name or email...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => setState(() => showForm = !showForm),
                  child: Text(showForm ? "Close Form" : "Add Trainer"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Form
            if (showForm)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    buildTextField("fullName", "Full Name", true),
                    buildTextField("email", "Email Address", true,
                        keyboardType: TextInputType.emailAddress),
                    buildTextField("phone", "Phone Number", true,
                        keyboardType: TextInputType.phone),
                    buildTextField("qualification", "Qualification", false),
                    buildTextField("experience", "Years of Experience", false),
                    buildTextField("skills", "Skills (Java, Python...)", false),
                    buildTextField("daysAvailable", "Available Days", false),
                    buildTextField("timeSlots", "Time Slots", false),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: pickFile,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formData["resume"] ?? "Upload Resume (PDF, DOC)",
                                style: TextStyle(
                                  color: formData["resume"] != null
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const Icon(Icons.upload_file, color: Colors.green),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: submitForm,
                          child: const Text("Submit"),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: resetForm,
                          child: const Text("Reset"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            const Text("Trainer List:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Trainer Cards
            loading
                ? const Center(child: CircularProgressIndicator())
                : filteredTrainers.isEmpty
                    ? const Text("No trainers found.")
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTrainers.length,
                        itemBuilder: (context, index) {
                          final trainer = filteredTrainers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(trainer["fullName"] ?? "",
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Email: ${trainer["email"] ?? ""}"),
                                  Text("Phone: ${trainer["phone"] ?? ""}"),
                                  Text("Qualification: ${trainer["qualification"] ?? ""}"),
                                  Text("Experience: ${trainer["experience"] ?? ""}"),
                                  Text("Skills: ${trainer["skills"] ?? ""}"),
                                  Text("Days: ${trainer["daysAvailable"] ?? ""}"),
                                  Text("Time Slots: ${trainer["timeSlots"] ?? ""}"),
                                  Text("Status: ${trainer["status"] ?? "Pending"}"),
                                  Text("Date: ${trainer["date"] ?? ""}"),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String key, String label, bool required,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) => value!.isEmpty ? "Enter $label" : null
            : null,
        onChanged: (val) => setState(() => formData[key] = val),
      ),
    );
  }
}
