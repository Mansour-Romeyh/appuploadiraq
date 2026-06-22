import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../theme/app_colors.dart';

/// Renders a backend list with loading / error+retry / empty / content states.
///
/// The [load] callback returns a (memoized) future from `ContentService`, so an
/// already-resolved feed paints its content on the first frame with no flash.
/// On failure the user gets a Retry button that calls [onRetry] (clearing the
/// memo) and re-issues the request.
class RemoteBuilder<T> extends StatefulWidget {
  final Future<List<T>> Function() load;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, List<T> data) builder;

  /// Shown (centered) when the fetch succeeds but returns no rows.
  final String? emptyText;

  const RemoteBuilder({
    super.key,
    required this.load,
    required this.onRetry,
    required this.builder,
    this.emptyText,
  });

  @override
  State<RemoteBuilder<T>> createState() => _RemoteBuilderState<T>();
}

class _RemoteBuilderState<T> extends State<RemoteBuilder<T>> {
  late Future<List<T>> _future = widget.load();

  void _retry() {
    widget.onRetry();
    setState(() => _future = widget.load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          );
        }
        if (snap.hasError) {
          return _ErrorState(onRetry: _retry);
        }
        final data = snap.data ?? const [];
        if (data.isEmpty && widget.emptyText != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                widget.emptyText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          );
        }
        return widget.builder(context, data);
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              t('components.error.unexpected'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.gold),
              label: Text(
                t('components.error.retry'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
