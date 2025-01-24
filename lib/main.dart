import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:planner/view/about_login/start_screen.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'service/notification_service.dart';
import 'view/home_screen.dart';
import 'view_model/auth_view_model.dart';
import 'view_model/calendar_view_model.dart';
import 'view_model/category_view_model.dart';
import 'view_model/audio_view_model.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // splash 화면을 유지하는 부분입니다.
  // flutter application이 초기화되는 동안 splash 화면이 나타나도록 합니다.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 3초간 splash 화면을 유지합니다.
  // splash 화면이 나타나는 시간이 매우 짧기 때문에 시간을 강제로 딜레이 시킵니다.
  await Future.delayed(const Duration(seconds: 3));

  // 1) Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalendarViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(create: (_) => AudioViewModel()),
      ],
      child: const MyApp(),
    ),
  );

  // 2) NotificationService 초기화
  await NotificationService.instance.initialize();

  //splash 화면을 제거하는 부분입니다.
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.instance.navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const StartScreen(),
      routes: {
        '/home_screen': (context) => const HomeScreen(),
        '/start_screen': (context) => const StartScreen(),
      },
    );
  }
}
