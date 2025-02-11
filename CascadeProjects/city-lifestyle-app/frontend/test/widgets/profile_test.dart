import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/user_profile.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/screens/profile_screen.dart';
import '../test_helper.dart';

import 'profile_test.mocks.dart';

@GenerateMocks([ProfileProvider])
void main() {
  late MockProfileProvider mockProfileProvider;

  setUp(() {
    mockProfileProvider = MockProfileProvider();
  });

  testWidgets('displays loading indicator when loading', (tester) async {
    when(mockProfileProvider.isLoading).thenReturn(true);
    when(mockProfileProvider.profile).thenReturn(null);
    when(mockProfileProvider.error).thenReturn(null);

    await TestHelper.pumpWidgetWithProviders(
      tester,
      const ProfileScreen(),
      profileProvider: mockProfileProvider,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays error message when there is an error', (tester) async {
    when(mockProfileProvider.isLoading).thenReturn(false);
    when(mockProfileProvider.error).thenReturn('Error loading profile');
    when(mockProfileProvider.profile).thenReturn(null);

    await TestHelper.pumpWidgetWithProviders(
      tester,
      const ProfileScreen(),
      profileProvider: mockProfileProvider,
    );

    expect(find.text('Error loading profile'), findsOneWidget);
  });

  testWidgets('displays profile information when loaded', (tester) async {
    const profile = UserProfile(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      avatar: 'https://example.com/avatar.jpg',
    );

    when(mockProfileProvider.isLoading).thenReturn(false);
    when(mockProfileProvider.error).thenReturn(null);
    when(mockProfileProvider.profile).thenReturn(profile);

    await TestHelper.pumpWidgetWithProviders(
      tester,
      const ProfileScreen(),
      profileProvider: mockProfileProvider,
    );

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
  });
}
