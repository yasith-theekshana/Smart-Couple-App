import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/design_system.dart';
import '../data/demo_articles.dart';

class ArticleLibrary extends StatefulWidget {
  const ArticleLibrary({super.key});

  @override
  State<ArticleLibrary> createState() => _ArticleLibraryState();
}

class _ArticleLibraryState extends State<ArticleLibrary> {
  int _category = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final categories = [s.all, s.communication, s.psychology, s.dailyLife];
    final articles = demoArticles(context.strings);
    return Scaffold(
      body: AppPage(
        children: [
          AppHeader(title: s.articles),
          Text(s.library, style: AppTypography.heading(26)),
          const SizedBox(height: 5),
          AppLabel(s.coupleSkills, color: AppColors.muted),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < categories.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(categories[i]),
                      selected: i == _category,
                      showCheckmark: false,
                      selectedColor: AppColors.cream,
                      onSelected: (_) => setState(() => _category = i),
                    ),
                  ),
              ],
            ),
          ),
          for (final (index, article) in articles.indexed)
            if (_category == 0 || article.category == categories[_category])
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ArticlePreview(index: index),
              ),
        ],
      ),
    );
  }
}

class ArticlePreview extends StatelessWidget {
  const ArticlePreview({required this.index, this.featured = false, super.key});
  final int index;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final article = demoArticles(context.strings)[index];
    final s = context.strings;
    void open() => context.push('/articles/$index', extra: featured);
    if (!featured) {
      return AppCard(
        onTap: open,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                'assets/images/${article.image}.jpg',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLabel(article.category, color: AppColors.gold),
                  const SizedBox(height: 3),
                  Text(article.title, style: AppTypography.heading(17)),
                  const SizedBox(height: 5),
                  AppLabel(
                    '${article.minutes} min  •  ${s.read}',
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      border: AppColors.gold,
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 164,
                child: Image.asset(
                  'assets/images/${article.image}.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: 15,
                bottom: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      article.category.toUpperCase(),
                      style: AppTypography.label(Colors.white, 9),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title, style: AppTypography.heading(22)),
                const SizedBox(height: 7),
                Text(s.listeningIntro),
                const SizedBox(height: 10),
                AppLabel(s.readArticle, color: AppColors.gold),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ArticleDetail extends StatelessWidget {
  const ArticleDetail({required this.index, this.fromHome = false, super.key});
  final int index;
  final bool fromHome;

  void _openLibrary(BuildContext context) {
    if (!context.canPop()) {
      context.go('/articles');
    } else if (fromHome) {
      context.pushReplacement('/articles');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final article = demoArticles(s)[index];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _openLibrary(context),
                      icon: const Icon(Icons.chevron_left, size: 17),
                      label: AppLabel(s.library),
                    ),
                    Expanded(child: Center(child: AppLabel(s.read))),
                    const SizedBox(width: 68),
                  ],
                ),
                Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 245,
                      child: Image.asset(
                        'assets/images/${article.image}.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.74),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              child: AppLabel(
                                article.category,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            article.title,
                            style: AppTypography.heading(26)
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppLabel(
                        '${article.minutes} min  •  ${article.date}',
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.line),
                      const SizedBox(height: 15),
                      if (index == 0) ...[
                        DecoratedBox(
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: AppColors.gold, width: 4),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            child: Text(
                              s.listeningIntro,
                              style: AppTypography.heading(19)
                                  .copyWith(height: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                      Text(
                        article.body,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.65,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.line),
                      AppButton(
                        s.library,
                        outlined: true,
                        onPressed: () => _openLibrary(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
