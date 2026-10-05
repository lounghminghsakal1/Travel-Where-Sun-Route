import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../injection.dart';
import '../../../route_input/presentation/providers/route_input_provider.dart';
import '../../../seat_scoring/domain/entities/vehicle_layout.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const SectionHeader(
                title: 'API keys',
                subtitle: 'Keys typed here override the bundled .env file',
              ),
              _ApiKeyTile(
                title: 'Google Maps Platform',
                purpose: 'Place search (Places API New) · Routes API when enabled. '
                    'The map itself uses the key from .env, baked in at build time.',
                envValue: Env.googleMapsKey,
                customValue: settings.googleKeyOverride,
                onSave: notifier.setGoogleKey,
                test: (dio, key) => dio.post(
                  ApiConstants.placesAutocomplete,
                  data: {'input': 'Lon'},
                  options: Options(headers: {'X-Goog-Api-Key': key}),
                ),
                service: 'Google',
              ),
              const SizedBox(height: 10),
              _ApiKeyTile(
                title: 'OpenWeatherMap',
                purpose: '5 day / 3 hour forecast along the route',
                envValue: Env.openWeatherKey,
                customValue: settings.weatherKeyOverride,
                onSave: notifier.setWeatherKey,
                test: (dio, key) => dio.get(
                  ApiConstants.owmForecast,
                  queryParameters: {'lat': 12.97, 'lon': 77.59, 'cnt': 1, 'appid': key},
                ),
                service: 'OpenWeather',
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'Driver position',
                subtitle: 'Sets which front seat is the passenger seat and the bus door side',
              ),
              SegmentedButton<DriverPosition>(
                segments: const [
                  ButtonSegment(
                    value: DriverPosition.right,
                    label: Text('Right-hand drive'),
                    icon: Icon(Icons.format_align_right_rounded),
                  ),
                  ButtonSegment(
                    value: DriverPosition.left,
                    label: Text('Left-hand drive'),
                    icon: Icon(Icons.format_align_left_rounded),
                  ),
                ],
                selected: {settings.driverPosition},
                onSelectionChanged: (s) => notifier.setDriverPosition(s.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 6),
              Text(
                'Right-hand drive: India, UK, Japan, Australia… Left-hand drive: US, Europe, Middle East…',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Data'),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud_sync_outlined),
                      title: const Text('Clear weather cache'),
                      subtitle: const Text('Forecasts are cached for an hour'),
                      onTap: () async {
                        await ref.read(weatherRepositoryImplProvider).clearCache();
                        if (context.mounted) _toast(context, 'Weather cache cleared');
                      },
                    ),
                    const Divider(indent: 56),
                    ListTile(
                      leading: const Icon(Icons.history_toggle_off_rounded),
                      title: const Text('Clear recent searches'),
                      onTap: () async {
                        await ref.read(recentTripsProvider.notifier).clear();
                        if (context.mounted) _toast(context, 'Recent searches cleared');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'About'),
              GlassCard(
                child: Text(
                  'SunRoute computes the sun\'s position on device (NOAA solar algorithm), '
                  'samples your route about once a minute and scores every seat on sun '
                  'exposure, ventilation and comfort.\n\n'
                  'Routes: Google Routes API when enabled for your key, otherwise OSRM '
                  '(OpenStreetMap data). Maps: Google Maps on Android and iOS, '
                  'OpenStreetMap elsewhere (© OpenStreetMap contributors). '
                  'Weather © OpenWeather.',
                  style: AppTextStyles.bodySecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

enum _TestState { idle, running, ok, failed }

class _ApiKeyTile extends ConsumerStatefulWidget {
  const _ApiKeyTile({
    required this.title,
    required this.purpose,
    required this.envValue,
    required this.customValue,
    required this.onSave,
    required this.test,
    required this.service,
  });

  final String title;
  final String purpose;
  final String envValue;
  final String customValue;
  final Future<void> Function(String) onSave;
  final Future<Response<dynamic>> Function(Dio dio, String key) test;
  final String service;

  @override
  ConsumerState<_ApiKeyTile> createState() => _ApiKeyTileState();
}

class _ApiKeyTileState extends ConsumerState<_ApiKeyTile> {
  _TestState _state = _TestState.idle;
  String? _message;

  String get _effective => widget.customValue.isNotEmpty ? widget.customValue : widget.envValue;

  String _mask(String key) {
    if (key.isEmpty) return 'Not set';
    if (key.length <= 8) return '•' * key.length;
    return '${key.substring(0, 4)}••••••••${key.substring(key.length - 4)}';
  }

  Future<void> _runTest() async {
    setState(() {
      _state = _TestState.running;
      _message = null;
    });
    try {
      await widget.test(ref.read(dioProvider), _effective);
      if (mounted) setState(() => _state = _TestState.ok);
    } catch (e) {
      if (!mounted) return;
      final failure = mapErrorToFailure(e, service: widget.service);
      setState(() {
        _state = _TestState.failed;
        _message = failure.message;
      });
    }
  }

  Future<void> _edit() async {
    final controller = TextEditingController(text: widget.customValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Paste API key (leave empty to use .env)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null) {
      await widget.onSave(result);
      if (mounted) setState(() => _state = _TestState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.customValue.isNotEmpty ? 'Custom' : (widget.envValue.isNotEmpty ? 'From .env' : 'Missing');
    final (statusIcon, statusColor) = switch (_state) {
      _TestState.ok => (Icons.check_circle_rounded, AppColors.accentCool),
      _TestState.failed => (Icons.error_rounded, AppColors.accentHot),
      _ => (null, AppColors.textMuted),
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.title, style: AppTextStyles.title)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(8)),
                child: Text(source, style: AppTextStyles.caption.copyWith(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(widget.purpose, style: AppTextStyles.caption),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _mask(_effective),
                  style: AppTextStyles.body.copyWith(fontFamily: 'monospace', letterSpacing: 0.5),
                ),
              ),
              if (statusIcon != null) Icon(statusIcon, size: 20, color: statusColor),
              const SizedBox(width: 4),
              TextButton(
                onPressed: _effective.isEmpty || _state == _TestState.running ? null : _runTest,
                child: _state == _TestState.running
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Test'),
              ),
              TextButton(onPressed: _edit, child: const Text('Edit')),
            ],
          ),
          if (_message != null)
            Text(_message!, style: AppTextStyles.caption.copyWith(color: AppColors.accentHot)),
        ],
      ),
    );
  }
}
