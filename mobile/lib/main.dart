
import 'package:material_ui/material_ui.dart';
import 'services/api_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ErrandApp());
}

class ErrandApp extends StatefulWidget {
  const ErrandApp({super.key});

  @override
  State<ErrandApp> createState() => _ErrandAppState();
}

class _ErrandAppState extends State<ErrandApp> {
  Map<String, dynamic>? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    restoreSession();
  }

  Future<void> restoreSession() async {
    await ApiService.loadToken();
    final savedUser = await ApiService.getSavedUser();

    if (!mounted) return;

    setState(() {
      user = savedUser;
      isLoading = false;
    });
  }

  Future<void> onAuthenticated() async {
    final savedUser = await ApiService.getSavedUser();

    if (!mounted) return;

    setState(() {
      user = savedUser;
    });
  }

  Future<void> logout() async {
    await ApiService.clearSession();

    if (!mounted) return;

    setState(() {
      user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Errand Request App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : user == null
              ? AuthScreen(onAuthenticated: onAuthenticated)
              : HomeScreen(
                  user: user!,
                  onLogout: logout,
                ),
    );
  }
}
