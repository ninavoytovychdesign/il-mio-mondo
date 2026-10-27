import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'mom.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Full screen: no status bar and no navigation bar while Ostap plays
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final state = await AppState.load();
  runApp(IlMioMondoApp(state: state));
}

class IlMioMondoApp extends StatelessWidget {
  const IlMioMondoApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => _app(),
    );
  }

  Widget _app() {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Pasetto',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Nunito',
          scaffoldBackgroundColor: C.bg,
          colorScheme: ColorScheme.fromSeed(seedColor: C.success, surface: C.bg),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        // The layout is designed for fixed text sizes; the system font scale would break the cards
        builder: (context, child) => MediaQuery(
          // phones get slightly smaller type: the screens are designed for the tablet first
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.sizeOf(context).shortestSide < 600
                ? TextScaler.linear(MediaQuery.sizeOf(context).shortestSide < 380 ? 0.86 : 0.9)
                : TextScaler.noScaling,
          ),
          child: child!,
        ),
        // Date and time pickers in the parents' language
        locale: Locale(state.ui),
        supportedLocales: const [Locale('it'), Locale('uk')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // The app opens on the parents' home with the dock; play starts from there
        home: const MomShell(),
      ),
    );
  }
}
