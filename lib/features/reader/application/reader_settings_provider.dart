import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReaderSettings {
  final double fontSize;
  final double lineSpacing;
  final double margin;

  const ReaderSettings({
    this.fontSize = 18.0,
    this.lineSpacing = 1.5,
    this.margin = 16.0,
  });

  ReaderSettings copyWith({
    double? fontSize,
    double? lineSpacing,
    double? margin,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      margin: margin ?? this.margin,
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
