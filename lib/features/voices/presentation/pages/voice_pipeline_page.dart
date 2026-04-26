import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../domain/voice_folder.dart';
import '../../domain/voice_job.dart';
import '../widgets/voice_job_list_card.dart';

/// 폴더(가로 스크롤) → 폴더 안 음성 목록
class VoicePipelinePage extends StatefulWidget {
  const VoicePipelinePage({
    super.key,
    required this.jobs,
    required this.folders,
    required this.onUploadTap,
    required this.onOpenFolderManage,
    required this.onRefreshScope,
    required this.onAdvanceDemo,
    required this.onDeleteJob,
    required this.onMoveJob,
    required this.onListenTap,
  });

  final List<VoiceJob> jobs;
  final List<VoiceFolder> folders;

  /// 폴더 안에서 올릴 때는 해당 폴더 id를 넘김. `모든 음성` 화면에서는 null.
  final Future<void> Function([String? initialFolderId]) onUploadTap;

  final Future<void> Function([String? currentFolderId]) onOpenFolderManage;
  final Future<void> Function([String? folderId]) onRefreshScope;
  final void Function(String id) onAdvanceDemo;
  final void Function(String id) onDeleteJob;
  final void Function(String jobId, String folderId) onMoveJob;

  /// 카드 탭 시 듣기 화면으로 (완료 여부는 콜백 안에서 처리)
  final void Function(VoiceJob job) onListenTap;

  @override
  State<VoicePipelinePage> createState() => _VoicePipelinePageState();
}

class _VoicePipelinePageState extends State<VoicePipelinePage> {
  static const String _scopeAll = '__scope_all__';

  final _searchController = TextEditingController();
  VoiceJobListSort _sort = VoiceJobListSort.newest;
  bool _refreshingScope = false;

  /// null이면 출처 전체
  VoiceOrigin? _originFilter;

  /// null: 폴더만 보기(루트) · [_scopeAll]: 전체 목록 · 그 외: 해당 폴더
  String? _scope;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _folderName(String folderId) {
    return _folderById(folderId)?.name ?? '폴더';
  }

  VoiceFolder? _folderById(String folderId) {
    for (final folder in widget.folders) {
      if (folder.id == folderId) return folder;
    }
    return null;
  }

  List<VoiceFolder> _sortedFoldersForParent(String? parentId) {
    final list = widget.folders.where((f) => f.parentId == parentId).toList();
    list.sort((a, b) {
      if (a.id == VoiceFolder.uncategorizedId) return -1;
      if (b.id == VoiceFolder.uncategorizedId) return 1;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  List<VoiceFolder> get _rootFolders => _sortedFoldersForParent(null);

  List<VoiceFolder> _childFoldersInScope() {
    if (_scope == null || _scope == _scopeAll) return const <VoiceFolder>[];
    return _sortedFoldersForParent(_scope);
  }

  int _countInFolder(String folderId) {
    return widget.jobs.where((j) => j.folderId == folderId).length;
  }

  List<VoiceJob> _jobsInScope() {
    if (_scope == null) return [];
    if (_scope == _scopeAll) return List<VoiceJob>.from(widget.jobs);
    return widget.jobs.where((j) => j.folderId == _scope).toList();
  }

  List<VoiceJob> _baseFiltered() {
    var list = _jobsInScope();
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((j) => j.fileName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  /// 검색·폴더 범위 + 출처 필터
  List<VoiceJob> _jobsAfterFilters() {
    var list = _baseFiltered();
    if (_originFilter != null) {
      list = list.where((j) => j.origin == _originFilter).toList();
    }
    return list;
  }

  List<VoiceJob> _visibleJobs() {
    var list = List<VoiceJob>.from(_jobsAfterFilters());
    switch (_sort) {
      case VoiceJobListSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case VoiceJobListSort.nameAsc:
        list.sort(
          (a, b) =>
              a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()),
        );
        break;
    }
    return list;
  }

  int _countForOrigin(VoiceOrigin? o) {
    final base = _baseFiltered();
    if (o == null) return base.length;
    return base.where((j) => j.origin == o).length;
  }

  String _scopeTitle() {
    if (_scope == null) return '';
    if (_scope == _scopeAll) return '모든 음성';
    return _folderPath(_scope!);
  }

  bool get _showFolderOnCards => _scope == _scopeAll;

  int get _childFolderCountInScope => _childFoldersInScope().length;

  String _scopeSummary() {
    if (_scope == null) return '';
    if (_scope == _scopeAll) return '${widget.jobs.length}개';
    return '하위 폴더 $_childFolderCountInScope개 · 음성 ${_jobsInScope().length}개';
  }

  Future<void> _openFolder(String folderId) async {
    await _changeScope(folderId);
  }

  Future<void> _goBackScope() async {
    if (_scope == null) return;
    if (_scope == _scopeAll) {
      await _changeScope(null);
      return;
    }
    final parentId = _folderById(_scope!)?.parentId;
    await _changeScope(parentId);
  }

  Future<void> _changeScope(String? nextScope) async {
    setState(() => _scope = nextScope);
    await _refreshCurrentScope();
  }

  Future<void> _refreshCurrentScope() async {
    final targetScope = _scope;
    if (targetScope == _scopeAll ||
        targetScope == VoiceFolder.uncategorizedId) {
      return;
    }
    if (!mounted) return;
    setState(() => _refreshingScope = true);
    try {
      await widget.onRefreshScope(targetScope);
    } finally {
      if (mounted) setState(() => _refreshingScope = false);
    }
  }

  String _folderPath(String folderId) {
    final parts = <String>[];
    final seen = <String>{};
    var currentId = folderId;
    while (seen.add(currentId)) {
      final folder = _folderById(currentId);
      if (folder == null) break;
      parts.add(folder.name);
      final parentId = folder.parentId;
      if (parentId == null) break;
      currentId = parentId;
    }
    return parts.reversed.join(' / ');
  }

  String _folderRowSubtitle(String folderId) {
    final childCount = _sortedFoldersForParent(folderId).length;
    final voiceCount = _countInFolder(folderId);
    if (childCount > 0) {
      return '하위 폴더 $childCount개 · 음성 $voiceCount개';
    }
    return '음성 $voiceCount개';
  }

  Future<void> _showMoveSheet(VoiceJob job) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '옮길 폴더',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...widget.folders.map(
                  (f) => ListTile(
                    title: Text(
                      f.isUncategorized ? '${f.name} (기본)' : _folderPath(f.id),
                    ),
                    trailing: job.folderId == f.id
                        ? const Icon(Icons.check, color: YeolpumtaTheme.accent)
                        : null,
                    onTap: () => Navigator.pop(ctx, f.id),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (id != null && id != job.folderId) {
      widget.onMoveJob(job.id, id);
    }
  }

  Future<void> _handleUploadInScope() {
    if (_scope == null) return Future.value();
    if (_scope == _scopeAll) {
      return widget.onUploadTap();
    }
    return widget.onUploadTap(_scope);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleJobs();
    final childFolders = _childFoldersInScope();

    return PopScope(
      canPop: _scope == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _scope != null) {
          _goBackScope();
        }
      },
      child: Scaffold(
        backgroundColor: YeolpumtaTheme.bg,
        body: RefreshIndicator(
          onRefresh: _refreshCurrentScope,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: _scope == null
                      ? _buildFolderBrowserHeader()
                      : _buildListHeader(),
                ),
              ),
              if (_refreshingScope)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                ),
              if (_scope == null) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  sliver: SliverList.separated(
                    itemCount: 1 + _rootFolders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return _FolderListRow(
                          icon: Icons.layers_rounded,
                          title: '모든 음성',
                          subtitle: '음성 ${widget.jobs.length}개',
                          accent: true,
                          onTap: () => _openFolder(_scopeAll),
                        );
                      }
                      final f = _rootFolders[i - 1];
                      return _FolderListRow(
                        icon: Icons.folder_rounded,
                        title: f.name,
                        subtitle: _folderRowSubtitle(f.id),
                        accent: false,
                        onTap: () => _openFolder(f.id),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 48),
                    child: _RootHint(),
                  ),
                ),
              ] else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: _handleUploadInScope,
                          icon: const Icon(Icons.upload_rounded, size: 20),
                          label: Text(
                            _scope == _scopeAll ? '음성 올리기' : '이 폴더에 올리기',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: YeolpumtaTheme.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (childFolders.isNotEmpty && _scope != _scopeAll) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '하위 폴더',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: YeolpumtaTheme.textSecondary.withValues(
                                  alpha: 0.88,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...childFolders.map(
                            (folder) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FolderListRow(
                                icon: Icons.folder_rounded,
                                title: folder.name,
                                subtitle: _folderRowSubtitle(folder.id),
                                accent: false,
                                onTap: () => _openFolder(folder.id),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 15,
                            color: YeolpumtaTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: '파일명 검색',
                            hintStyle: const TextStyle(
                              color: YeolpumtaTheme.textSecondary,
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: YeolpumtaTheme.textSecondary,
                              size: 22,
                            ),
                            filled: true,
                            fillColor: YeolpumtaTheme.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: YeolpumtaTheme.divider,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: YeolpumtaTheme.divider,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: YeolpumtaTheme.accent,
                                width: 1.2,
                              ),
                            ),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: PopupMenuButton<VoiceJobListSort>(
                            tooltip: '정렬',
                            initialValue: _sort,
                            onSelected: (v) => setState(() => _sort = v),
                            itemBuilder: (context) => VoiceJobListSort.values
                                .map(
                                  (s) => PopupMenuItem(
                                    value: s,
                                    child: Row(
                                      children: [
                                        if (_sort == s)
                                          const Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                            color: YeolpumtaTheme.accent,
                                          )
                                        else
                                          const SizedBox(width: 18),
                                        const SizedBox(width: 8),
                                        Text(s.label),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.sort_rounded,
                                color: YeolpumtaTheme.textSecondary,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '출처',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: YeolpumtaTheme.textSecondary.withValues(
                                alpha: 0.88,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  avatar: Icon(
                                    Icons.filter_list_rounded,
                                    size: 16,
                                    color: _originFilter == null
                                        ? YeolpumtaTheme.accent
                                        : YeolpumtaTheme.textSecondary,
                                  ),
                                  label: Text(
                                    '전체 (${_countForOrigin(null)})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: _originFilter == null
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _originFilter == null
                                          ? YeolpumtaTheme.accent
                                          : YeolpumtaTheme.textSecondary,
                                    ),
                                  ),
                                  selected: _originFilter == null,
                                  onSelected: (_) =>
                                      setState(() => _originFilter = null),
                                  showCheckmark: false,
                                  backgroundColor: YeolpumtaTheme.surface,
                                  selectedColor: YeolpumtaTheme.accentSoft,
                                  side: const BorderSide(
                                    color: YeolpumtaTheme.divider,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                ),
                              ),
                              for (final o in VoiceOrigin.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    avatar: Icon(
                                      VoiceOriginStyle.of(o).icon,
                                      size: 15,
                                      color: _originFilter == o
                                          ? VoiceOriginStyle.of(o).accent
                                          : YeolpumtaTheme.textSecondary,
                                    ),
                                    label: Text(
                                      '${o.label} (${_countForOrigin(o)})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _originFilter == o
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _originFilter == o
                                            ? VoiceOriginStyle.of(o).accent
                                            : YeolpumtaTheme.textSecondary,
                                      ),
                                    ),
                                    selected: _originFilter == o,
                                    onSelected: (_) =>
                                        setState(() => _originFilter = o),
                                    showCheckmark: false,
                                    backgroundColor: YeolpumtaTheme.surface,
                                    selectedColor: VoiceOriginStyle.of(o).tint,
                                    side: BorderSide(
                                      color: _originFilter == o
                                          ? VoiceOriginStyle.of(
                                              o,
                                            ).accent.withValues(alpha: 0.35)
                                          : YeolpumtaTheme.divider,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (visible.isEmpty && childFolders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _jobsInScope().isEmpty
                                  ? (_scope == _scopeAll
                                        ? '아직 올린 파일이 없어요'
                                        : '이 폴더에 음성이 없어요')
                                  : '조건에 맞는 파일이 없어요',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: YeolpumtaTheme.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                            if (_jobsInScope().isEmpty) ...[
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _handleUploadInScope,
                                style: FilledButton.styleFrom(
                                  backgroundColor: YeolpumtaTheme.accent,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('지금 올리기'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else if (visible.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final j = visible[i];
                        return VoiceJobListCard(
                          job: j,
                          folderLabel: _folderName(j.folderId),
                          showFolderLine: _showFolderOnCards,
                          onAdvance: () => widget.onAdvanceDemo(j.id),
                          onDelete: () => widget.onDeleteJob(j.id),
                          onMove: () => _showMoveSheet(j),
                          onCardTap: () => widget.onListenTap(j),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderBrowserHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '음성',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: YeolpumtaTheme.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '폴더를 골라 들어가면 그 안에서 파일을 올리고 상태를 볼 수 있어요.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => widget.onOpenFolderManage(),
              icon: const Icon(Icons.tune_rounded),
              tooltip: '폴더 관리',
              style: IconButton.styleFrom(
                backgroundColor: YeolpumtaTheme.surface,
                foregroundColor: YeolpumtaTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _goBackScope,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: YeolpumtaTheme.textPrimary,
              tooltip: '폴더 목록',
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _scopeTitle(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: YeolpumtaTheme.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _scopeSummary(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => widget.onOpenFolderManage(
                _scope == _scopeAll ? null : _scope,
              ),
              icon: const Icon(Icons.folder_outlined),
              color: YeolpumtaTheme.textSecondary,
              tooltip: '폴더 관리',
            ),
          ],
        ),
      ],
    );
  }
}

class _RootHint extends StatelessWidget {
  const _RootHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 44,
            color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 12),
          Text(
            '폴더를 눌러 들어가면\n파일을 올리고 상태를 볼 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

/// 세로 목록용 — 한 줄 전체 너비
class _FolderListRow extends StatelessWidget {
  const _FolderListRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? YeolpumtaTheme.accentSoft : YeolpumtaTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent
                      ? YeolpumtaTheme.accent.withValues(alpha: 0.12)
                      : YeolpumtaTheme.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: accent
                      ? YeolpumtaTheme.accent
                      : YeolpumtaTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: YeolpumtaTheme.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: YeolpumtaTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.7),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
