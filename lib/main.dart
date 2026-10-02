import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/services.dart';
import 'data/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting();
  runApp(
    SteadyApp(
      services: AppServices(
        db: AppDatabase.openDefault(),
        clock: const Clock(),
      ),
    ),
  );
}
