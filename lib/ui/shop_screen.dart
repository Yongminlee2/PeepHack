import 'package:flutter/material.dart';

import '../engine/progress.dart';
import '../engine/shop.dart';
import '../strings.dart';
import 'fx/crt.dart';
import 'fx/matrix_rain.dart';
import 'theme.dart';

/// 장비 상점: 임무·브리치에서 번 크레딧으로 크랙 장비를 산다.
class ShopScreen extends StatefulWidget {
  final Progress progress;
  const ShopScreen({super.key, required this.progress});
  @override
  State<ShopScreen> createState() => _ShopState();
}

class _ShopState extends State<ShopScreen> {
  static const _icons = {'buffer': Icons.view_week, 'overclock': Icons.speed, 'jammer': Icons.wifi_tethering_off};

  Future<void> _buy(Upgrade u) async {
    final ok = await widget.progress.buy(u.id, u.price);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('shop_no_money')), duration: const Duration(seconds: 1)));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('shop_title'))),
      body: Stack(fit: StackFit.expand, children: [
        const MatrixRain(opacity: 0.12),
        const CrtOverlay(),
        ListView(padding: const EdgeInsets.all(16), children: [
          Text(S.tn('shop_credits', {'n': p.credits}),
              style: const TextStyle(color: hqOrange, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: kMono)),
          const SizedBox(height: 4),
          Text(S.t('shop_howto'), style: const TextStyle(color: hqDim, fontSize: 13)),
          const SizedBox(height: 16),
          for (final u in kUpgrades)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: const Color(0xE60B0F0C),
                shape: Border.all(color: hqGreen.withValues(alpha: p.owned.contains(u.id) ? 0.8 : 0.35)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Icon(_icons[u.id], color: hqGreen, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(S.t('upg_${u.id}'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        Text(S.t('upg_${u.id}_desc'), style: const TextStyle(color: hqDim, fontSize: 13)),
                      ]),
                    ),
                    if (p.owned.contains(u.id))
                      Text(S.t('shop_owned'), style: const TextStyle(color: hqGreen))
                    else if (p.credits >= u.price)
                      FilledButton(
                        key: Key('buy_${u.id}'),
                        onPressed: () => _buy(u),
                        child: Text(S.tn('shop_buy', {'n': u.price})),
                      )
                    else
                      // 모자라면 흐리게(누르면 「크레딧이 모자랍니다」 — 얼마가 필요한지는 보인다)
                      OutlinedButton(
                        key: Key('buy_${u.id}'),
                        style: OutlinedButton.styleFrom(foregroundColor: hqDim, side: const BorderSide(color: hqDim)),
                        onPressed: () => _buy(u),
                        child: Text(S.tn('shop_buy', {'n': u.price})),
                      ),
                  ]),
                ),
              ),
            ),
        ]),
      ]),
    );
  }
}
