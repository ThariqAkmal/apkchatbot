import 'package:difychatbot/screens/auth/login_screen.dart';
import 'package:difychatbot/screens/chatpage_screen.dart';
import 'package:difychatbot/screens/provider_selection_screen.dart';
import 'package:difychatbot/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/n8n_chat_database.dart';
import 'services/web_chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize appropriate storage based on platform
  if (kIsWeb) {
    print('📱 Running on Web - Using SharedPreferences for chat history');
    await WebChatService().loadCurrentConversation();
  } else {
    try {
      await N8nChatDatabase().database;
      print('✅ SQLite database initialized successfully');
    } catch (e) {
      print('⚠️ SQLite initialization failed: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'TSEL AI Assistant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // home: SplashScreen(),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/provider-selection': (context) => ProviderSelectionScreen(),
          '/profile': (context) => ProfileScreen(),
          '/home': (context) => ChatPageScreen(),
        },
      ),
    );
  }
}
