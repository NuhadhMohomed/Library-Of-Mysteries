import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/reader_settings_provider.dart';

class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerSettingsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Typography Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          _buildSlider(
            context,
            label: 'Font Size (\${settings.fontSize.toInt()}px)',
            value: settings.fontSize,
            min: 16.0,
            max: 32.0,
            onChanged: (val) {
              ref.read(readerSettingsProvider.notifier)
                  .updateSettings(settings.copyWith(fontSize: val));
            },
          ),
          _buildSlider(
            context,
            label: 'Line Spacing (\${settings.lineSpacing.toStringAsFixed(1)})',
            value: settings.lineSpacing,
            min: 1.0,
            max: 2.5,
            onChanged: (val) {
              ref.read(readerSettingsProvider.notifier)
                  .updateSettings(settings.copyWith(lineSpacing: val));
            },
          ),
          _buildSlider(
            context,
            label: 'Margins (\${settings.margin.toInt()}px)',
            value: settings.margin,
            min: 8.0,
            max: 64.0,
            onChanged: (val) {
              ref.read(readerSettingsProvider.notifier)
                  .updateSettings(settings.copyWith(margin: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
