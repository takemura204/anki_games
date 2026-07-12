enum Gender {
  male,
  female,
  other,
  noAnswer;

  String get label => switch (this) {
        Gender.male => '男性',
        Gender.female => '女性',
        Gender.other => 'その他',
        Gender.noAnswer => '無回答',
      };
}

enum AgeRange {
  y13_17,
  y18_24,
  y25_34,
  y35_44,
  y45_54,
  y55plus;

  String get label => switch (this) {
        AgeRange.y13_17 => '13〜17歳',
        AgeRange.y18_24 => '18〜24歳',
        AgeRange.y25_34 => '25〜34歳',
        AgeRange.y35_44 => '35〜44歳',
        AgeRange.y45_54 => '45〜54歳',
        AgeRange.y55plus => '55歳以上',
      };

  static AgeRange? fromValue(String? v) =>
      AgeRange.values.where((e) => e.name == v).firstOrNull;
}

class UserProfile {
  const UserProfile({
    this.displayName,
    this.gender,
    this.ageRange,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        displayName: json['displayName'] as String?,
        gender: Gender.values
            .where((e) => e.name == json['gender'])
            .firstOrNull,
        ageRange: AgeRange.fromValue(json['ageRange'] as String?),
      );

  final String? displayName;
  final Gender? gender;
  final AgeRange? ageRange;

  UserProfile copyWith({
    String? displayName,
    Gender? gender,
    AgeRange? ageRange,
  }) =>
      UserProfile(
        displayName: displayName ?? this.displayName,
        gender: gender ?? this.gender,
        ageRange: ageRange ?? this.ageRange,
      );

  Map<String, dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName,
        if (gender != null) 'gender': gender!.name,
        if (ageRange != null) 'ageRange': ageRange!.name,
      };
}
