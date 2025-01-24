import 'package:flutter/material.dart';
import 'package:planner/theme/theme.dart';

class HomeNavigatorScreen extends StatefulWidget {
  const HomeNavigatorScreen({super.key});

  @override
  State<HomeNavigatorScreen> createState() => _HomeNavigatorScreenState();
}

class _HomeNavigatorScreenState extends State<HomeNavigatorScreen> {
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    currentPageIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.25),
              blurRadius: 4,
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
              (Set<WidgetState> states) {
                final isSelected = states.contains(WidgetState.selected);
                return TextStyle(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.secondary
                      : const Color(0xFF535252),
                  fontSize: 15,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -0.32,
                );
              },
            ),
          ),
          child: NavigationBar(
            indicatorColor: Colors.transparent,
            backgroundColor: Colors.white,
            onDestinationSelected: (int index) {
              setState(() {
                currentPageIndex = index;
              });
            },
            selectedIndex: currentPageIndex,
            destinations: <Widget>[
              NavigationDestination(
                selectedIcon: Image.asset(
                  "assets/home.png",
                  width: (31 / 393) * screenWidth,
                  height: (31 / 852) * screenHeight,
                  color: const Color(0xff1a86ff),
                ),
                icon: Image.asset(
                  "assets/home.png",
                  width: (31 / 393) * screenWidth,
                  height: (31 / 852) * screenHeight,
                  color: const Color(0xff9d9d9d),
                ),
                label: '홈',
              ),
              NavigationDestination(
                icon: Image.asset(
                  'assets/stamp.png',
                  width: (31 / 393) * screenWidth,
                  height: (31 / 852) * screenHeight,
                  color: const Color(0xff9d9d9d),
                ),
                selectedIcon: Image.asset(
                  'assets/stamp.png',
                  width: (31 / 393) * screenWidth,
                  height: (31 / 852) * screenHeight,
                  color: const Color(0xff1a86ff),
                ),
                label: '스탬프',
              ),
              NavigationDestination(
                icon: Image.asset(
                  'assets/map_home.png',
                  width: (31 / 393) * screenWidth,
                  height: (31 / 852) * screenHeight,
                  color: const Color(0xff9d9d9d),
                ),
                selectedIcon: Image.asset(
                  'assets/map_home.png',
                  width: (31 / 393) * screenWidth,
                  height: (31 / 852) * screenHeight,
                  color: const Color(0xff1a86ff),
                ),
                label: '지도',
              ),
              NavigationDestination(
                icon: Image.asset(
                  'assets/taxi_home.png',
                  width: (31 / 393) * screenWidth,
                  height: (31 / 852) * screenHeight,
                  color: const Color(0xff9d9d9d),
                ),
                selectedIcon: Image.asset(
                  'assets/taxi_home.png',
                  width: (31 / 393) * screenWidth,
                  height: (31 / 852) * screenHeight,
                  color: const Color(0xff1a86ff),
                ),
                label: '이동수단',
              ),
            ],
          ),
        ),
      ),
      body: <Widget>[][currentPageIndex],
    );
  }
}
