import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/providers/place_provider.dart';

class TestHelper {
  const TestHelper();

  static Future<void> pumpWidgetWithProviders(
    WidgetTester tester,
    Widget child, {
    AuthProvider? authProvider,
    ProfileProvider? profileProvider,
    PlaceProvider? placeProvider,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider ?? AuthProvider(),
          ),
          ChangeNotifierProvider<ProfileProvider>.value(
            value: profileProvider ?? ProfileProvider(),
          ),
          ChangeNotifierProvider<PlaceProvider>.value(
            value: placeProvider ?? PlaceProvider(),
          ),
        ],
        child: MaterialApp(home: child),
      ),
    );
  }
}

void setupTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  
  // Add any additional test setup here
}

class TestApp extends StatelessWidget {
  final Widget child;

  const TestApp({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: child,
    );
  }
}
