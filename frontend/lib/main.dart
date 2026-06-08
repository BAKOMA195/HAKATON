import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'providers/user_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider()..autoLogin(),
      child: MaterialApp(
        title: 'SKS Quest',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFE94560),
          brightness: Brightness.dark,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final provider = context.read<UserProvider>();
    await provider.autoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      size: 80,
                      color: Color(0xFFE94560),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(color: Color(0xFFE94560)),
                    const SizedBox(height: 16),
                    Text(
                      provider.error != null
                          ? 'Ошибка: ${provider.error}'
                          : 'Подключение к SKS Quest...',
                      style: TextStyle(
                        color: provider.error != null ? Colors.red : Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (provider.error != null) ...[
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          provider.clearError();
                          _tryAutoLogin();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text('Попробовать снова'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          provider.clearError();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text('Войти вручную', style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        return const MainScreen();
      },
    );
  }
}
