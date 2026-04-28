import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';
import '../../../onboarding/data/onboarding_prefs.dart';
import '../../../onboarding/presentation/widgets/spotlight_coach_overlay.dart';
import '../../domain/voice_folder.dart';
import '../../domain/voice_job.dart';
import '../widgets/voice_capture_choice_sheet.dart';
import '../widgets/voice_job_list_card.dart';

/// 폴더(가로 스크롤) → 폴더 안 음성 목록
class VoicePipelinePage extends StatefulWidget {
  const VoicePipelinePage({
    super.key,
    required this.jobs,
    required this.folders,
    required this.onUploadTap,
    required this.onDirectRecordTap,
    required this.onOpenFolderManage,
    required this.onRefreshScope,
    required this.onAdvanceDemo,
    required this.onDeleteJob,
    required this.onMoveJob,
    required this.onListenTap,
  });

  final List<VoiceJob> jobs;
  final List<VoiceFolder> folders;

  /// 폴더 안에서 올릴 때는 해당 폴더 id를 넘김. 루트·미리 선택 없음이면 null.
  final Future<void> Function([String? initialFolderId]) onUploadTap;

  /// 직접 녹음 플로우. [initialFolderId]가 있으면 시트에서 해당 폴더가 미리 선택됨.
  final Future<void> Function([String? initialFolderId]) onDirectRecordTap;

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
  final GlobalKey _bodyStackKey = GlobalKey();
  final GlobalKey _rootRecordButtonKey = GlobalKey();
  final _searchController = TextEditingController();
  VoiceJobListSort _sort = VoiceJobListSort.newest;
  bool _refreshingScope = false;
  bool _voiceCtaCoachActive = false;
  Rect? _recordButtonHoleLocal;

  /// null: 루트(내 폴더 목록) · 그 외: 열린 폴더 id
  String? _scope;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVoiceCtaCoach());
  }

  Future<void> _loadVoiceCtaCoach() async {
    final done = await OnboardingPrefs.isVoiceRootCtaCoachDone();
    if (!mounted) return;
    setState(() => _voiceCtaCoachActive = !done);
    if (!done) _scheduleMeasureRecordHole();
  }

  void _scheduleMeasureRecordHole() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureRecordButtonHole();
    });
  }

  void _measureRecordButtonHole() {
    if (!_voiceCtaCoachActive || _scope != null) return;
    final buttonCtx = _rootRecordButtonKey.currentContext;
    final stackCtx = _bodyStackKey.currentContext;
    if (buttonCtx == null || stackCtx == null) return;
    final buttonBox = buttonCtx.findRenderObject() as RenderBox?;
    final stackBox = stackCtx.findRenderObject() as RenderBox?;
    if (buttonBox == null ||
        stackBox == null ||
        !buttonBox.hasSize ||
        !stackBox.hasSize) {
      return;
    }
    final topLeft =
        stackBox.globalToLocal(buttonBox.localToGlobal(Offset.zero));
    const pad = 6.0;
    final r = Rect.fromLTWH(
      topLeft.dx - pad,
      topLeft.dy - pad,
      buttonBox.size.width + pad * 2,
      buttonBox.size.height + pad * 2,
    );
    if (!mounted) return;
    setState(() => _recordButtonHoleLocal = r);
  }

  @override
  void didUpdateWidget(covariant VoicePipelinePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_voiceCtaCoachActive && _scope == null) {
      _scheduleMeasureRecordHole();
    }
  }

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

  /// 루트 목록 — 시스템 폴더(미분류)는 숨김
  List<VoiceFolder> get _rootFoldersVisible => _rootFolders
      .where((f) => !f.isUncategorized)
      .toList(growable: false);

  List<VoiceFolder> _childFoldersInScope() {
    if (_scope == null) return const <VoiceFolder>[];
    return _sortedFoldersForParent(_scope);
  }

  int _countInFolder(String folderId) {
    return widget.jobs.where((j) => j.folderId == folderId).length;
  }

  List<VoiceJob> _jobsInScope() {
    if (_scope == null) return [];
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
    var list = List<VoiceJob>.from(_baseFiltered());
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

  String _scopeTitle() {
    if (_scope == null) return '';
    return _folderPath(_scope!);
  }

  bool get _showFolderOnCards => false;

  int get _childFolderCountInScope => _childFoldersInScope().length;

  String _scopeSummary() {
    if (_scope == null) return '';
    return '하위 폴더 $_childFolderCountInScope개 · 음성 ${_jobsInScope().length}개';
  }

  Future<void> _openFolder(String folderId) async {
    await _changeScope(folderId);
  }

  Future<void> _goBackScope() async {
    if (_scope == null) return;
    final parentId = _folderById(_scope!)?.parentId;
    await _changeScope(parentId);
  }

  Future<void> _changeScope(String? nextScope) async {
    setState(() => _scope = nextScope);
    await _refreshCurrentScope();
    if (_voiceCtaCoachActive && nextScope == null) {
      _scheduleMeasureRecordHole();
    }
  }

  Future<void> _refreshCurrentScope() async {
    final targetScope = _scope;
    if (targetScope == VoiceFolder.uncategorizedId) {
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

  /// 루트 등 폴더 미선택이면 null
  String? get _captureInitialFolderId {
    if (_scope == null) return null;
    return _scope;
  }

  /// 폴더 / 모든 음성 목록 안에서 — 업로드 / 직접 녹음 (현재 폴더 id 미리 선택 가능)
  Future<void> _openVoiceCaptureEntry() async {
    final initial = _captureInitialFolderId;
    final choice = await showModalBottomSheet<VoiceCaptureChoice?>(
      context: context,
      backgroundColor: YeolpumtaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const VoiceCaptureChoiceSheet(),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case VoiceCaptureChoice.upload:
        await widget.onUploadTap(initial);
      case VoiceCaptureChoice.record:
        await widget.onDirectRecordTap(initial);
    }
  }

  /// 루트 화면(_scope == null)에서만 사용
  Future<void> _openVoiceCaptureFromRoot() async {
    final choice = await showModalBottomSheet<VoiceCaptureChoice?>(
      context: context,
      backgroundColor: YeolpumtaTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const VoiceCaptureChoiceSheet(),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case VoiceCaptureChoice.upload:
        await widget.onUploadTap();
      case VoiceCaptureChoice.record:
        await widget.onDirectRecordTap();
    }
  }

  Future<void> _onRootVoiceCaptureTap() async {
    if (_voiceCtaCoachActive) {
      await OnboardingPrefs.setVoiceRootCtaCoachDone();
      if (!mounted) return;
      setState(() {
        _voiceCtaCoachActive = false;
        _recordButtonHoleLocal = null;
      });
      await widget.onDirectRecordTap();
      return;
    }
    await _openVoiceCaptureFromRoot();
  }

  ButtonStyle get _voiceCaptureButtonStyle => FilledButton.styleFrom(
    backgroundColor: YeolpumtaTheme.accent,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 0,
  );

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
        body: Stack(
          key: _bodyStackKey,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: RefreshIndicator(
                onRefresh: _refreshCurrentScope,
                child: CustomScrollView(
                  physics: (_voiceCtaCoachActive &&
                          _scope == null &&
                          _recordButtonHoleLocal != null)
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: FilledButton.icon(
                      key: _rootRecordButtonKey,
                      onPressed: _onRootVoiceCaptureTap,
                      icon: const Icon(Icons.mic_rounded, size: 22),
                      label: const Text(
                        '음성 녹음',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: _voiceCaptureButtonStyle,
                    ),
                  ),
                ),
                if (_rootFoldersVisible.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(32, 8, 32, 24),
                      child: _EmptyRootFoldersHint(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    sliver: SliverList.separated(
                      itemCount: _rootFoldersVisible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final f = _rootFoldersVisible[i];
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
                if (_rootFoldersVisible.isNotEmpty)
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
                          onPressed: _openVoiceCaptureEntry,
                          icon: const Icon(Icons.mic_rounded, size: 22),
                          label: const Text(
                            '음성 녹음',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: _voiceCaptureButtonStyle,
                        ),
                        const SizedBox(height: 16),
                        if (childFolders.isNotEmpty) ...[
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
                                  ? '이 폴더에 음성이 없어요'
                                  : '조건에 맞는 파일이 없어요',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: YeolpumtaTheme.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                            if (_jobsInScope().isEmpty) ...[
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _openVoiceCaptureEntry,
                                icon: const Icon(Icons.mic_rounded, size: 22),
                                label: const Text(
                                  '음성 녹음',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: _voiceCaptureButtonStyle,
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
            if (_voiceCtaCoachActive &&
                _scope == null &&
                _recordButtonHoleLocal != null)
              Positioned.fill(
                child: SpotlightCoachOverlay(
                  holeRect: _recordButtonHoleLocal!,
                  title: '시작은 여기!',
                  body: '가장 많이 쓰는 건 이 초록 버튼이에요. 누르면 바로 녹음으로 갈게요.',
                  tapHint: '👉 한번 눌러볼래?',
                  holeRadius: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewFolderToolbarButton({String? currentFolderId}) {
    return FilledButton.tonalIcon(
      onPressed: () => widget.onOpenFolderManage(currentFolderId),
      icon: const Icon(Icons.create_new_folder_rounded, size: 20),
      label: const Text(
        '새 폴더',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: YeolpumtaTheme.surface,
        foregroundColor: YeolpumtaTheme.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: YeolpumtaTheme.outline),
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
                    '음성 녹음으로 바로 추가하거나, 새 폴더로 정리할 수 있어요. 만든 폴더를 누르면 그 안의 목록·상태를 볼 수 있어요.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: YeolpumtaTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _buildNewFolderToolbarButton(),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            _buildNewFolderToolbarButton(currentFolderId: _scope),
          ],
        ),
      ],
    );
  }
}

/// 루트에 사용자 폴더가 없을 때
class _EmptyRootFoldersHint extends StatelessWidget {
  const _EmptyRootFoldersHint();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.folder_open_rounded,
          size: 48,
          color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.75),
        ),
        const SizedBox(height: 14),
        const Text(
          '아직 만든 폴더가 없어요',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: YeolpumtaTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '오른쪽 위 「새 폴더」로 첫 폴더를 만들거나,\n음성 녹음으로 바로 추가해 보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: YeolpumtaTheme.textSecondary.withValues(alpha: 0.95),
          ),
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
            '아래 목록에서 폴더를 누르거나,\n오른쪽 위 「새 폴더」를 눌러 보세요',
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
    final shadowColor = Colors.black.withValues(alpha: 0.06);
    final borderColor =
        accent ? YeolpumtaTheme.accent.withValues(alpha: 0.22) : YeolpumtaTheme.outline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: accent ? YeolpumtaTheme.accentSoft : YeolpumtaTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                        : YeolpumtaTheme.iconMutedBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: YeolpumtaTheme.accent,
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
    ),
    );
  }
}
