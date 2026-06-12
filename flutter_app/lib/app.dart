import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/form_provider.dart';
import 'providers/response_provider.dart';

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
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
