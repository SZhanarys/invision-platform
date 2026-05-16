import 'package:flutter/material.dart';

import '../../core/ui/responsive.dart';
import '../../core/ui/theme_toggle_button.dart';
import '../../data/services/user_service.dart';
import 'candidate_compare_screen.dart';
import 'candidate_details_screen.dart';

class HiringInsightsScreen extends StatefulWidget {
  const HiringInsightsScreen({super.key, required this.requesterId});

  final int requesterId;

  @override
  State<HiringInsightsScreen> createState() => _HiringInsightsScreenState();
}

class _HiringInsightsScreenState extends State<HiringInsightsScreen> {
  final _userService = UserService();

  List<Map<String, dynamic>> _candidates = const [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final candidates = await _userService.fetchCandidates(
        requesterId: widget.requesterId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _candidates = candidates;
        _isLoading = false;
        _hasError = false;
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
    final maxWidth = AppResponsive.contentMaxWidth(context, desktop: 1180);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Инсайты по найму'),
        actions: const [ThemeToggleButton()],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(inset),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _hasError
                    ? _StateCard(
                        icon: Icons.wifi_off_rounded,
                        title: 'Не удалось загрузить инсайты по найму',
                        subtitle:
                            'Проверь backend и открой экран еще раз. После этого метрики и рекомендации подтянутся автоматически.',
                        actionLabel: 'Повторить',
                        onPressed: _load,
                      )
                    : _candidates.isEmpty
                    ? const _StateCard(
                        icon: Icons.inbox_rounded,
                        title: 'Пока нет кандидатов',
                        subtitle:
                            'Когда кандидаты заполнят анкеты, здесь появятся топ-профили, сигналы навыков и быстрые рекомендации по найму.',
                      )
                    : _InsightsContent(
                        requesterId: widget.requesterId,
                        candidates: _candidates,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsContent extends StatelessWidget {
  const _InsightsContent({required this.requesterId, required this.candidates});

  final int requesterId;
  final List<Map<String, dynamic>> candidates;

  @override
  Widget build(BuildContext context) {
    final sorted = [...candidates]
      ..sort((a, b) => _scoreOf(b).compareTo(_scoreOf(a)));
    final topCandidates = sorted.take(3).toList();
    final averageScore = candidates.isEmpty
        ? 0
        : (candidates.map(_scoreOf).reduce((a, b) => a + b) / candidates.length)
              .round();
    final strongCount = candidates
        .where((candidate) => _scoreOf(candidate) >= 85)
        .length;
    final filledCount = candidates
        .where((candidate) => candidate['submitted'] == true)
        .length;
    final topSkills = _extractTopSkills(candidates);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroInsightsCard(
          totalCount: candidates.length,
          averageScore: averageScore,
          strongCount: strongCount,
          filledCount: filledCount,
          bestCandidateName: _candidateName(sorted.first),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final width = stacked
                ? constraints.maxWidth
                : (constraints.maxWidth - 18) / 2;

            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                _TopCandidatesCard(
                  width: width,
                  requesterId: requesterId,
                  candidates: topCandidates,
                ),
                _SkillRadarCard(
                  width: width,
                  topSkills: topSkills,
                  candidates: candidates,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _RecommendationCard(candidates: sorted, requesterId: requesterId),
      ],
    );
  }

  static int _scoreOf(Map<String, dynamic> candidate) {
    final value = candidate['aiScore'] ?? candidate['score'];
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _candidateName(Map<String, dynamic> candidate) {
    return (candidate['fullName'] ?? candidate['name'] ?? 'Кандидат')
        .toString();
  }

  static List<MapEntry<String, int>> _extractTopSkills(
    List<Map<String, dynamic>> candidates,
  ) {
    final frequencies = <String, int>{};

    for (final candidate in candidates) {
      final rawSkills =
          candidate['skills'] ?? candidate['skill'] ?? candidate['stack'];
      final values = <String>[];
      if (rawSkills is List) {
        values.addAll(rawSkills.map((item) => item.toString()));
      } else if (rawSkills != null) {
        values.addAll(rawSkills.toString().split(','));
      }

      for (final item in values) {
        final skill = item.trim();
        if (skill.isEmpty) {
          continue;
        }
        frequencies.update(skill, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final sorted = frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(6).toList();
  }
}

class _HeroInsightsCard extends StatelessWidget {
  const _HeroInsightsCard({
    required this.totalCount,
    required this.averageScore,
    required this.strongCount,
    required this.filledCount,
    required this.bestCandidateName,
  });

  final int totalCount;
  final int averageScore;
  final int strongCount;
  final int filledCount;
  final String bestCandidateName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppResponsive.isMobile(context) ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF0F766E)],
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
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Ключевая фича для админа',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Инсайты по кандидатам в одном экране',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ты сразу видишь средний уровень пула, сильный шорт-лист, топ-кандидата и сигналы навыков без ручного просмотра каждого профиля.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricChip(label: 'Кандидаты', value: '$totalCount'),
              _MetricChip(label: 'Средний балл', value: '$averageScore'),
              _MetricChip(label: 'Сильный шорт-лист', value: '$strongCount'),
              _MetricChip(label: 'Заполненные анкеты', value: '$filledCount'),
              _MetricChip(label: 'Топ-кандидат', value: bestCandidateName),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCandidatesCard extends StatelessWidget {
  const _TopCandidatesCard({
    required this.width,
    required this.requesterId,
    required this.candidates,
  });

  final double width;
  final int requesterId;
  final List<Map<String, dynamic>> candidates;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
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
          Text(
            'Топ-кандидаты',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Лучшие профили по текущему AI score и полноте анкеты.'),
          const SizedBox(height: 18),
          ...candidates.asMap().entries.map((entry) {
            final index = entry.key;
            final candidate = entry.value;
            final candidateId = candidate['id'] as int?;
            final score = _InsightsContent._scoreOf(candidate);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _InsightsContent._candidateName(candidate),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text((candidate['email'] ?? '-').toString()),
                            ],
                          ),
                        ),
                        _ScoreBadge(score: score),
                      ],
                    ),
                    if (candidateId != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CandidateDetailsScreen(
                                  userId: candidateId,
                                  requesterId: requesterId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Открыть детали'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SkillRadarCard extends StatelessWidget {
  const _SkillRadarCard({
    required this.width,
    required this.topSkills,
    required this.candidates,
  });

  final double width;
  final List<MapEntry<String, int>> topSkills;
  final List<Map<String, dynamic>> candidates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
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
          Text(
            'Радар навыков',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Часто встречающиеся навыки в текущем пуле кандидатов и быстрый взгляд на силу выборки.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: topSkills.isEmpty
                ? [const _EmptySkillChip(label: 'Навыки пока не распознаны')]
                : topSkills
                      .map(
                        (entry) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${entry.key} · ${entry.value}',
                            style: const TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
          ),
          const SizedBox(height: 18),
          _InsightLine(
            title: 'Инсайт',
            value: topSkills.isEmpty
                ? 'Для сильного skill analysis нужно больше заполненных анкет.'
                : 'Самый частый сигнал сейчас: ${topSkills.first.key}. Это хороший маркер текущего стека участников.',
          ),
          const SizedBox(height: 10),
          _InsightLine(
            title: 'Рекомендация',
            value: candidates.length >= 2
                ? 'Сравни top 2 кандидатов, чтобы показать жюри не только список, но и инструмент принятия решения.'
                : 'Когда появится второй кандидат, открой экран сравнения для полноценного hiring demo.',
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.candidates,
    required this.requesterId,
  });

  final List<Map<String, dynamic>> candidates;
  final int requesterId;

  @override
  Widget build(BuildContext context) {
    final top = candidates.first;
    final second = candidates.length > 1 ? candidates[1] : null;
    final topId = top['id'] as int?;
    final secondId = second?['id'] as int?;

    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            'AI-рекомендация по найму',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Лучший текущий кандидат: ${_InsightsContent._candidateName(top)}. Его балл: ${_InsightsContent._scoreOf(top)}.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (topId != null)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CandidateDetailsScreen(
                          userId: topId,
                          requesterId: requesterId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_search_rounded),
                  label: const Text('Открыть топ-кандидата'),
                ),
              if (topId != null && secondId != null)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CandidateCompareScreen(
                          requesterId: requesterId,
                          firstCandidateId: topId,
                          secondCandidateId: secondId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.compare_rounded),
                  label: const Text('Сравнить top 2'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 90
        ? const Color(0xFF059669)
        : score >= 75
        ? const Color(0xFF2563EB)
        : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$score pts',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF334155),
          height: 1.5,
        ),
        children: [
          TextSpan(
            text: '$title: ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _EmptySkillChip extends StatelessWidget {
  const _EmptySkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
