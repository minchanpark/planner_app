import 'package:flutter/material.dart';
import 'package:planner/view/about_camera/camera_screen.dart';
import '../theme/theme.dart';
import 'home_screen.dart';

class HomePageNavigationBar extends StatefulWidget {
  const HomePageNavigationBar({super.key});

  @override
  State<HomePageNavigationBar> createState() => _HomePageNavigationBarState();
}

class _HomePageNavigationBarState extends State<HomePageNavigationBar> {
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    currentPageIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(),
        child: NavigationBar(
          indicatorColor: Colors.transparent,
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          selectedIndex: currentPageIndex,
          destinations: <Widget>[
            const NavigationDestination(
              selectedIcon: Icon(
                Icons.home,
                color: Color(0xffead8ca),
                size: 31,
              ),
              icon: Icon(
                Icons.home,
                size: 31,
                color: Color(0xff535252),
              ),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.camera_alt,
                size: 31,
                color: Color(0xff535252),
              ),
              selectedIcon: Icon(
                Icons.camera_alt,
                size: 31,
                color: Color(0xffead8ca),
              ),
              label: '',
            ),
            const NavigationDestination(
              icon: Icon(
                Icons.plus_one,
                size: 31,
                color: Color(0xff535252),
              ),
              selectedIcon: Icon(
                Icons.plus_one,
                size: 31,
                color: Color(0xffead8ca),
              ),
              label: '',
            ),
          ],
        ),
      ),
      body: <Widget>[
        const HomeScreen(),
        const CameraScreen(),
        const CameraScreen(),
      ][currentPageIndex],
    );
  }
}
