import '../../../l10n/app_localizations.dart';

typedef DemoArticle = ({
  String title,
  String category,
  String body,
  int minutes,
  String image,
  String date,
});

List<DemoArticle> demoArticles(AppLocalizations strings) => [
  (
    title: strings.listening,
    category: strings.communication,
    body: strings.listeningBody,
    minutes: 5,
    image: 'listening',
    date: '2024-03-10',
  ),
  (
    title: strings.loveLanguages,
    category: strings.psychology,
    body: strings.loveBody,
    minutes: 6,
    image: 'love',
    date: '2024-03-05',
  ),
  (
    title: strings.forgiveness,
    category: strings.psychology,
    body: strings.forgivenessBody,
    minutes: 4,
    image: 'forgiveness',
    date: '2024-03-15',
  ),
  (
    title: strings.vision,
    category: strings.dailyLife,
    body: strings.visionBody,
    minutes: 8,
    image: 'vision',
    date: '2024-02-28',
  ),
];
