import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme.dart';
import 'injection.dart' as di;
import 'router.dart';

/// The entry point of the Flutter application.
/// Initializes the app by setting up system UI, preferred orientations,
/// dependency injection, and then runs the OneGameApp widget.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF16213E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await di.init();

  runApp(const OneGameApp());
}

/// The root widget of the Flutter application.
/// This is a stateless widget that provides the MaterialApp with
/// the app's title, theme, and router configuration.
class OneGameApp extends StatelessWidget {
  /// Creates a OneGameApp widget.
  const OneGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '1Game',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
