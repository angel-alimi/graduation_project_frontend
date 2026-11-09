import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';

class LifeShareApp extends StatefulWidget {
  const LifeShareApp({super.key});

  @override
  State<LifeShareApp> createState() => _LifeShareAppState();
}

class _LifeShareAppState extends State<LifeShareApp> {
  bool? _wasDark;

  /// Colours are read from [AppColors] while building, so after a palette
  /// switch every widget (including const ones) has to build again.
  void _rebuildEverything() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }
    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app; // rebuilds when language or theme changes
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final dark = app.themeMode == 'dark' || (app.themeMode == 'system' && platformDark);

    final theme = buildTheme(app.lang, dark: dark); // also switches AppColors
    if (_wasDark != null && _wasDark != dark) _rebuildEverything();
    _wasDark = dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'LifeShare',
      debugShowCheckedModeBanner: false,
      theme: theme,
      themeAnimationDuration: Duration.zero,
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
