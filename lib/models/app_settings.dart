import 'package:hive_ce_flutter/hive_flutter.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings {
  const AppSettings({this.themeModeKey = 'system'});

  @HiveField(0)
  final String themeModeKey;

  AppSettings copyWith({String? themeModeKey}) {
    return AppSettings(themeModeKey: themeModeKey ?? this.themeModeKey);
  }
}
