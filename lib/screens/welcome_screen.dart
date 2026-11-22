import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../services/biometric_authenticator.dart';
import '../widgets/fliq_logo.dart';
import '../widgets/welcome_button.dart' as welcome;
import '../services/account_store.dart';
import 'biometric_lock_screen.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({required this.biometricAuthenticator, super.key});

  final BiometricAuthenticator biometricAuthenticator;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with WidgetsBindingObserver {
  late final VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videoController = VideoPlayerController.asset('assets/videos/welcome.mp4');
    _startBackgroundVideo();
  }

  Future<void> _startBackgroundVideo() async {
    try {
      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.setVolume(0);
      await _videoController.play();
      if (mounted) setState(() {});
    } on PlatformException catch (error) {
      debugPrint('Could not play the welcome background video: $error');
    } on UnimplementedError catch (error) {
      debugPrint('Welcome background video is unsupported: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_videoController.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      _videoController.play();
    } else {
      _videoController.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            _WelcomeVideo(controller: _videoController),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.32, 0.55, 0.76, 1],
                  colors: [
                    Color(0x22000000),
                    Color(0x12000000),
                    Color(0x88000000),
                    Color(0xFF000000),
                    Color(0xFF000000),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    const FliqLogo(),
                    const SizedBox(height: 30),
                    const Text(
                      'Money without\nborders',
                      style: TextStyle(
                        fontSize: 35,
                        height: 1.17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.35,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'Any chain. Any bank or mobile money.\n'
                      'Best live rates, in seconds.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    const SizedBox(height: 32),
                    welcome.WelcomeButton(
                      label: 'Continue with passkey',
                      icon: Icons.person_add_alt_1_outlined,
                      isPrimary: true,
                      onPressed: _start,
                    ),
                    const SizedBox(height: 12),
                    welcome.WelcomeButton(
                      label: 'I already have an account',
                      icon: Icons.undo_rounded,
                      isPrimary: false,
                      onPressed: _start,
                    ),
                    const SizedBox(height: 58),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Signed in already: unlock. Otherwise sign in with an email link.
  /// Passkeys on Android need fliq.cash to trust this app first, so both
  /// buttons use email for now.
  Future<void> _start() async {
    final navigator = Navigator.of(context);
    if (!AccountStore.instance.isSignedIn) {
      final signedIn = await navigator.push<bool>(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
      if (signedIn != true || !mounted) return;
      await navigator.pushAndRemoveUntil<void>(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
      return;
    }
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            BiometricLockScreen(authenticator: widget.biometricAuthenticator),
      ),
    );
  }
}

class _WelcomeVideo extends StatelessWidget {
  const _WelcomeVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    final size = controller.value.size;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
