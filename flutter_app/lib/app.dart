import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import 'notifiers/auth_provider.dart';
import 'notifiers/form_provider.dart';
import 'notifiers/response_provider.dart';
import 'notifiers/notification_provider.dart';
import 'notifiers/settings_provider.dart';
import 'notifiers/analytics_provider.dart';
import 'notifiers/user_provider.dart';

/// The display name of the application.
/// Change this single value to rename the app everywhere.
const String appName = 'Form Builder';

class TheArchitectApp extends StatelessWidget {
  const TheArchitectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [

        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FormProvider()),
        ChangeNotifierProvider(create: (_) => ResponseProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp.router(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
