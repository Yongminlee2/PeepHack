import 'package:flutter/material.dart';

import '../strings.dart';

/// 「개발자의 다른 게임」 자리. 목록은 legal/apps.json 에서 읽어야 하므로(인터넷)
/// 광고를 붙이는 시점에 common/promo/README.md 대로 채운다.
class PromoScreen extends StatelessWidget {
  const PromoScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(S.t('promo_title'))),
        body: Center(child: Text(S.t('promo_coming'))),
      );
}
