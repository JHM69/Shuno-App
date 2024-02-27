//Shuno

import 'package:flutter/material.dart';
import 'package:shuno/Screens/Home/shuno.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //String name = Hive.box('settings').get('username', defaultValue: 'Guest') as String;

    final brightness = Theme.of(context).brightness;

    // Determine the image path based on the theme brightness
    final imagePath = brightness == Brightness.dark
        ? 'assets/dark_logo.png' // Image for dark theme
        : 'assets/light_logo.png'; // Image for light theme

    // final double screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 70,
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset(
                  imagePath,
                  height: 40,
                ),
                const Spacer(), // Creates space between the image and the icons
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  // Notification icon
                  onPressed: () {
                    Navigator.pushNamed(context, '/notification');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.history_rounded), // Profile icon
                  onPressed: () {
                    Navigator.pushNamed(context, '/recent');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined), // Profile icon
                  onPressed: () {
                    Navigator.pushNamed(context, '/setting');
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ShunoHomePage(), // Your main content here
            ),
          ),
        ],
      ),
    );
  }
}
