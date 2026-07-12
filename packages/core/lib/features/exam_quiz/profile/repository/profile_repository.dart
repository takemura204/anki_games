import 'dart:convert';

import 'package:core/features/exam_quiz/profile/model/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileRepository {
  static const _key = 'user_profile_v1';

  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const UserProfile();
    try {
      return UserProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } on Object {
      return const UserProfile();
    }
  }

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }
}
