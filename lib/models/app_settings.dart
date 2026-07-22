import 'package:hive_ce_flutter/hive_flutter.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings {
  const AppSettings({this.themeModeKey = 'system', this.displayName});

  @HiveField(0)
  final String themeModeKey;

  // Legacy field. User names are now stored in Firebase Authentication.
  // Do not reuse Hive field number 1.
  @HiveField(1)
  final String? displayName;

  AppSettings copyWith({String? themeModeKey, String? displayName}) {
    return AppSettings(
      themeModeKey: themeModeKey ?? this.themeModeKey,
      displayName: displayName ?? this.displayName,
    );
  }
}
