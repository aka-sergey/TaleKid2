/// Landing page assets.
/// Web:    loads from S3 network URLs.
/// Mobile: loads from bundled assets (no network needed on landing).
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LandingAssets
// ─────────────────────────────────────────────────────────────────────────────

class LandingAssets {
  LandingAssets._();

  static const String _base =
      'https://s3.twcstorage.ru/3e487a89-899c-4ef8-91e2-0900cb899801';

  // ── UI backgrounds ──────────────────────────────────────────────────────────
  static const String heroBgUrl   = '$_base/landing-assets/ui/hero-bg.png';
  static const String ctaBgUrl    = '$_base/landing-assets/ui/cta-bg.png';
  static const String howStep1Url = '$_base/landing-assets/ui/how-step1.png';
  static const String howStep2Url = '$_base/landing-assets/ui/how-step2.png';
  static const String howStep3Url = '$_base/landing-assets/ui/how-step3.png';

  static const String heroBgAsset   = 'assets/landing/ui/hero-bg.png';
  static const String ctaBgAsset    = 'assets/landing/ui/cta-bg.png';
  static const String howStep1Asset = 'assets/landing/ui/how-step1.png';
  static const String howStep2Asset = 'assets/landing/ui/how-step2.png';
  static const String howStep3Asset = 'assets/landing/ui/how-step3.png';

  // Resolved getters — используй их везде
  static String get heroBg   => kIsWeb ? heroBgUrl   : heroBgAsset;
  static String get ctaBg    => kIsWeb ? ctaBgUrl    : ctaBgAsset;
  static String get howStep1 => kIsWeb ? howStep1Url : howStep1Asset;
  static String get howStep2 => kIsWeb ? howStep2Url : howStep2Asset;
  static String get howStep3 => kIsWeb ? howStep3Url : howStep3Asset;

  // ── Showcase story IDs ──────────────────────────────────────────────────────
  static const String tale1Id = 'e85f654c-d2d5-44e6-8160-8861bded01c0';
  static const String tale2Id = 'c7d27217-0c83-47a4-abfe-903aafaed86b';
  static const String tale3Id = '1a31734f-350b-4247-8acd-473dd3f2550d';
  static const String tale4Id = '5a24c43f-1822-4d5c-aa14-bbf81016f1da';

  // ── Showcase covers ─────────────────────────────────────────────────────────
  static const String tale1CoverUrl = '$_base/stories/$tale1Id/cover.png';
  static const String tale2CoverUrl = '$_base/stories/$tale2Id/cover.png';
  static const String tale3CoverUrl = '$_base/stories/$tale3Id/cover.png';
  static const String tale4CoverUrl = '$_base/stories/$tale4Id/cover.png';

  static const String tale1CoverAsset = 'assets/landing/stories/tale1/cover.png';
  static const String tale2CoverAsset = 'assets/landing/stories/tale2/cover.png';
  static const String tale3CoverAsset = 'assets/landing/stories/tale3/cover.png';
  static const String tale4CoverAsset = 'assets/landing/stories/tale4/cover.png';

  static String get tale1Cover => kIsWeb ? tale1CoverUrl : tale1CoverAsset;
  static String get tale2Cover => kIsWeb ? tale2CoverUrl : tale2CoverAsset;
  static String get tale3Cover => kIsWeb ? tale3CoverUrl : tale3CoverAsset;
  static String get tale4Cover => kIsWeb ? tale4CoverUrl : tale4CoverAsset;

  // ── Page images ─────────────────────────────────────────────────────────────
  static List<String> _remotePages(String storyId) =>
      List.generate(10, (i) => '$_base/stories/$storyId/pages/${i + 1}.png');

  static List<String> _localPages(String taleKey) =>
      List.generate(10, (i) => 'assets/landing/stories/$taleKey/pages/${i + 1}.png');

  static List<String> get tale1Pages =>
      kIsWeb ? _remotePages(tale1Id) : _localPages('tale1');
  static List<String> get tale2Pages =>
      kIsWeb ? _remotePages(tale2Id) : _localPages('tale2');
  static List<String> get tale3Pages =>
      kIsWeb ? _remotePages(tale3Id) : _localPages('tale3');
  static List<String> get tale4Pages =>
      kIsWeb ? _remotePages(tale4Id) : _localPages('tale4');

  // ── Style covers ────────────────────────────────────────────────────────────
  static const List<String> _styleCoversUrls = [
    '$_base/landing-assets/styles/watercolor.png',
    '$_base/landing-assets/styles/3d-pixar.png',
    '$_base/landing-assets/styles/disney.png',
    '$_base/landing-assets/styles/comic.png',
    '$_base/landing-assets/styles/anime.png',
    '$_base/landing-assets/styles/pastel.png',
    '$_base/landing-assets/styles/classic-book.png',
    '$_base/landing-assets/styles/pop-art.png',
  ];

  static const List<String> _styleCoversAssets = [
    'assets/landing/styles/watercolor.png',
    'assets/landing/styles/3d-pixar.png',
    'assets/landing/styles/disney.png',
    'assets/landing/styles/comic.png',
    'assets/landing/styles/anime.png',
    'assets/landing/styles/pastel.png',
    'assets/landing/styles/classic-book.png',
    'assets/landing/styles/pop-art.png',
  ];

  static List<String> get styleCovers =>
      kIsWeb ? _styleCoversUrls : _styleCoversAssets;

  static const List<String> styleNames = [
    'Акварель',
    '3D Анимация (Pixar)',
    'Disney',
    'Комикс',
    'Аниме',
    'Пастель',
    'Книжная классика',
    'Поп-арт',
  ];

  // ── Page texts ──────────────────────────────────────────────────────────────
  static const List<String> tale1Texts = [
    'Жила-была девочка Маша. Ей было четыре года, и она носила красное пальто с мехом. Однажды мама попросила её принести подснежники из зимнего леса.',
    'Маша одела красные варежки и пошла в лес. Вокруг было много снега и очень холодно. Девочка шла, любуясь белыми снежинками.',
    'Вдруг она увидела костёр и вокруг него двенадцать людей. Это были братья-Месяцы, каждый со своей волшебной силой.',
    'Маша поздоровалась со всеми и спросила, могут ли они помочь ей найти подснежники. Месяцы улыбнулись и вызвали апрель.',
    'Апрель взмахнул рукой, и снег начал таять. Подснежники выглянули из-под снега, расцветая вокруг.',
    'Маша поблагодарила братьев и собрала букет цветов. Она чувствовала себя очень счастливой.',
    'Девочка побежала домой, держа цветы в руках. Лес теперь казался ей волшебным.',
    'Когда Маша вернулась домой, мама была очень удивлена. Подснежники были такими красивыми!',
    'Мама похвалила Машу за её доброту и смелость. Девочка улыбалась и думала о новых друзьях из леса.',
    'С тех пор Маша всегда верила в чудеса. Ведь главное — это доброта и верность своим друзьям.',
  ];

  static const List<String> tale2Texts = [
    'Жил-был мальчик Дима. У него были рыжие вихрастые волосы, веснушки и зелёные глаза. Он очень любил играть со своим пушистым серым котом Барсиком.',
    'Однажды Дима решил построить ракету из большой картонной коробки. Он позвал Барсика, и они начали строить.',
    'Когда ракета была готова, она вдруг ожила! Дима и Барсик сели внутрь и полетели в космос.',
    'Ракета мчалась мимо планет и звёзд. Дима увидел красную планету — это Марс!',
    'Вдруг они встретили добрых инопланетян. Инопланетяне помахали Диме и Барсику и пригласили их на пикник.',
    'На пикнике Дима узнал, что одна из звёзд сломалась и больше не светит. Он решил помочь её починить.',
    'Дима и Барсик полетели к звезде и нашли, что она просто устала светить. Они её развеселили, и она снова засияла.',
    'Настало время возвращаться домой, но Дима не знал дорогу. Инопланетяне подсказали найти Полярную звезду.',
    'Следуя за Полярной звездой, ракета быстро добралась до дома. Дима и Барсик были счастливы вернуться.',
    'Дома Дима и Барсик уснули, мечтая о новых приключениях. Ведь космос — такой удивительный!',
  ];

  static const List<String> tale3Texts = [
    'В глубоком океане жила маленькая русалочка Алиса. У неё были длинные тёмные волосы и карие глаза. Однажды она заметила, что коралловый дворец стал терять свои яркие краски.',
    'Алиса решила помочь дворцу вернуть его цвета. Её верный друг, золотистый морской конёк Лучик, согласился отправиться с ней в путешествие.',
    'Первым делом они встретили мудрую черепаху Торту. Она рассказала, что волшебные жемчужины помогут вернуть цвета.',
    'Алиса и Лучик поплыли дальше и встретили осьминога Оливера. Он подарил им первую жемчужину.',
    'Затем они встретили дельфина Дэна, который тоже подарил им жемчужину. Дэн любил играть и прыгать из воды.',
    'В пути Алиса узнала, что звезда морская по имени Зара прячет свои жемчужины под песком. Она поделилась одной с Алисой.',
    'Когда они собрали все жемчужины, Алиса вернулась к дворцу. Она разложила их вокруг, и дворец снова засиял яркими красками.',
    'Все обитатели моря собрались полюбоваться красотой дворца. Они благодарили Алису и Лучика за помощь.',
    'Алиса предложила устроить праздник. Все веселились, танцевали и играли в прятки среди разноцветных кораллов.',
    'После праздника Алиса и Лучик попрощались с друзьями. Они вернулись домой, зная, что теперь коралловый дворец снова радует всех.',
  ];

  static const List<String> tale4Texts = [
    'Жил-был мальчик Тимофей. У него были короткие чёрные волосы и смелые тёмные глаза. Однажды он нашёл в шкафу дедушки волшебный плащ.',
    'Тимофей надел плащ и почувствовал себя сильным и лёгким. Он надел жёлто-синий костюм с буквой «Т» на груди и синюю маску. Теперь он выглядел как настоящий супергерой!',
    'Сначала Тимофей решил испытать свою суперсилу на улице. Он увидел котёнка, который застрял на дереве. Тимофей взлетел и аккуратно снял котёнка.',
    'На другой улице Тимофей увидел бабушку, которой было тяжело нести сумки. Он помог ей донести их до дома.',
    'Потом Тимофей заметил маленькую девочку, у которой улетел воздушный шарик. Он догнал шарик и вернул его девочке.',
    'Вечером Тимофей вернулся домой. Он рассказал маме о своих подвигах. Мама обняла его и сказала, что у него доброе сердце.',
    'Тимофей задумался, что значит быть настоящим супергероем. Он понял, что суперсила — это доброе сердце и помощь другим.',
    'Теперь Тимофей знал, что даже без плаща он может быть супергероем. Главное — помогать и заботиться о других.',
    'Каждый день приносил новые приключения и новые возможности для добрых дел. Тимофей был готов помогать снова и снова.',
    'Так Тимофей стал самым добрым супергероем в городе. И все знали, что у него самое доброе сердце.',
  ];

  // ── Titles ──────────────────────────────────────────────────────────────────
  static const String tale1Title = 'Маша и Двенадцать Месяцев';
  static const String tale2Title = 'Дима и Звёздный Кот';
  static const String tale3Title = 'Алиса и Коралловое Королевство';
  static const String tale4Title = 'Супергерой Тимофей';
}

// ─────────────────────────────────────────────────────────────────────────────
// LandingImage — универсальный виджет для изображений лендинга
// Web:    Image.network  (S3 URL)
// Mobile: Image.asset    (bundled, мгновенно)
// ─────────────────────────────────────────────────────────────────────────────

class LandingImage extends StatelessWidget {
  /// Передавай resolved геттер из LandingAssets:
  ///   LandingImage(src: LandingAssets.heroBg, ...)
  /// На web — https:// URL, на mobile — assets/... путь.
  final String src;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  const LandingImage({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => errorWidget ?? const SizedBox.shrink(),
      );
    } else {
      return Image.asset(
        src,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => errorWidget ?? const SizedBox.shrink(),
      );
    }
  }
}
