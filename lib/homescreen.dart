import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'courses.dart';
import 'trainers.dart';
import 'students.dart';
import 'mapping.dart';
import 'attendance.dart';
import 'collections.dart';
import 'reports.dart';
import 'settings.dart';
import 'login_page.dart'; // import login page for logout navigation

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userEmail = "";
  String userRole = "";

  // Dropdown allowed values
  final List<String> allowedRoles = ['Admin', 'Trainer', 'Student'];

  final List<Map<String, dynamic>> stats = [
    {
      "title": "Courses",
      "count": 18,
      "icon": Icons.menu_book,
      "color": Colors.blue,
    },
    {
      "title": "Trainers",
      "count": 7,
      "icon": Icons.person,
      "color": Colors.green,
    },
    {
      "title": "Students",
      "count": 125,
      "icon": Icons.school,
      "color": Colors.orange,
    },
    {
      "title": "Ongoing Classes",
      "count": 5,
      "icon": Icons.schedule,
      "color": Colors.purple,
    },
  ];

  final List<Map<String, String>> upcomingClasses = [
    {"title": "React Basics", "trainer": "John Doe", "time": "10:00 AM"},
    {"title": "Java OOP", "trainer": "Jane Smith", "time": "12:00 PM"},
    {"title": "Spring Boot API", "trainer": "Emily Johnson", "time": "2:00 PM"},
    {"title": "Data Structures", "trainer": "Michael Brown", "time": "4:00 PM"},
    {"title": "Angular Essentials", "trainer": "Sarah Davis", "time": "6:00 PM"},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    String email = prefs.getString("email") ?? "user@example.com";
    String role = prefs.getString("role") ?? "User";

    // ✅ Ensure role exists in allowedRoles, else default to first item
    if (!allowedRoles.contains(role)) {
      role = allowedRoles.first;
    }

    if (mounted) {
      setState(() {
        userEmail = email;
        userRole = role;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  static Widget sidebarItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.yellowAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                const Center(
                    child: Icon(Icons.home, color: Colors.white, size: 30)),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'TechEd',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                sidebarItem(Icons.book, 'Courses', () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const Courses()));
                }),
                sidebarItem(Icons.person, 'Trainers', () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const Trainers()));
                }),
                sidebarItem(Icons.people, 'Students', () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StudentsPage()));
                }),
                sidebarItem(Icons.link, 'Mapping', () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const Mapping()));
                }),
                sidebarItem(Icons.check_box, 'Attendance', () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AttendancePage(
                        userId: userEmail,
                        role: userRole,
                      ),
                    ),
                  );
                }),
                sidebarItem(Icons.payment, 'Collections', () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CollectionsPage()));
                }),
                sidebarItem(Icons.bar_chart, 'Reports', () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const Reports()));
                }),
                sidebarItem(Icons.settings, 'Settings', () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const Settings()));
                }),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Role:", style: TextStyle(color: Colors.white)),
                      // ✅ Corrected DropdownButton
                      DropdownButton<String>(
                        value: allowedRoles.contains(userRole)
                            ? userRole
                            : allowedRoles.first,
                        dropdownColor: Colors.white,
                        items: allowedRoles.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false,
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "TechEd Dashboard",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == "logout") {
                    _logout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: "role",
                    enabled: false,
                    child: Text("Role: $userRole"),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: "logout",
                    child: Text("Logout"),
                  ),
                ],
                child: Row(
                  children: [
                    Text(
                      userEmail,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 250,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Manage your courses, trainers, students, and more with ease."),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.map((stat) {
                return Container(
                  width: MediaQuery.of(context).size.width / 2 - 20,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: stat['color'], width: 4),
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(stat['icon'], color: stat['color']),
                      const SizedBox(height: 8),
                      Text(stat['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(stat['count'].toString(), style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              "Upcoming Classes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: upcomingClasses.map((cls) {
                  return ListTile(
                    title: Text(cls['title']!),
                    subtitle: Text(cls['trainer']!),
                    trailing: Text(cls['time']!),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
