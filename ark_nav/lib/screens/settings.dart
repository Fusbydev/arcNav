import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool isDarkMode = false; // Toggle state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE3E3C1), // Background color
          image: const DecorationImage(
            image: AssetImage('assets/wave.png'), // Background image
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Gradient top title
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
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "Settings",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top bar logo
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
                ],
              ),
            ),

            // Rectangles slightly below the title
            Positioned(
              top: 140, // Adjust vertical position
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _darkModeOption(), // Dark/Light mode toggle
                  const SizedBox(height: 16),
                  _alertDistanceOption(),
                  const SizedBox(height: 16),
                  _notificationOption(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // First rectangle with toggle switch
  Widget _darkModeOption() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 250, // Minimum width
        maxWidth: 350, // Maximum width
      ),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1D364E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Dark/Light Mode",
              style: TextStyle(
                color: Color(0xFFE3E3C1),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Switch(
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
              },
              activeColor: const Color(0xFFE3E3C1),
              inactiveThumbColor: Colors.white54,
              inactiveTrackColor: Colors.white30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertDistanceOption() {
  return Center( // Center to make sure it's horizontally centered
    child: Container(
      width: 350, // Fixed width
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D364E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Set Alert Distance",
            style: TextStyle(
              color: Color(0xFFE3E3C1),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Set the distance in which you receive an alert about possible flooding.",
            style: TextStyle(color: Color(0xFFE3E3C1), fontSize: 14),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                WidgetSpan(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E3C1), // background color
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "300m",
                      style: TextStyle(
                        color: Colors.black, // text color
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const TextSpan(
                  text: " (Default)",
                  style: TextStyle(
                    color: Color(0xFFE3E3C1),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
bool isNotificationEnabled = false; // Add this in your State class
  // Other rectangles
Widget _notificationOption() {
  return Center(
    child: Container(
      width: 350, // Fixed width
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D364E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Make text column flexible to avoid overflow
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Manage Notification",
                  style: TextStyle(
                    color: Color(0xFFE3E3C1),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Allow notification for the best experience (recommended)",
                  style: TextStyle(
                    color: Color(0xFFE3E3C1),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis, // Optional: truncate long text
                  maxLines: 2,
                ),
              ],
            ),
          ),

          // Checkbox
          StatefulBuilder(
            builder: (context, setStateSB) {
              return Checkbox(
                value: isNotificationEnabled,
                onChanged: (value) {
                  setStateSB(() {
                    isNotificationEnabled = value!;
                  });
                  setState(() {
                    isNotificationEnabled = value!;
                  });
                },
                activeColor: const Color(0xFFE3E3C1),
                checkColor: const Color(0xFF1D364E),
                side: const BorderSide(color: Color(0xFFE3E3C1)),
              );
            },
          ),
        ],
      ),
    ),
  );
}

}
