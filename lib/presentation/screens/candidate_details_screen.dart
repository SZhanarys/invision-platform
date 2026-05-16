import 'package:flutter/material.dart';

import '../../core/analysis/candidate_ai_tools.dart';
import '../../core/ui/responsive.dart';
import '../../core/ui/theme_toggle_button.dart';
import '../../data/services/user_service.dart';

class CandidateDetailsScreen extends StatefulWidget {
  const CandidateDetailsScreen({
    super.key,
    required this.userId,
    required this.requesterId,
  });

  final int userId;
  final int requesterId;

  @override
  State<CandidateDetailsScreen> createState() => _CandidateDetailsScreenState();
}

class _CandidateDetailsScreenState extends State<CandidateDetailsScreen> {
  final _userService = UserService();
  final _jobDescriptionController = TextEditingController();

  Map<String, dynamic>? _candidate;
  bool _isLoading = true;
  JobMatchResult? _jobMatch;

  @override
  void initState() {
    super.initState();
    _loadCandidate();
  }

  @override
  void dispose() {
    _jobDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCandidate() async {
    final candidate = await _userService.fetchCandidateDetails(
      userId: widget.userId,
      requesterId: widget.requesterId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _candidate = candidate;
      _isLoading = false;
    });
  }

  void _runJobMatch() {
    if (_candidate == null || _jobDescriptionController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _jobMatch = CandidateAiTools.buildJobMatch(
        candidate: _candidate!,
        jobDescription: _jobDescriptionController.text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final inset = AppResponsive.inset(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали кандидата'),
        actions: const [ThemeToggleButton()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _candidate == null
          ? const Center(
              child: Text(
                'Не удалось загрузить данные кандидата или доступ запрещен.',
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppResponsive.contentMaxWidth(
                    context,
                    desktop: 1180,
                  ),
                ),
                child: ListView(
                  padding: EdgeInsets.all(inset),
                  children: [
                    _HeroCandidateCard(candidate: _candidate!),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 960;
                        final width = stacked
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 18) / 2;
                        final interviewPack =
                            CandidateAiTools.buildInterviewPack(_candidate!);
                        final redFlags = CandidateAiTools.detectRedFlags(
                          _candidate!,
                        );

                        return Wrap(
                          spacing: 18,
                          runSpacing: 18,
                          children: [
                            _JobMatchCard(
                              width: width,
                              controller: _jobDescriptionController,
                              result: _jobMatch,
                              onRun: _runJobMatch,
                            ),
                            _InsightStackCard(
                              width: width,
                              interviewPack: interviewPack,
                              redFlags: redFlags,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle(title: 'Основной профиль'),
                    const SizedBox(height: 12),
                    _InfoCard(
                      title: 'Полное имя',
                      value: (_candidate!['fullName'] ?? '').toString(),
                    ),
                    _InfoCard(
                      title: 'Номер телефона',
                      value: (_candidate!['phoneNumber'] ?? '').toString(),
                    ),
                    _InfoCard(
                      title: 'Email',
                      value: (_candidate!['email'] ?? '').toString(),
                    ),
                    _InfoCard(
                      title: 'Сводка ценности',
                      value: (_candidate!['valueStatement'] ?? '').toString(),
                    ),
                    _InfoCard(
                      title: 'Выжимка опыта',
                      value: (_candidate!['experienceSummary'] ?? '')
                          .toString(),
                    ),
                    _InfoCard(
                      title: 'Оценка',
                      value: (_candidate!['aiScore'] ?? 0).toString(),
                    ),
                    _InfoCard(
                      title: 'Вердикт',
                      value: (_candidate!['aiVerdict'] ?? '').toString(),
                    ),
                    _ListCard(
                      title: 'Навыки',
                      items:
                          (_candidate!['skills'] as List<dynamic>? ?? const [])
                              .map((item) => item.toString())
                              .toList(),
                    ),
                    _ListCard(
                      title: 'Проекты',
                      items:
                          (_candidate!['projects'] as List<dynamic>? ??
                                  const [])
                              .map((item) => item.toString())
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _HeroCandidateCard extends StatelessWidget {
  const _HeroCandidateCard({required this.candidate});

  final Map<String, dynamic> candidate;

  @override
  Widget build(BuildContext context) {
    final score = CandidateAiTools.candidateScore(candidate);
    final shortlist = CandidateAiTools.shortlistLabel(candidate);

    return Container(
      padding: EdgeInsets.all(AppResponsive.isMobile(context) ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF7C2D12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppResponsive.heroRadius(context)),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    shortlist,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  (candidate['fullName'] ?? 'Кандидат').toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (candidate['aiVerdict'] ?? 'AI verdict пока не получен.')
                      .toString(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'AI score',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobMatchCard extends StatelessWidget {
  const _JobMatchCard({
    required this.width,
    required this.controller,
    required this.result,
    required this.onRun,
  });

  final double width;
  final TextEditingController controller;
  final JobMatchResult? result;
  final VoidCallback onRun;

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
          _SectionTitle(title: 'Симулятор совпадения с вакансией'),
          const SizedBox(height: 8),
          const Text(
            'Вставь текст вакансии и посмотри, насколько кандидат совпадает со стеком и требованиями.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            minLines: 7,
            maxLines: 10,
            decoration: InputDecoration(
              hintText:
                  'Например: Java, Spring Boot, PostgreSQL, Docker, Kafka, microservices...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRun,
            icon: const Icon(Icons.auto_graph_rounded),
            label: const Text('Запустить match'),
          ),
          if (result != null) ...[
            const SizedBox(height: 18),
            _MatchScoreBanner(score: result!.score),
            const SizedBox(height: 12),
            _MiniList(
              title: 'Сильные совпадения',
              items: result!.matchedSkills,
            ),
            const SizedBox(height: 10),
            _MiniList(
              title: 'Пробелы / чего не хватает',
              items: result!.missingSkills,
            ),
            const SizedBox(height: 10),
            Text(
              result!.summary,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              result!.recommendation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightStackCard extends StatelessWidget {
  const _InsightStackCard({
    required this.width,
    required this.interviewPack,
    required this.redFlags,
  });

  final double width;
  final List<String> interviewPack;
  final List<String> redFlags;

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
          _SectionTitle(title: 'AI-набор вопросов для интервью'),
          const SizedBox(height: 8),
          ...interviewPack.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('• $item'),
            ),
          ),
          const SizedBox(height: 10),
          _SectionTitle(title: 'Детектор красных флагов'),
          const SizedBox(height: 8),
          if (redFlags.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Критичных красных флагов не найдено. Профиль выглядит достаточно цельным.',
              ),
            )
          else
            ...redFlags.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(item),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchScoreBanner extends StatelessWidget {
  const _MatchScoreBanner({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 82
        ? const Color(0xFF059669)
        : score >= 68
        ? const Color(0xFF2563EB)
        : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.track_changes_rounded, color: color),
          const SizedBox(width: 12),
          Text(
            'Совпадение с вакансией: $score%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _MiniList extends StatelessWidget {
  const _MiniList({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('-')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(item),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(AppResponsive.isMobile(context) ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(AppResponsive.isMobile(context) ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Text('-')
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('- $item'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
