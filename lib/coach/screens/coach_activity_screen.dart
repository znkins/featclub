import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/services/completed_session_service.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/providers/data_providers.dart';
import '../../theme/app_spacing.dart';
import '../widgets/activity_list_tile.dart';

/// Page Activité coach : feed des dernières séances complétées par tous
/// ses élèves. Pagination cursor-based (curseur = `completed_at`) + scroll
/// infini : 1ère page chargée en `initState`, suivantes au scroll.
class CoachActivityScreen extends ConsumerStatefulWidget {
  const CoachActivityScreen({super.key});

  @override
  ConsumerState<CoachActivityScreen> createState() =>
      _CoachActivityScreenState();
}

class _CoachActivityScreenState extends ConsumerState<CoachActivityScreen> {
  static const int _pageSize = 30;
  static const double _loadMoreThreshold = 300;

  final ScrollController _scrollController = ScrollController();
  final List<RecentActivityItem> _items = [];
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThreshold) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    try {
      final service = ref.read(completedSessionServiceProvider);
      final page = await service.listRecentWithStudent(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page);
        _hasMore = page.length == _pageSize;
        _initialLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _error = e;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_items.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final service = ref.read(completedSessionServiceProvider);
      final page = await service.listRecentWithStudent(
        limit: _pageSize,
        before: _items.last.completion.completedAt,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length == _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      // Échec silencieux : on garde l'écran déjà rempli, le prochain
      // scroll réessaiera.
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _hasMore = true;
      _initialLoading = true;
      _error = null;
    });
    await _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activité')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initialLoading) return const LoadingIndicator();
    if (_error != null) {
      return ErrorView(
        message: 'Impossible de charger l\'activité.\n$_error',
        onRetry: _refresh,
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: AppSpacing.xxl * 2),
            EmptyView(
              icon: LucideIcons.calendarCheck,
              wrapIcon: true,
              message:
                  'Aucune séance terminée pour le moment.\nLe feed se remplira au fil des complétions.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        // +1 pour le sentinel de bas de liste (loader ou rien).
        itemCount: _items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) {
          if (i == _items.length) return _BottomSentinel(loading: _loadingMore);
          return ActivityListTile(item: _items[i]);
        },
      ),
    );
  }
}

class _BottomSentinel extends StatelessWidget {
  const _BottomSentinel({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (!loading) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
