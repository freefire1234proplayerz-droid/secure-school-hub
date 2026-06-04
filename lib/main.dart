import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'services/local_db.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/parent_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalDb.init();

  runApp(const SecureSchoolHubApp());
}

class SecureSchoolHubApp extends StatelessWidget {
  const SecureSchoolHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => ApiService()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'SecureSchoolHub',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
              brightness: Brightness.light,
              cardTheme: const CardThemeData(
                margin: EdgeInsets.zero,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
              brightness: Brightness.dark,
              cardTheme: const CardThemeData(
                margin: EdgeInsets.zero,
              ),
            ),
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const LoginScreen(),
            routes: {
              AdminDashboard.routeName: (_) => const AdminDashboard(),
              TeacherDashboard.routeName: (_) => const TeacherDashboard(),
              ParentDashboard.routeName: (_) => const ParentDashboard(),
            },
          );
        },
      ),
    );
  }
}
