import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AttendancePage extends StatefulWidget {
  final String userId; // from login
  final String role;   // "Student" or "Trainer"

  const AttendancePage({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String? attendanceId;
  String status = "Not Marked";
  String location = "";
  String address = "";
  bool isLoading = false;

  final String baseUrl = "https://teched-backend-liqn.onrender.com/attendance";

  /// Get Current Location
  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => location = "Location services are disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => location = "Location permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => location = "Location permission permanently denied");
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        location = "${pos.latitude}, ${pos.longitude}";
      });

      // Optional: Get Address
      List<Placemark> placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          address =
              "${place.locality}, ${place.administrativeArea}, ${place.country}";
        });
      }
    } catch (e) {
      setState(() => location = "Error getting location: $e");
    }
  }

  /// Check In
  Future<void> checkIn() async {
    setState(() => isLoading = true);
    await _getLocation();

    final res = await http.post(
      Uri.parse("$baseUrl/checkin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": widget.userId,
        "role": widget.role,
        "location": location,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        attendanceId = data["id"];
        status = "Checked In at ${data['checkInTime']}";
      });
    } else {
      setState(() => status = "Check-in failed (${res.statusCode})");
    }

    setState(() => isLoading = false);
  }

  /// Check Out
  Future<void> checkOut() async {
    if (attendanceId == null) {
      setState(() => status = "No check-in found");
      return;
    }

    setState(() => isLoading = true);

    final res = await http.post(Uri.parse("$baseUrl/checkout/$attendanceId"));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        status = "Checked Out at ${data['checkOutTime']}";
      });
    } else {
      setState(() => status = "Check-out failed (${res.statusCode})");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Attendance"),
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const CircularProgressIndicator()
              : Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "User: ${widget.userId}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Role: ${widget.role}",
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Status: $status",
                          style: const TextStyle(
                              fontSize: 16, color: Colors.deepPurple),
                        ),
                        const SizedBox(height: 10),
                        if (location.isNotEmpty)
                          Column(
                            children: [
                              Text("Location: $location",
                                  style: const TextStyle(fontSize: 14)),
                              if (address.isNotEmpty)
                                Text("Address: $address",
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black54)),
                            ],
                          ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: checkIn,
                              icon: const Icon(Icons.login),
                              label: const Text("Check In"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: checkOut,
                              icon: const Icon(Icons.logout),
                              label: const Text("Check Out"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
