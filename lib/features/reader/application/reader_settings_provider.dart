import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReaderTheme { light, sepia, dark, amoled }

class ReaderSettings {
  final double fontSize;
  final double lineSpacing;
  final double margin;
  final ReaderTheme theme;

  const ReaderSettings({
    this.fontSize = 18.0,
    this.lineSpacing = 1.5,
    this.margin = 16.0,
    this.theme = ReaderTheme.light,
  });

  ReaderSettings copyWith({
    double? fontSize,
    double? lineSpacing,
    double? margin,
    ReaderTheme? theme,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      margin: margin ?? this.margin,
      theme: theme ?? this.theme,
    );
  }
}

class ReaderSettingsNotifier extends Notifier<ReaderSettings> {
  @override
  ReaderSettings build() {
    return const ReaderSettings();
  }

  void updateSettings(ReaderSettings newSettings) {
    state = newSettings;
  }
}

final readerSettingsProvider = NotifierProvider<ReaderSettingsNotifier, ReaderSettings>(() {
  return ReaderSettingsNotifier();
});
