import 'package:flutter/material.dart';

import '../../core/analysis/candidate_ai_tools.dart';
import '../../core/ui/responsive.dart';
import '../../core/ui/theme_toggle_button.dart';
import '../../data/services/user_service.dart';

class CandidateCompareScreen extends StatefulWidget {
  const CandidateCompareScreen({
    super.key,
    required this.requesterId,
    required this.firstCandidateId,
    required this.secondCandidateId,
  });

  final int requesterId;
  final int firstCandidateId;
  final int secondCandidateId;

  @override
  State<CandidateCompareScreen> createState() => _CandidateCompareScreenState();
}

class _CandidateCompareScreenState extends State<CandidateCompareScreen> {
  final _userService = UserService();

  Map<String, dynamic>? _firstCandidate;
  Map<String, dynamic>? _secondCandidate;
  Map<String, dynamic>? _comparison;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await _userService.fetchCandidateComparison(
        requesterId: widget.requesterId,
        firstCandidateId: widget.firstCandidateId,
        secondCandidateId: widget.secondCandidateId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _firstCandidate = result?['firstCandidate'] as Map<String, dynamic>?;
        _secondCandidate = result?['secondCandidate'] as Map<String, dynamic>?;
        _comparison = result?['comparison'] as Map<String, dynamic>?;
        _isLoading = false;
        _hasError =
            result == null ||
            _firstCandidate == null ||
            _secondCandidate == null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = AppResponsive.inset(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сравнение кандидатов'),
        actions: const [ThemeToggleButton()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError || _firstCandidate == null || _secondCandidate == null
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppResponsive.contentMaxWidth(context),
                ),
                child: Padding(
                  padding: EdgeInsets.all(inset),
                  child: _CompareStateCard(
                    icon: Icons.compare_arrows_rounded,
                    title: 'Не удалось собрать сравнение',
                    subtitle:
                        'Проверьте доступ к данным кандидатов и попробуйте открыть экран заново.',
                    actionLabel: 'Повторить',
                    onPressed: _loadCandidates,
                  ),
                ),
              ),
            )
          : _CompareContent(
              firstCandidate: _firstCandidate!,
              secondCandidate: _secondCandidate!,
              comparison: _comparison,
            ),
    );
  }
}

class _CompareContent extends StatelessWidget {
  const _CompareContent({
    required this.firstCandidate,
    required this.secondCandidate,
    required this.comparison,
  });

  final Map<String, dynamic> firstCandidate;
  final Map<String, dynamic> secondCandidate;
  final Map<String, dynamic>? comparison;

  @override
  Widget build(BuildContext context) {
    final inset = AppResponsive.inset(context);
    final maxWidth = AppResponsive.contentMaxWidth(context, desktop: 1180);
    final firstScore = _parseScore(firstCandidate['aiScore']);
    final secondScore = _parseScore(secondCandidate['aiScore']);
    final scoreDelta = (firstScore - secondScore).abs();
    final title = _readText(comparison?['summaryTitle']);
    final summary = _readText(comparison?['summaryText']);
    final recommendation = _readText(comparison?['recommendation']);
    final decisionFactors = _toStringList(comparison?['decisionFactors']);
    final firstStrengths = _toStringList(
      comparison?['firstCandidateStrengths'],
    );
    final secondStrengths = _toStringList(
      comparison?['secondCandidateStrengths'],
    );
    final firstRedFlags = CandidateAiTools.detectRedFlags(firstCandidate);
    final secondRedFlags = CandidateAiTools.detectRedFlags(secondCandidate);
    final winner = title.isEmpty
        ? _winnerTitle(firstCandidate, secondCandidate, firstScore, secondScore)
        : title;
    final summaryText = summary.isEmpty
        ? _summaryText(firstCandidate, secondCandidate, firstScore, secondScore)
        : summary;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: EdgeInsets.all(inset),
          children: [
            _AiSummaryCard(
              winner: winner,
              scoreDelta: scoreDelta,
              summary: summaryText,
              recommendation: recommendation,
              decisionFactors: decisionFactors,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 960;
                final gap = AppResponsive.isMobile(context) ? 12.0 : 16.0;
                final panelWidth = stacked
                    ? constraints.maxWidth
                    : (constraints.maxWidth - gap) / 2;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _CandidateComparePanel(
                      width: panelWidth,
                      candidate: firstCandidate,
                      opponentScore: secondScore,
                      aiStrengths: firstStrengths,
                      redFlags: firstRedFlags,
                    ),
                    _CandidateComparePanel(
                      width: panelWidth,
                      candidate: secondCandidate,
                      opponentScore: firstScore,
                      aiStrengths: secondStrengths,
                      redFlags: secondRedFlags,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static int _parseScore(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _candidateName(Map<String, dynamic> candidate) {
    return (candidate['fullName'] ?? 'Кандидат').toString();
  }

  static String _winnerTitle(
    Map<String, dynamic> firstCandidate,
    Map<String, dynamic> secondCandidate,
    int firstScore,
    int secondScore,
  ) {
    if (firstScore == secondScore) {
      return 'По оценке кандидаты идут на равных';
    }
    return firstScore > secondScore
        ? 'Преимущество у ${_candidateName(firstCandidate)}'
        : 'Преимущество у ${_candidateName(secondCandidate)}';
  }

  static String _summaryText(
    Map<String, dynamic> firstCandidate,
    Map<String, dynamic> secondCandidate,
    int firstScore,
    int secondScore,
  ) {
    if (firstScore == secondScore) {
      return 'У обоих кандидатов одинаковый балл. Смотрите на детали проектов, глубину роли и подтвержденные результаты.';
    }

    final better = firstScore > secondScore ? firstCandidate : secondCandidate;
    final other = firstScore > secondScore ? secondCandidate : firstCandidate;
    final verdict = (better['aiVerdict'] ?? '').toString().trim();
    final betterName = _candidateName(better);
    final otherName = _candidateName(other);

    if (verdict.isEmpty) {
      return '$betterName набрал больше баллов, чем $otherName. Основное преимущество видно по общей оценке и структуре профиля.';
    }

    return '$betterName опережает $otherName. Ключевой акцент: $verdict';
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static String _readText(dynamic value) => value?.toString().trim() ?? '';
}

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard({
    required this.winner,
    required this.scoreDelta,
    required this.summary,
    required this.recommendation,
    required this.decisionFactors,
  });

  final String winner;
  final int scoreDelta;
  final String summary;
  final String recommendation;
  final List<String> decisionFactors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppResponsive.isMobile(context) ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppResponsive.heroRadius(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              scoreDelta == 0 ? 'Баллы совпали' : 'Разница: $scoreDelta баллов',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            winner,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          if (recommendation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              recommendation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
          if (decisionFactors.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...decisionFactors.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '- $item',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.90),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CandidateComparePanel extends StatelessWidget {
  const _CandidateComparePanel({
    required this.width,
    required this.candidate,
    required this.opponentScore,
    required this.aiStrengths,
    required this.redFlags,
  });

  final double width;
  final Map<String, dynamic> candidate;
  final int opponentScore;
  final List<String> aiStrengths;
  final List<String> redFlags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = _parseScore(candidate['aiScore']);
    final isLeader = score > opponentScore;
    final skills = _toStringList(candidate['skills']);
    final projects = _toStringList(candidate['projects']);
    final shortlistLabel = CandidateAiTools.shortlistLabel(candidate);

    return Container(
      width: width,
      padding: EdgeInsets.all(AppResponsive.isMobile(context) ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        border: Border.all(
          color: isLeader ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
          width: isLeader ? 2 : 1,
        ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (candidate['fullName'] ?? 'Кандидат').toString(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (candidate['email'] ?? '-').toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shortlistLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isLeader
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _CompareScoreBadge(score: score, isLeader: isLeader),
            ],
          ),
          const SizedBox(height: 18),
          _CompareSection(
            title: 'Вердикт',
            child: Text(
              (candidate['aiVerdict'] ?? 'Пояснение пока недоступно.')
                  .toString(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          if (aiStrengths.isNotEmpty)
            _CompareSection(
              title: 'AI акценты',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: aiStrengths
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('- $item'),
                      ),
                    )
                    .toList(),
              ),
            ),
          _CompareSection(
            title: 'Сводка ценности',
            child: Text(
              (candidate['valueStatement'] ?? '-').toString(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          _CompareSection(
            title: 'Выжимка опыта',
            child: Text(
              (candidate['experienceSummary'] ?? '-').toString(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          _CompareSection(
            title: 'Red flags',
            child: redFlags.isEmpty
                ? const Text('Критичных red flags не найдено.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: redFlags
                        .take(3)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('- $item'),
                          ),
                        )
                        .toList(),
                  ),
          ),
          _CompareSection(
            title: 'Навыки',
            child: skills.isEmpty
                ? const Text('-')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map((skill) => _TagChip(label: skill))
                        .toList(),
                  ),
          ),
          _CompareSection(
            title: 'Проекты',
            child: projects.isEmpty
                ? const Text('-')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: projects
                        .map(
                          (project) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('- $project'),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  static int _parseScore(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

class _CompareScoreBadge extends StatelessWidget {
  const _CompareScoreBadge({required this.score, required this.isLeader});

  final int score;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    final color = isLeader ? const Color(0xFF2563EB) : const Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Score',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CompareSection extends StatelessWidget {
  const _CompareSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CompareStateCard extends StatelessWidget {
  const _CompareStateCard({
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
