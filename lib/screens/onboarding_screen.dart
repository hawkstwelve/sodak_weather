import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/onboarding_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/location_provider.dart';

/// Onboarding screen using introduction_screen package with glassmorphism styling
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final GlobalKey<IntroductionScreenState> _introKey = GlobalKey<IntroductionScreenState>();

  bool? _locationGranted; // null = not attempted, true = granted, false = denied
  bool? _notificationGranted;
  bool _locationRequesting = false;
  bool _notificationRequesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IntroductionScreen(
        key: _introKey,
        globalBackgroundColor: const Color(0xFFF8F9FA),
        pages: _buildPages(),
        showSkipButton: true,
        showNextButton: true,
        showBackButton: true,
        showDoneButton: true,
        skip: _buildGlassButton('Skip'),
        next: _buildGlassButton('Next'),
        back: _buildGlassButton('Back'),
        done: _buildDoneButton(),
        onDone: _handleOnDone,
        onSkip: _handleOnSkip,
        dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(20.0, 10.0),
          activeColor: const Color(0xFF0a6e0c),
          color: Colors.grey.shade300,
          spacing: const EdgeInsets.symmetric(horizontal: 3.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        baseBtnStyle: TextButton.styleFrom(
          foregroundColor: AppTheme.textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          minimumSize: const Size(140.0, 48.0),
        ),
        controlsMargin: const EdgeInsets.all(24.0),
        controlsPadding: const EdgeInsets.all(16.0),
        animationDuration: 400,
        curve: Curves.easeInOut,
      ),
    );
  }

  List<PageViewModel> _buildPages() {
    return [
      _buildWelcomePage(),
      _buildLocationPermissionPage(),
      _buildNotificationPermissionPage(),
      _buildFinalPage(),
    ];
  }

  PageViewModel _buildWelcomePage() {
    return PageViewModel(
      title: 'Welcome to Sodak Weather',
      body: 'Your personal weather companion for South Dakota. Get accurate forecasts, radar data, and weather alerts tailored to your location.',
      image: Center(
        child: Container(
          padding: const EdgeInsets.only(top: 80.0, left: 16.0, right: 16.0, bottom: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.asset(
              'assets/onboarding/welcome.png',
              height: 700.0,
              width: 300.0,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
        bodyTextStyle: TextStyle(
          fontSize: 16.0,
          color: AppTheme.textDark,
        ),
        pageColor: Color(0xFFF8F9FA),
        imageFlex: 2,
        bodyFlex: 1,
      ),
    );
  }

  PageViewModel _buildLocationPermissionPage() {
    return PageViewModel(
      title: 'Location Access',
      image: Center(
        child: Container(
          padding: const EdgeInsets.only(top: 80.0, left: 16.0, right: 16.0, bottom: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.asset(
              'assets/onboarding/location.png',
              height: 700.0,
              width: 300.0,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      bodyWidget: Column(
        children: [
          const Text(
            'To provide you with accurate weather forecasts and alerts, we need access to your location. This helps us show you weather data for your exact area.',
            style: TextStyle(
              fontSize: 16.0,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          Center(
            child: _locationGranted == true
                ? const Icon(Icons.check_circle, color: Colors.green, size: 40)
                : _locationGranted == false
                    ? const Icon(Icons.cancel, color: Colors.red, size: 40)
                    : ElevatedButton.icon(
                        icon: _locationRequesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.location_on),
                        label: const Text('Allow Location'),
                        onPressed: _locationRequesting
                            ? null
                            : () async {
                                setState(() => _locationRequesting = true);
                                final permission = await Geolocator.requestPermission();
                                if (!mounted) return;
                                setState(() {
                                  _locationGranted = (permission == LocationPermission.always || permission == LocationPermission.whileInUse)
                                      ? true
                                      : false;
                                  _locationRequesting = false;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD84315),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
          ),
        ],
      ),
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
        bodyTextStyle: TextStyle(
          fontSize: 16.0,
          color: AppTheme.textDark,
        ),
        pageColor: Color(0xFFF8F9FA),
        imageFlex: 2,
        bodyFlex: 1,
      ),
    );
  }

  PageViewModel _buildNotificationPermissionPage() {
    return PageViewModel(
      title: 'Weather Notifications',
      image: Center(
        child: Container(
          padding: const EdgeInsets.only(top: 80.0, left: 16.0, right: 16.0, bottom: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.asset(
              'assets/onboarding/notification.png',
              height: 700.0,
              width: 300.0,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      bodyWidget: Column(
        children: [
          const Text(
            'Stay informed about severe weather conditions, alerts, and important weather updates with timely notifications.',
            style: TextStyle(
              fontSize: 16.0,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          Center(
            child: _notificationGranted == true
                ? const Icon(Icons.check_circle, color: Colors.green, size: 40)
                : _notificationGranted == false
                    ? const Icon(Icons.cancel, color: Colors.red, size: 40)
                    : ElevatedButton.icon(
                        icon: _notificationRequesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.notifications_active),
                        label: const Text('Allow Notifications'),
                        onPressed: _notificationRequesting
                            ? null
                            : () async {
                                setState(() => _notificationRequesting = true);
                                final notificationService = Provider.of<NotificationService>(context, listen: false);
                                await notificationService.requestPermissions();
                                final settings = await notificationService.messaging.getNotificationSettings();
                                if (!mounted) return;
                                setState(() {
                                  _notificationGranted = (settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional)
                                      ? true
                                      : false;
                                  _notificationRequesting = false;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD84315),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
          ),
        ],
      ),
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
        bodyTextStyle: TextStyle(
          fontSize: 16.0,
          color: AppTheme.textDark,
        ),
        pageColor: Color(0xFFF8F9FA),
        imageFlex: 2,
        bodyFlex: 1,
      ),
    );
  }

  PageViewModel _buildFinalPage() {
    return PageViewModel(
      title: 'You\'re All Set!',
      body: 'Sodak Weather is ready to provide you with accurate weather information, beautiful radar views, and timely alerts. Enjoy your personalized weather experience!',
      image: Center(
        child: Container(
          padding: const EdgeInsets.only(top: 80.0, left: 16.0, right: 16.0, bottom: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.asset(
              'assets/onboarding/complete.png',
              height: 700.0,
              width: 300.0,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
        bodyTextStyle: TextStyle(
          fontSize: 16.0,
          color: AppTheme.textDark,
        ),
        pageColor: Color(0xFFF8F9FA),
        imageFlex: 2,
        bodyFlex: 1,
      ),
    );
  }

  Widget _buildGlassButton(String text) {
    return SizedBox(
      width: 100.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Color.alphaBlend(Colors.black.withAlpha((0.1 * 255).toInt()), Colors.transparent),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            softWrap: false,
          ),
        ),
      ),
    );
  }

  Widget _buildDoneButton() {
    return Container(
      width: 120.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Color.alphaBlend(Colors.black.withAlpha((0.1 * 255).toInt()), Colors.transparent),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Done',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
          softWrap: false,
        ),
      ),
    );
  }

  Future<void> _handleOnDone() async {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await onboardingProvider.markComplete();
    await locationProvider.getCurrentLocation(forceRefresh: true);
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleOnSkip() async {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    Provider.of<LocationProvider>(context, listen: false);
    await onboardingProvider.markComplete();
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
} 