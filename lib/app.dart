import 'package:flutter/material.dart';

import 'core/services.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'features/shell/home_shell.dart';
import 'l10n/app_localizations.dart';

class SteadyApp extends StatelessWidget {
  const SteadyApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ServicesScope(
      services: services,
      child: MaterialApp(
        title: 'Steady',
        debugShowCheckedModeBanner: false,
        theme: buildSteadyTheme(SteadyColors.dark, Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeShell(),
      ),
    );
  }
}
