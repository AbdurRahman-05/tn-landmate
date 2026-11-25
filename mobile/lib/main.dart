import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/shell_screen.dart';
import 'shared/widgets/gov_portal_host.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: TnLandMateApp(),
    ),
  );
}

class TnLandMateApp extends ConsumerWidget {
  const TnLandMateApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'TN LandMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ta', 'IN'),
      ],
      // Connects to eservices.tn.gov.in in the background as soon as the app opens.
      builder: (context, child) => GovPortalHost(child: child ?? const SizedBox.shrink()),
      home: const ShellScreen(),
    );
  }
}
