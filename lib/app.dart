import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';

class LifeShareApp extends StatelessWidget {
  const LifeShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app; // rebuilds when the language changes
    return MaterialApp(
      title: 'LifeShare',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(app.lang),
      locale: Locale(app.lang),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
