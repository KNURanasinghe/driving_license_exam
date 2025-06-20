import 'package:flutter/material.dart';

import 'screen/splash/splash.dart';
import 'services/socket_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// Add 'with WidgetsBindingObserver' to implement the observer interface
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add this widget as an observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize socket when app starts
    SocketService.initialize();
    SocketService.connect();
  }

  @override
  void dispose() {
    // Remove this widget as an observer
    WidgetsBinding.instance.removeObserver(this);

    // Dispose socket when app is closed
    SocketService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        // Reconnect when app comes to foreground
        SocketService.connect();
        print('App resumed - connecting socket');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Disconnect when app goes to background
        SocketService.disconnect();
        print('App paused/detached - disconnecting socket');
        break;
      case AppLifecycleState.hidden:
        print('App hidden');
        break;
      case AppLifecycleState.inactive:
        print('App inactive');
        break;
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Driving License Exam',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      home: const Splash(),
    );
  }
}
