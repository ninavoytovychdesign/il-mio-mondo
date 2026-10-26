import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'screens.dart';
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
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Il mio mondo',
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
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
