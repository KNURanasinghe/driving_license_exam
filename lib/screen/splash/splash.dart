import 'package:driving_license_exam/home.dart';
import 'package:driving_license_exam/screen/login/login.dart';
import 'package:driving_license_exam/services/api_service.dart';
import 'package:flutter/material.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    navigateToNextScreen();
  }

  void navigateToNextScreen() async {
    final uid = await StorageService.getID();
    // Navigate to login screen after 3 seconds
    if (uid == null || uid.isEmpty) {
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: size.height * 0.17,
                ),
                const Text(
                  'App logo',
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(
                  height: size.height * 0.1,
                ),
                Image.asset("assets/images/Loader.png"),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Wait a second ',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                "assets/images/Group 5245.png",
                width: size.width,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
