import 'package:flutter/material.dart';

import '../engine/progress.dart';
import '../strings.dart';

class SettingsScreen extends StatefulWidget {
  final Progress progress;
  const SettingsScreen({super.key, required this.progress});
  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  void _rebuild() => setState(() {});

  @override
  void initState() {
    super.initState();
    AppLang().addListener(_rebuild);
  }

  @override
  void dispose() {
    AppLang().removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLang().value;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('settings_title'))),
      body: ListView(children: [
        SwitchListTile(
          key: const Key('set_sound'),
          title: Text(S.t('settings_sound')),
          value: widget.progress.soundOn,
          onChanged: (v) async { await widget.progress.setSound(v); setState(() {}); },
        ),
        SwitchListTile(
          key: const Key('set_vibration'),
          title: Text(S.t('settings_vibration')),
          value: widget.progress.vibrationOn,
          onChanged: (v) async { await widget.progress.setVibration(v); setState(() {}); },
        ),
        ListTile(title: Text(S.t('settings_language'))),
        for (final code in ['system', ...kLanguageOrder])
          ListTile(
            // 그 언어 글자로 적는다. 번역하지 않는다. (RadioListTile 은 3.3x 에서 deprecated 라 쓰지 않는다)
            title: Text(code == 'system' ? S.t('settings_follow_system') : kLanguageNames[code]!),
            trailing: lang == code ? const Icon(Icons.check) : null,
            onTap: () => AppLang().set(code),
          ),
        const Divider(),
        ListTile(
          title: Text(S.t('btn_reset')),
          onTap: () async {
            final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
              content: Text(S.t('confirm_reset')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: Text(S.t('btn_close'))),
                TextButton(onPressed: () => Navigator.pop(c, true), child: Text(S.t('btn_check'))),
              ],
            ));
            if (ok == true) await widget.progress.reset();
          },
        ),
      ]),
    );
  }
}
