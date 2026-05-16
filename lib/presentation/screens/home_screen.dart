import 'package:flutter/material.dart';

import '../../core/ui/theme_toggle_button.dart';
import 'auth_screen.dart';
import 'hiring_insights_screen.dart';
import 'profile_screen.dart';
import 'rating_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.userId, required this.role});

  final int userId;
  final String role;

  bool get _isAdmin => role == 'ADMIN';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 860;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Платформа Invision'),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Выйти',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerLowest,
              const Color(0xFFF4E4CF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                _HeroCard(userId: userId, role: role, isAdmin: _isAdmin),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    _ActionTile(
                      width: isCompact ? double.infinity : 590,
                      icon: _isAdmin
                          ? Icons.groups_2_rounded
                          : Icons.assignment_ind_rounded,
                      title: _isAdmin
                          ? 'Список кандидатов'
                          : 'Заполнить анкету',
                      subtitle: _isAdmin
                          ? 'Открой список, фильтруй профили, сравнивай кандидатов и переходи в детали.'
                          : 'Заполни анкету кандидата, чтобы система собрала сильный профиль и AI-оценку.',
                      accent: _isAdmin
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF2563EB),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _isAdmin
                                ? RatingScreen(role: role, requesterId: userId)
                                : ProfileScreen(userId: userId),
                          ),
                        );
                      },
                    ),
                    _ActionTile(
                      width: isCompact ? double.infinity : 590,
                      icon: _isAdmin
                          ? Icons.analytics_rounded
                          : Icons.leaderboard_rounded,
                      title: _isAdmin ? 'Панель отбора' : 'Посмотреть рейтинг',
                      subtitle: _isAdmin
                          ? 'Открой аналитический экран: топ-кандидаты, средний балл, сильные навыки и AI-рекомендация по найму.'
                          : 'Посмотри результаты, место в рейтинге и текущее состояние твоего профиля.',
                      accent: _isAdmin
                          ? const Color(0xFF0F766E)
                          : const Color(0xFF059669),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _isAdmin
                                ? HiringInsightsScreen(requesterId: userId)
                                : RatingScreen(role: role, requesterId: userId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    _InfoPanel(
                      width: isCompact ? double.infinity : 386,
                      icon: Icons.bolt_rounded,
                      title: 'Быстрый сценарий demo',
                      description:
                          'Открой список кандидатов, выбери двух человек, сравни их и покажи детали профиля без лишних переходов.',
                    ),
                    _InfoPanel(
                      width: isCompact ? double.infinity : 386,
                      icon: Icons.psychology_alt_rounded,
                      title: 'AI-помощь',
                      description:
                          'Платформа хранит AI score, verdict, value statement и опыт, чтобы решение выглядело объяснимым, а не случайным.',
                    ),
                    _InfoPanel(
                      width: isCompact ? double.infinity : 386,
                      icon: Icons.design_services_rounded,
                      title: 'Пространство для решений',
                      description:
                          'Главный экран сразу ведет в реальные hiring-сценарии: список кандидатов, аналитика, сравнение и AI-инструменты.',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ShowcaseStrip(isAdmin: _isAdmin),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.userId,
    required this.role,
    required this.isAdmin,
  });

  final int userId;
  final String role;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;

    return Container(
      padding: EdgeInsets.all(compact ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x221E293B),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: compact ? double.infinity : 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isAdmin
                        ? 'Пространство рекрутера'
                        : 'Пространство кандидата',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isAdmin
                      ? 'Единое пространство для отбора, анализа и сравнения кандидатов.'
                      : 'Собери сильный профиль и покажи себя платформе с лучшей стороны.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isAdmin
                      ? 'На главном экране собраны ключевые инструменты рекрутера: список кандидатов, аналитика, AI-инсайты и сценарии сравнения профилей.'
                      : 'Заполни анкету, добавь сильные стороны, опыт и проекты. Платформа соберет понятный AI-профиль и покажет твое место в рейтинге.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: compact ? double.infinity : 300,
            child: Column(
              children: [
                _HeroMetric(label: 'ID пользователя', value: '$userId'),
                const SizedBox(height: 12),
                _HeroMetric(label: 'Роль', value: role),
                const SizedBox(height: 12),
                _HeroMetric(
                  label: 'Режим',
                  value: isAdmin ? 'Администратор отбора' : 'Кандидат',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: accent, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5B6472),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward_rounded, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
  });

  final double width;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7D7C6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE7D7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFFB45309)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5B6472),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseStrip extends StatelessWidget {
  const _ShowcaseStrip({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _MiniShowcase(
            title: 'Что видно сразу',
            lines: [
              'Контекст пользователя и роли',
              'Быстрые действия',
              'Описание ключевых возможностей',
            ],
          ),
          _MiniShowcase(
            title: isAdmin ? 'Сценарий для жюри' : 'Сценарий для участника',
            lines: isAdmin
                ? [
                    'Открыть список кандидатов',
                    'Перейти в детали профиля',
                    'Сравнить двух кандидатов',
                  ]
                : [
                    'Заполнить анкету',
                    'Отправить на AI-анализ',
                    'Посмотреть рейтинг',
                  ],
          ),
          _MiniShowcase(
            title: 'Что это дает',
            lines: const [
              'Быстрый вход в demo без лишних объяснений',
              'Понятный flow для рекрутера и жюри',
              'Сильнее выглядит продуктовая ценность платформы',
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniShowcase extends StatelessWidget {
  const _MiniShowcase({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(line)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
