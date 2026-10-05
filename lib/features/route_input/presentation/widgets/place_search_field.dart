import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../injection.dart';
import '../../domain/entities/place.dart';
import '../providers/route_input_provider.dart';

/// One row of the From/To card.
class PlaceField extends StatelessWidget {
  const PlaceField({
    super.key,
    required this.label,
    required this.hint,
    required this.leading,
    required this.place,
    required this.onTap,
  });

  final String label;
  final String hint;
  final Widget leading;
  final Place? place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: ${place?.name ?? hint}',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 64, 14),
          child: Row(
            children: [
              SizedBox(width: 24, child: Center(child: leading)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(), style: AppTextStyles.overline),
                    const SizedBox(height: 3),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        place?.name ?? hint,
                        key: ValueKey(place?.id ?? hint),
                        style: place == null
                            ? AppTextStyles.title.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w500)
                            : AppTextStyles.title.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (place != null && place!.address.isNotEmpty && place!.address != place!.name)
                      Text(
                        place!.address,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-height search sheet backed by Google Places (New) autocomplete.
Future<Place?> showPlaceSearch(BuildContext context, {required String title}) {
  return showModalBottomSheet<Place>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.94,
      child: _PlaceSearchSheet(title: title),
    ),
  );
}

class _PlaceSearchSheet extends ConsumerStatefulWidget {
  const _PlaceSearchSheet({required this.title});
  final String title;

  @override
  ConsumerState<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends ConsumerState<_PlaceSearchSheet> {
  final _controller = TextEditingController();
  final _sessionToken = _uuidV4();
  Timer? _debounce;
  int _request = 0;
  bool _loading = false;
  Failure? _failure;
  String? _resolving;
  List<PlaceSuggestion> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    setState(() {});
    if (q.trim().length < 2) {
      _request++;
      setState(() {
        _results = const [];
        _loading = false;
        _failure = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () => _search(q));
  }

  Future<void> _search(String q) async {
    final id = ++_request;
    setState(() {
      _loading = true;
      _failure = null;
    });
    final result = await ref.read(searchPlacesProvider)(q, _sessionToken);
    if (!mounted || id != _request) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok(:final value):
          _results = value;
        case Err(:final failure):
          _failure = failure;
          _results = const [];
      }
    });
  }

  Future<void> _pickSuggestion(PlaceSuggestion s) async {
    HapticFeedback.selectionClick();
    setState(() => _resolving = s.placeId);
    final result = await ref.read(getPlaceDetailsProvider)(s.placeId, _sessionToken);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        final place = Place(
          id: value.id,
          name: value.name.isNotEmpty ? value.name : s.primaryText,
          address: value.address.isNotEmpty ? value.address : s.secondaryText,
          location: value.location,
        );
        await ref.read(recentPlacesProvider.notifier).add(place);
        if (mounted) Navigator.of(context).pop(place);
      case Err(:final failure):
        setState(() {
          _resolving = null;
          _failure = failure;
        });
    }
  }

  void _pickPlace(Place p) {
    HapticFeedback.selectionClick();
    ref.read(recentPlacesProvider.notifier).add(p);
    Navigator.of(context).pop(p);
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final recents = ref.watch(recentPlacesProvider);
    final popular = {
      for (final t in sampleTrips) ...[t.origin, t.destination],
    }.toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
            child: Row(
              children: [
                Expanded(child: Text(widget.title, style: AppTextStyles.h1)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.body.copyWith(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search a city, station or address',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 20, color: AppColors.textMuted),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _body(query, recents, popular)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Place search powered by Google',
              style: AppTextStyles.caption.copyWith(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(String query, List<Place> recents, List<Place> popular) {
    if (_failure != null) return _ErrorBlock(failure: _failure!, onRetry: () => _search(query));

    if (query.length < 2) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (recents.isNotEmpty) ...[
            _ListHeader('Recent'),
            for (final p in recents)
              _ResultTile(
                icon: Icons.history_rounded,
                title: p.name,
                subtitle: p.address,
                onTap: () => _pickPlace(p),
              ),
          ],
          _ListHeader('Popular'),
          for (final p in popular)
            _ResultTile(
              icon: Icons.location_city_rounded,
              title: p.name,
              subtitle: p.address,
              onTap: () => _pickPlace(p),
            ),
        ],
      );
    }

    if (_loading && _results.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (var i = 0; i < 5; i++) ...[
            const ShimmerBox(height: 52),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.travel_explore_rounded, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No places match "$query"', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final s = _results[i];
        return _ResultTile(
          icon: Icons.place_outlined,
          title: s.primaryText,
          subtitle: s.secondaryText,
          busy: _resolving == s.placeId,
          onTap: _resolving == null ? () => _pickSuggestion(s) : null,
        );
      },
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
        child: Text(text.toUpperCase(), style: AppTextStyles.overline),
      );
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
      title: Text(title, style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: busy
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.north_west_rounded, size: 16, color: AppColors.textMuted),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.failure, required this.onRetry});
  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isKey = failure is ApiKeyFailure;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isKey ? Icons.key_off_rounded : Icons.wifi_off_rounded, size: 40, color: AppColors.accentHot),
          const SizedBox(height: 12),
          Text(failure.title, style: AppTextStyles.title, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(failure.message, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          if (isKey)
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/settings');
              },
              child: const Text('Open settings'),
            )
          else
            FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

String _uuidV4() {
  final r = math.Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int i) => b[i].toRadixString(16).padLeft(2, '0');
  final s = List.generate(16, hex).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}
