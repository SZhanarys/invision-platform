import 'package:flutter/material.dart';

import '../../core/analysis/candidate_ai_tools.dart';
import '../../core/ui/responsive.dart';
import '../../core/ui/theme_toggle_button.dart';
import '../../data/services/shortlist_service.dart';
import '../../data/services/user_service.dart';
import 'candidate_compare_screen.dart';
import 'candidate_details_screen.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({
    super.key,
    required this.role,
    required this.requesterId,
  });

  final String role;
  final int requesterId;

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final _searchController = TextEditingController();
  final _userService = UserService();
  final _shortlistService = createShortlistService();
  final Set<int> _selectedCandidateIds = <int>{};
  final Set<int> _shortlistedIds = <int>{};

  List<Map<String, dynamic>> users = const [];
  bool isLoading = true;
  bool hasError = false;
  bool showShortlistOnly = false;

  bool get _isAdmin => widget.role == 'ADMIN';
  String get _searchQuery => _searchController.text.trim().toLowerCase();

  List<Map<String, dynamic>> get _visibleUsers {
    var allUsers = [...users];
    if (_isAdmin && showShortlistOnly) {
      allUsers = allUsers
          .where((user) => _shortlistedIds.contains(user['id']))
          .toList();
    }
    if (!_isAdmin || _searchQuery.isEmpty) {
      return allUsers;
    }

    return allUsers.where((user) {
      final name = ((user['fullName'] ?? user['name'] ?? '') as Object)
          .toString()
          .toLowerCase();
      final skills = _extractSkillsText(user).toLowerCase();
      return name.contains(_searchQuery) || skills.contains(_searchQuery);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadShortlist();
    fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShortlist() async {
    final saved = await _shortlistService.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _shortlistedIds
        ..clear()
        ..addAll(saved);
    });
  }

  Future<void> fetch() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final result = await _userService.fetchCandidates(
        requesterId: widget.requesterId,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        users = result;
        isLoading = false;
      });
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
      hasError = true;
    });
  }

  void _toggleCandidateSelection(int candidateId) {
    setState(() {
      if (_selectedCandidateIds.contains(candidateId)) {
        _selectedCandidateIds.remove(candidateId);
        return;
      }
      if (_selectedCandidateIds.length == 2) {
        _selectedCandidateIds.remove(_selectedCandidateIds.first);
      }
      _selectedCandidateIds.add(candidateId);
    });
  }

  Future<void> _toggleShortlist(int candidateId) async {
    setState(() {
      if (_shortlistedIds.contains(candidateId)) {
        _shortlistedIds.remove(candidateId);
      } else {
        _shortlistedIds.add(candidateId);
      }
    });
    await _shortlistService.save(_shortlistedIds);
  }

  void _openCompare() {
    if (_selectedCandidateIds.length != 2) {
      return;
    }
    final ids = _selectedCandidateIds.toList(growable: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CandidateCompareScreen(
          requesterId: widget.requesterId,
          firstCandidateId: ids[0],
          secondCandidateId: ids[1],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inset = AppResponsive.inset(context);
    final visibleUsers = _visibleUsers;
    final shortlistedUsers =
        users.where((user) => _shortlistedIds.contains(user['id'])).toList()
          ..sort(
            (a, b) => CandidateAiTools.candidateScore(
              b,
            ).compareTo(CandidateAiTools.candidateScore(a)),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'Кандидаты' : 'Рейтинг'),
        actions: const [ThemeToggleButton()],
      ),
      body: RefreshIndicator(
        onRefresh: fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(inset, inset, inset, inset + 8),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppResponsive.contentMaxWidth(
                    context,
                    desktop: 1180,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(
                      title: _isAdmin
                          ? 'Список кандидатов'
                          : 'Рейтинг участников',
                      subtitle: _isAdmin
                          ? 'Ищите, добавляйте в шорт-лист, находите красные флаги и сравнивайте кандидатов попарно.'
                          : 'Следите за результатами и общей картиной по участникам.',
                      accentColor: _isAdmin
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF059669),
                      totalCount: users.length,
                    ),
                    SizedBox(height: AppResponsive.sectionGap(context) - 6),
                    if (_isAdmin) ...[
                      _ShortlistBoard(
                        shortlistedUsers: shortlistedUsers,
                        showShortlistOnly: showShortlistOnly,
                        onToggleShowShortlist: () {
                          setState(
                            () => showShortlistOnly = !showShortlistOnly,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _SearchCard(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _CompareToolbar(
                        selectedCount: _selectedCandidateIds.length,
                        onClear: _selectedCandidateIds.isEmpty
                            ? null
                            : () => setState(_selectedCandidateIds.clear),
                        onCompare: _selectedCandidateIds.length == 2
                            ? _openCompare
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (hasError)
                      _StateCard(
                        icon: Icons.cloud_off_rounded,
                        title: 'Не удалось загрузить данные',
                        subtitle:
                            'Проверьте backend и попробуйте обновить экран.',
                        actionLabel: 'Повторить',
                        onPressed: fetch,
                      )
                    else if (users.isEmpty)
                      _StateCard(
                        icon: Icons.inbox_rounded,
                        title: 'Список пока пуст',
                        subtitle: _isAdmin
                            ? 'Кандидаты появятся после регистрации и заполнения анкеты.'
                            : 'Рейтинг появится, когда в системе будут участники.',
                      )
                    else if (visibleUsers.isEmpty)
                      const _StateCard(
                        icon: Icons.search_off_rounded,
                        title: 'Ничего не найдено',
                        subtitle:
                            'Попробуйте изменить запрос или отключить фильтр шорт-листа.',
                      )
                    else ...[
                      Text(
                        _isAdmin ? 'Активные профили' : 'Участники рейтинга',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(visibleUsers.length, (index) {
                        final user = visibleUsers[index];
                        final candidateId = user['id'] is int
                            ? user['id'] as int
                            : null;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CandidateCard(
                            index: index,
                            role: widget.role,
                            user: user,
                            requesterId: widget.requesterId,
                            isSelectedForCompare:
                                candidateId != null &&
                                _selectedCandidateIds.contains(candidateId),
                            isShortlisted:
                                candidateId != null &&
                                _shortlistedIds.contains(candidateId),
                            onToggleCompare: candidateId == null
                                ? null
                                : () => _toggleCandidateSelection(candidateId),
                            onToggleShortlist: candidateId == null
                                ? null
                                : () => _toggleShortlist(candidateId),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractSkillsText(Map<String, dynamic> user) {
    final rawSkills = user['skills'] ?? user['skill'] ?? user['stack'];
    if (rawSkills == null) {
      return '';
    }
    if (rawSkills is List) {
      return rawSkills.map((item) => item.toString()).join(' ');
    }
    return rawSkills.toString();
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.totalCount,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppResponsive.isMobile(context) ? 18 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor,
            Color.lerp(accentColor, Colors.white, 0.35) ?? accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Всего: $totalCount',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortlistBoard extends StatelessWidget {
  const _ShortlistBoard({
    required this.shortlistedUsers,
    required this.showShortlistOnly,
    required this.onToggleShowShortlist,
  });

  final List<Map<String, dynamic>> shortlistedUsers;
  final bool showShortlistOnly;
  final VoidCallback onToggleShowShortlist;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppResponsive.isMobile(context) ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Панель шорт-листа',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              FilterChip(
                selected: showShortlistOnly,
                onSelected: (_) => onToggleShowShortlist(),
                label: const Text('Только шорт-лист'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            shortlistedUsers.isEmpty
                ? 'Пока нет сохраненных кандидатов. Отмечай сильные профили звездой прямо в карточке.'
                : 'Сильные профили под рукой. Можно быстро вернуться к лучшим кандидатам без повторного поиска.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          if (shortlistedUsers.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: shortlistedUsers
                  .take(6)
                  .map(
                    (user) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${(user['fullName'] ?? 'Кандидат').toString()} · ${CandidateAiTools.candidateScore(user)}',
                        style: const TextStyle(
                          color: Color(0xFF9A3412),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompareToolbar extends StatelessWidget {
  const _CompareToolbar({
    required this.selectedCount,
    this.onClear,
    this.onCompare,
  });

  final int selectedCount;
  final VoidCallback? onClear;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppResponsive.isMobile(context) ? 14 : 16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            selectedCount == 0
                ? 'Выберите двух кандидатов для сравнения'
                : 'Выбрано для сравнения: $selectedCount из 2',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          OutlinedButton(onPressed: onClear, child: const Text('Сбросить')),
          ElevatedButton.icon(
            onPressed: onCompare,
            icon: const Icon(Icons.compare_rounded),
            label: const Text('Сравнить'),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.index,
    required this.role,
    required this.user,
    required this.requesterId,
    required this.isSelectedForCompare,
    required this.isShortlisted,
    this.onToggleCompare,
    this.onToggleShortlist,
  });

  final int index;
  final String role;
  final Map<String, dynamic> user;
  final int requesterId;
  final bool isSelectedForCompare;
  final bool isShortlisted;
  final VoidCallback? onToggleCompare;
  final VoidCallback? onToggleShortlist;

  bool get _isAdmin => role == 'ADMIN';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isAdmin
        ? (user['fullName'] ?? 'Без имени').toString()
        : (user['name'] ?? 'Участник').toString();
    final score = CandidateAiTools.candidateScore(user);
    final phone = (user['phoneNumber'] ?? '').toString();
    final submitted = user['submitted'] == true;
    final canOpenDetails = _isAdmin && user['id'] is int;
    final canCompare = _isAdmin && user['id'] is int;
    final redFlags = CandidateAiTools.detectRedFlags(user);
    final shortlistLabel = CandidateAiTools.shortlistLabel(user);
    final cardPadding = AppResponsive.isMobile(context) ? 16.0 : 18.0;
    final cardRadius = AppResponsive.isMobile(context) ? 20.0 : 22.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(cardRadius),
        onTap: canOpenDetails
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CandidateDetailsScreen(
                      userId: user['id'] as int,
                      requesterId: requesterId,
                    ),
                  ),
                );
              }
            : null,
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: isSelectedForCompare
                  ? const Color(0xFF2563EB)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.2),
              width: isSelectedForCompare ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final info = Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shortlistLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );

                  final trailing = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onToggleShortlist != null)
                        IconButton(
                          tooltip: isShortlisted
                              ? 'Убрать из шорт-листа'
                              : 'Добавить в шорт-лист',
                          onPressed: onToggleShortlist,
                          icon: Icon(
                            isShortlisted
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: isShortlisted
                                ? const Color(0xFFEA580C)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      _ScoreChip(score: score),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _RankBadge(index: index + 1),
                            const SizedBox(width: 12),
                            info,
                          ],
                        ),
                        const SizedBox(height: 12),
                        trailing,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      _RankBadge(index: index + 1),
                      const SizedBox(width: 12),
                      info,
                      const SizedBox(width: 12),
                      trailing,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoChip(
                    icon: Icons.insights_rounded,
                    label: 'Оценка',
                    value: '$score',
                  ),
                  if (_isAdmin)
                    _InfoChip(
                      icon: submitted
                          ? Icons.verified_rounded
                          : Icons.pending_actions_rounded,
                      label: 'Анкета',
                      value: submitted ? 'Заполнена' : 'Не заполнена',
                      accentColor: submitted
                          ? const Color(0xFF059669)
                          : const Color(0xFFB45309),
                    ),
                  if (_isAdmin && phone.isNotEmpty)
                    _InfoChip(
                      icon: Icons.phone_rounded,
                      label: 'Телефон',
                      value: phone,
                    ),
                  _InfoChip(
                    icon: Icons.flag_rounded,
                    label: 'Красные флаги',
                    value: '${redFlags.length}',
                    accentColor: redFlags.isEmpty
                        ? const Color(0xFF059669)
                        : const Color(0xFFB45309),
                  ),
                ],
              ),
              if (redFlags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    redFlags.first,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              if (canOpenDetails || canCompare) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (canOpenDetails)
                      Text(
                        'Открыть подробности',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (canCompare)
                      OutlinedButton.icon(
                        onPressed: onToggleCompare,
                        icon: Icon(
                          isSelectedForCompare
                              ? Icons.check_circle_rounded
                              : Icons.compare_arrows_rounded,
                        ),
                        label: Text(
                          isSelectedForCompare ? 'Выбран' : 'Сравнить',
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppResponsive.isMobile(context) ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: 'Поиск по имени или навыку',
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          isDense: true,
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final isTopThree = index <= 3;

    return Container(
      width: AppResponsive.isMobile(context) ? 42 : 46,
      height: AppResponsive.isMobile(context) ? 42 : 46,
      decoration: BoxDecoration(
        color: isTopThree ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        '#$index',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: isTopThree ? const Color(0xFFB45309) : const Color(0xFF334155),
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 90
        ? const Color(0xFF059669)
        : score >= 75
        ? const Color(0xFF2563EB)
        : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score баллов',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor = const Color(0xFF334155),
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label: $value',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppResponsive.isMobile(context) ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF64748B)),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 18),
            ElevatedButton(onPressed: onPressed, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
