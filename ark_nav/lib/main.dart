import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'screens/settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapWithUI(),
    );
  }
}

class MapWithUI extends StatefulWidget {
  const MapWithUI({super.key});

  @override
  State<MapWithUI> createState() => _MapWithUIState();
}

class _MapWithUIState extends State<MapWithUI> {
  LatLng? _currentLatLng;
  LatLng? _pinnedLatLng; // For pinned location
  TextEditingController _locationController = TextEditingController();
  TextEditingController _pinLocationController = TextEditingController(); // Pin input
  String selectedDuration = 'Now';
  final MapController _mapController = MapController(); // Map controller

  @override
  void initState() {
    super.initState();
    _updateCurrentLocation(); // fetch location on start
  }

  // Get current GPS position
  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // Convert coordinates to address
  Future<String> _getAddressFromLatLng(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      return '${place.street}, ${place.locality}, ${place.country}';
    }
    return '';
  }

  // Update map marker and input field
  void _updateCurrentLocation() async {
    try {
      Position pos = await _getCurrentPosition();
      String address = await _getAddressFromLatLng(pos);

      setState(() {
        _currentLatLng = LatLng(pos.latitude, pos.longitude);
        _locationController.text = address;
      });
    } catch (e) {
      print("ERROR: $e");
    }
  }

  // Fetch nearby streets using Overpass API
  Future<List<String>> _fetchNearbyStreets(
      double lat, double lon, int radius) async {
    final overpassQuery = """
      [out:json];
      (
        way(around:$radius,$lat,$lon)["highway"];
      );
      out tags;
    """;

    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      body: overpassQuery,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<String> streets = [];
      for (var element in data['elements']) {
        if (element['tags'] != null && element['tags']['name'] != null) {
          streets.add(element['tags']['name']);
        }
      }
      return streets.toSet().toList();
    } else {
      return [];
    }
  }

  // Show streets in a dialog
  void _showNearbyStreetsDialog(LatLng position) async {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<String>>(
        future: _fetchNearbyStreets(position.latitude, position.longitude, 300),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator())),
            );
          } else if (snapshot.hasError) {
            return AlertDialog(
              title: const Text("Error"),
              content: Text(snapshot.error.toString()),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"))
              ],
            );
          } else {
            final streets = snapshot.data ?? [];
            return AlertDialog(
              backgroundColor: const Color(0xFF1D364E),
              title: const Text(
                "Nearby Streets",
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: streets.isEmpty
                    ? const Center(
                        child: Text(
                          "No streets found nearby.",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: streets.length,
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A4A6F),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                streets[index],
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // Convert address to LatLng for pin
  Future<LatLng?> _getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print("Error converting address: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLatLng ?? LatLng(14.5995, 120.9842),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.ark_nav',
              ),

              // Current Location Circle + Marker
              if (_currentLatLng != null) ...[
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentLatLng!,
                      radius: 300, // meters
                      useRadiusInMeter: true,
                      color: Colors.blue.withOpacity(0),
                      borderStrokeWidth: 2,
                      borderColor: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLatLng!,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showNearbyStreetsDialog(_currentLatLng!),
                        child: const Icon(
                          Icons.my_location,
                          color: Color(0xFF01AFBA),
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Pinned Location Circle + Marker
              if (_pinnedLatLng != null) ...[
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _pinnedLatLng!,
                      radius: 300,
                      useRadiusInMeter: true,
                      color: Colors.red.withOpacity(0),
                      borderStrokeWidth: 2,
                      borderColor: Colors.red,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pinnedLatLng!,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showNearbyStreetsDialog(_pinnedLatLng!),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          // Top fade overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1D364E),
                    image: const DecorationImage(
                      image: AssetImage('assets/logo.png'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _topIconButton(Icons.notifications, () {}),
                    const SizedBox(width: 8),
                    _topIconButton(Icons.settings, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Settings()),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          // Bottom container (status + inputs)
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _circleIconButton(Icons.refresh, _updateCurrentLocation),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D364E),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statusCircle(Colors.green, 'Safe'),
                              _statusCircle(Colors.yellow, 'Moderate'),
                              _statusCircle(Colors.red, 'Danger'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _circleIconButton(Icons.restart_alt, () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Bottom input rectangle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D364E),
                    image: DecorationImage(
                      image: AssetImage('assets/wave.png'),
                      fit: BoxFit.cover,
                      opacity: 0.5,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Duration selector
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: ['Now', '3 Days', '7 Days']
                                .map((duration) {
                              final bool isSelected = selectedDuration == duration;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedDuration = duration;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blueAccent
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    duration,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        // Current Location input
                        TextField(
                          controller: _locationController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Current Location',
                            labelStyle: const TextStyle(color: Colors.white),
                            hintText: 'Enter location',
                            hintStyle: const TextStyle(color: Colors.white70),
                            prefixIcon:
                                const Icon(Icons.my_location, color: Colors.white),
                            filled: true,
                            fillColor: const Color(0xFF1D364E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.white70),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide:
                                  const BorderSide(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Pin another location input
                        TextField(
                          controller: _pinLocationController,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (value) async {
                            LatLng? latLng = await _getLatLngFromAddress(value);
                            if (latLng != null) {
                              setState(() {
                                _pinnedLatLng = latLng;
                              });
                              _mapController.move(latLng, 15.0);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Pin another location',
                            labelStyle: const TextStyle(color: Colors.white),
                            hintText: 'Enter another location',
                            hintStyle: const TextStyle(color: Colors.white70),
                            prefixIcon:
                                const Icon(Icons.location_on, color: Colors.white),
                            filled: true,
                            fillColor: const Color(0xFF1D364E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.white70),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide:
                                  const BorderSide(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 45,
      height: 45,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white24,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF01AFBA)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1D364E),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF01AFBA)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _statusCircle(Color color, String label) {
    return Column(
      children: [
        CircleAvatar(radius: 12, backgroundColor: color),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
