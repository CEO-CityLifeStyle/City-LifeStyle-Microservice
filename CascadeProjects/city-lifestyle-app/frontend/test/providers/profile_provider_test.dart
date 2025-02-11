import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/config/api_config.dart';

import 'profile_provider_test.mocks.dart';

@GenerateMocks([http.Client, SharedPreferences])
void main() {
  late ProfileProvider profileProvider;
  late MockClient mockClient;
  late MockSharedPreferences mockPrefs;
  late User testUser;

  setUp(() {
    mockClient = MockClient();
    mockPrefs = MockSharedPreferences();
    testUser = User(
      id: '1',
      name: 'Test User',
      email: 'test@example.com',
      bio: 'Test bio',
    );

    profileProvider = ProfileProvider('test-token', testUser);
  });

  group('ProfileProvider Tests', () {
    test('initial state is correct', () {
      expect(profileProvider.profile, equals(testUser));
      expect(profileProvider.isLoading, isFalse);
      expect(profileProvider.isSyncing, isFalse);
    });

    test('fetchProfile updates state correctly', () async {
      final responseData = {
        'id': '1',
        'name': 'Updated User',
        'email': 'test@example.com',
        'bio': 'Updated bio',
      };

      when(mockClient.get(
        Uri.parse('${ApiConfig.baseUrl}/profile'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async =>
          http.Response(json.encode(responseData), 200));

      await profileProvider.fetchProfile();

      expect(profileProvider.profile?.name, equals('Updated User'));
      expect(profileProvider.profile?.bio, equals('Updated bio'));
    });

    test('updateProfile handles offline mode correctly', () async {
      final updates = {
        'name': 'Offline Update',
        'bio': 'Updated while offline',
      };

      // Simulate offline mode
      when(mockClient.put(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenThrow(const SocketException('No internet connection'));

      await profileProvider.updateProfile(updates);

      // Check that local state was updated optimistically
      expect(profileProvider.profile?.name, equals('Offline Update'));
      expect(profileProvider.profile?.bio, equals('Updated while offline'));
    });

    test('updateAvatar handles success case', () async {
      final mockFile = File('test.jpg');
      final responseData = {
        'id': '1',
        'name': 'Test User',
        'email': 'test@example.com',
        'avatar': {
          'thumbnail': 'thumbnail-url',
          'medium': 'medium-url',
          'large': 'large-url',
        },
      };

      when(mockClient.send(any)).thenAnswer((_) async =>
          http.StreamedResponse(Stream.value([]), 200));

      when(mockClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async =>
          http.Response(json.encode(responseData), 200));

      await profileProvider.updateAvatar(mockFile);

      expect(profileProvider.profile?.avatar?['thumbnail'],
          equals('thumbnail-url'));
    });

    test('privacy settings are updated correctly', () async {
      final settings = {
        'profileVisibility': 'private',
        'activityVisibility': 'friends',
        'emailVisibility': 'private',
      };

      when(mockClient.put(
        Uri.parse('${ApiConfig.baseUrl}/profile/privacy'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async =>
          http.Response(json.encode(settings), 200));

      await profileProvider.updatePrivacySettings(settings);

      expect(profileProvider.profile?.privacy, equals(settings));
    });

    test('cached profile is loaded on init', () async {
      final cachedData = {
        'id': '1',
        'name': 'Cached User',
        'email': 'cached@example.com',
      };

      when(mockPrefs.getString('cached_profile'))
          .thenReturn(json.encode(cachedData));

      final provider = ProfileProvider('test-token', null);
      await Future.delayed(Duration.zero); // Wait for async init

      expect(provider.profile?.name, equals('Cached User'));
    });

    test('pending changes are synced when online', () async {
      final updates1 = {'name': 'Update 1'};
      final updates2 = {'bio': 'Update 2'};

      // Simulate offline updates
      when(mockClient.put(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenThrow(const SocketException('No internet connection'));

      await profileProvider.updateProfile(updates1);
      await profileProvider.updateProfile(updates2);

      // Simulate coming online
      when(mockClient.put(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{}', 200));

      await profileProvider.syncPendingChanges();

      verify(mockClient.put(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(2);
    });
  });
}
