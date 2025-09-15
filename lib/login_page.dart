import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'homescreen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String role = "admin";
  String username = "";
  String password = "";
  String error = "";
  bool isLoading = false;

  final roles = [
    {"label": "Admin", "value": "admin", "icon": FontAwesomeIcons.userShield},
    {"label": "Trainer", "value": "trainer", "icon": FontAwesomeIcons.chalkboardTeacher},
    {"label": "Student", "value": "student", "icon": FontAwesomeIcons.userGraduate},
    {"label": "Head", "value": "head", "icon": FontAwesomeIcons.userTie},
  ];

  final _formKey = GlobalKey<FormState>();

  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => error = "Please enter username and password");
      return;
    }

    setState(() {
      isLoading = true;
      error = "";
    });

    try {
      final response = await http.post(
        Uri.parse("https://teched-backend-liqn.onrender.com/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final userRole = data["role"]?.toString() ?? "unknown";
        final userEmail = data["email"]?.toString() ?? "";
        final userMobile = data["mobile"]?.toString() ?? "";

        // ✅ Role validation
        if (userRole != role) {
          setState(() {
            error =
                "Role mismatch! Your account role is '$userRole' but you selected '$role'.";
          });
          return;
        }

        // ✅ Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('role', userRole);
        await prefs.setString('email', userEmail);
        await prefs.setString('mobile', userMobile);

        // ✅ Navigate to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        setState(() {
          error = "Invalid username or password";
        });
      }
    } catch (e) {
      setState(() {
        error = "Error connecting to server: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "TechEd Login",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Role Selection
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: roles.map((r) {
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(r["icon"] as IconData, size: 18),
                              const SizedBox(width: 6),
                              Text(r["label"].toString()),
                            ],
                          ),
                          selected: role == r["value"],
                          onSelected: (_) => setState(() => role = r["value"] as String),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Username
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Username (Email)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Enter username" : null,
                      onChanged: (val) => username = val,
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (val) =>
                          val == null || val.isEmpty ? "Enter password" : null,
                      onChanged: (val) => password = val,
                    ),

                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(error, style: const TextStyle(color: Colors.red)),
                    ],

                    const SizedBox(height: 20),

                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: handleLogin,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Login"),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
