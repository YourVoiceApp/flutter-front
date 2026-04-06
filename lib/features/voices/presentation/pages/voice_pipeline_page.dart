import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../domain/voice_folder.dart';
import '../../domain/voice_job.dart';

/// 폴더(가로 스크롤) → 폴더 안 음성 목록 → 학습 상태
class VoicePipelinePage extends StatefulWidget {
  const VoicePipelinePage({
    super.key,
    required this.jobs,
    required this.folders,
    required this.onUploadTap,
    required this.onOpenFolderManage,
    required this.onAdvanceDemo,
    required this.onDeleteJob,
    required this.onMoveJob,
  });

  final List<VoiceJob> jobs;
  final List<VoiceFolder> folders;

  /// 폴더 안에서 올릴 때는 해당 폴더 id를 넘김. `모든 음성` 화면에서는 null.
  final Future<void> Function([String? initialFolderId]) onUploadTap;

  final VoidCallback onOpenFolderManage;
  final void Function(String id) onAdvanceDemo;
  final void Function(String id) onDeleteJob;
  final void Function(String jobId, String folderId) onMoveJob;

  @override
  State<VoicePipelinePage> createState() => _VoicePipelinePageState();
}

class _VoicePipelinePageState extends State<VoicePipelinePage> {
  static const String _scopeAll = '__scope_all__';

  final _searchController = TextEditingController();
  VoiceJobListFilter _filter = VoiceJobListFilter.all;
  VoiceJobListSort _sort = VoiceJobListSort.newest;

  /// null: 폴더만 보기(루트) · [_scopeAll]: 전체 목록 · 그 외: 해당 폴더
  String? _scope;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _folderName(String folderId) {
    try {
      return widget.folders.firstWhere((f) => f.id == folderId).name;
    } catch (_) {
      return '폴더';
    }
  }

  List<VoiceFolder> get _sortedFolders {
    final list = List<VoiceFolder>.from(widget.folders);
    list.sort((a, b) {
      if (a.id == VoiceFolder.uncategorizedId) return -1;
      if (b.id == VoiceFolder.uncategorizedId) return 1;
      return a.name.compareTo(b.name);
    });
    return list;
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

  List<VoiceJob> _visibleJobs() {
    var list = _baseFiltered().where((j) => _filter.matches(j)).toList();
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

  int _countFor(VoiceJobListFilter f) {
    final base = _baseFiltered();
    if (f == VoiceJobListFilter.all) return base.length;
    return base.where((j) => f.matches(j)).length;
  }

  String _scopeTitle() {
    if (_scope == null) return '';
    if (_scope == _scopeAll) return '모든 음성';
    return _folderName(_scope!);
  }

  bool get _showFolderOnCards => _scope == _scopeAll;

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
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ..._sortedFolders.map(
                  (f) => ListTile(
                    title: Text(f.name),
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
    final filters = VoiceJobListFilter.values;

    return PopScope(
      canPop: _scope == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _scope != null) {
          setState(() => _scope = null);
        }
      },
      child: Scaffold(
        backgroundColor: YeolpumtaTheme.bg,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: _scope == null
                    ? _buildFolderBrowserHeader()
                    : _buildListHeader(),
              ),
            ),
            if (_scope == null) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                sliver: SliverList.separated(
                  itemCount: 1 + _sortedFolders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _FolderListRow(
                        icon: Icons.layers_rounded,
                        title: '모든 음성',
                        count: widget.jobs.length,
                        accent: true,
                        onTap: () => setState(() => _scope = _scopeAll),
                      );
                    }
                    final f = _sortedFolders[i - 1];
                    return _FolderListRow(
                      icon: Icons.folder_rounded,
                      title: f.name,
                      count: _countInFolder(f.id),
                      accent: false,
                      onTap: () => setState(() => _scope = f.id),
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
                          _scope == _scopeAll
                              ? '음성 올리기'
                              : '이 폴더에 올리기',
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final f in filters) ...[
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(
                                          '${f.label} (${_countFor(f)})',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: _filter == f
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: _filter == f
                                                ? YeolpumtaTheme.accent
                                                : YeolpumtaTheme
                                                    .textSecondary,
                                          ),
                                        ),
                                        selected: _filter == f,
                                        onSelected: (_) =>
                                            setState(() => _filter = f),
                                        showCheckmark: false,
                                        backgroundColor:
                                            YeolpumtaTheme.surface,
                                        selectedColor:
                                            YeolpumtaTheme.accentSoft,
                                        side: const BorderSide(
                                          color: YeolpumtaTheme.divider,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          PopupMenuButton<VoiceJobListSort>(
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (visible.isEmpty)
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
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final j = visible[i];
                      return _VoiceJobCard(
                        job: j,
                        folderLabel: _folderName(j.folderId),
                        showFolderLine: _showFolderOnCards,
                        onAdvance: () => widget.onAdvanceDemo(j.id),
                        onDelete: () => widget.onDeleteJob(j.id),
                        onMove: () => _showMoveSheet(j),
                      );
                    },
                  ),
                ),
            ],
          ],
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
              onPressed: widget.onOpenFolderManage,
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
              onPressed: () => setState(() => _scope = null),
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
                    '${_jobsInScope().length}개',
                    style: const TextStyle(
                      fontSize: 14,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: widget.onOpenFolderManage,
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
    required this.count,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
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
                      '음성 $count개',
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

class _VoiceJobCard extends StatelessWidget {
  const _VoiceJobCard({
    required this.job,
    required this.folderLabel,
    required this.showFolderLine,
    required this.onAdvance,
    required this.onDelete,
    required this.onMove,
  });

  final VoiceJob job;
  final String folderLabel;
  final bool showFolderLine;
  final VoidCallback onAdvance;
  final VoidCallback onDelete;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final status = job.status;
    final (IconData icon, Color color) = switch (status) {
      VoiceJobStatus.uploaded => (
          Icons.cloud_upload_outlined,
          const Color(0xFF8E8E93),
        ),
      VoiceJobStatus.training => (
          Icons.auto_awesome_motion_rounded,
          YeolpumtaTheme.accent,
        ),
      VoiceJobStatus.completed => (
          Icons.check_circle_rounded,
          const Color(0xFF34C759),
        ),
    };

    return Material(
      color: YeolpumtaTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.fileName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: YeolpumtaTheme.textPrimary,
                          ),
                        ),
                        if (showFolderLine) ...[
                          const SizedBox(height: 4),
                          Text(
                            '폴더 · $folderLabel',
                            style: const TextStyle(
                              fontSize: 12,
                              color: YeolpumtaTheme.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _StatusPill(status: status),
                            if (status != VoiceJobStatus.completed) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: onAdvance,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: YeolpumtaTheme.accent,
                                ),
                                child: const Text(
                                  '다음 단계(데모)',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                    onSelected: (v) {
                      if (v == 'move') onMove();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'move',
                        child: Text('다른 폴더로'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          '삭제',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (status == VoiceJobStatus.training) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.62,
                    minHeight: 4,
                    backgroundColor: YeolpumtaTheme.divider,
                    color: YeolpumtaTheme.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '학습 진행 중… (UI만 표시)',
                  style: TextStyle(
                    fontSize: 12,
                    color: YeolpumtaTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final VoiceJobStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: YeolpumtaTheme.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: YeolpumtaTheme.textSecondary,
        ),
      ),
    );
  }
}
