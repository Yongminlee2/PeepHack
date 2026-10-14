import 'package:flutter/material.dart';

import '../engine/shell.dart';
import '../sfx.dart';
import '../strings.dart';
import 'fx/juice.dart';
import 'theme.dart';

/// 칩 두 줄(명령·인자) + 입력칸 + 실행. 칩을 누르면 입력칸에 낱말이 들어간다.
/// `editable=false` 면 입력칸은 읽기 전용(칩만). 비밀번호 대기 중엔 칩을 숨기고 입력칸을 연다.
class InputBar extends StatefulWidget {
  final Suggestions suggestions;
  final bool editable;
  final bool password;
  /// 지금 있는 곳(서버:폴더). 파일 칩 위에 띄우고, 바뀌면 칩이 튀어 오른다.
  final String place;
  /// 키보드가 떠 있다 — 칩을 한 줄로. (Scaffold 안에선 키보드 높이가 0으로 보여서 바깥에서 알려 준다)
  final bool compact;
  final void Function(String line) onRun;
  const InputBar({super.key, required this.suggestions, required this.editable, required this.password, required this.onRun, this.compact = false, this.place = ''});
  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _ctl = TextEditingController();
  final _focus = FocusNode();

  @override
  void didUpdateWidget(InputBar old) {
    super.didUpdateWidget(old);
    // 칩 임무에서 비밀번호 입력이 끝나면 키보드를 내린다. 안 그러면 읽기 전용 칸에 키보드가 남는다.
    if (old.password && !widget.password && !widget.editable) _focus.unfocus();
    // 비밀번호를 물으면 바로 칠 수 있게 키보드를 띄운다.
    if (!old.password && widget.password) _focus.requestFocus();
  }

  @override
  void dispose() {
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String? _explain; // 방금 고른 명령의 쉬운 말 설명

  /// 명령 → 설명 열쇠('|' 는 cmd_pipe).
  static String cmdKey(String c) => c == '|' ? 'cmd_pipe' : 'cmd_$c';

  void _help() => showModalBottomSheet(
        context: context,
        builder: (_) => ListView(padding: const EdgeInsets.all(16), shrinkWrap: true, children: [
          Text(S.t('cmd_help_title'), style: const TextStyle(color: hqOrange, fontSize: 16)),
          const SizedBox(height: 8),
          for (final c in widget.suggestions.commands)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 80, child: Text(c, style: const TextStyle(fontFamily: kMono, color: hqGreen, fontWeight: FontWeight.w700))),
                Expanded(child: Text(S.t(cmdKey(c)))),
              ]),
            ),
        ]),
      );

  void _append(String token) {
    Sfx().play('tap');
    if (widget.suggestions.commands.contains(token)) _explain = S.t(cmdKey(token));
    setState(() => _ctl.text = '${_ctl.text}$token ');
  }

  void _run() {
    final line = _ctl.text.trim();
    _ctl.clear();
    if (line.isEmpty) return;
    Sfx().play('run');
    widget.onRun(line);
  }

  Widget _chip(String t) => ActionChip(
        key: Key('chip_$t'),
        label: Text(t),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () => _append(t),
      );

  // 평소: 줄을 바꿔 전부 보이게 한다. 옆으로 밀어야 나오는 칩은 실기기에서 아무도 못 찾았다.
  // 너무 많으면(키보드 챕터) 세 줄 높이에서 위아래로 민다.
  // 키보드가 떠 있으면: 한 줄로 옆으로 민다(어차피 손으로 치는 중이고, 터미널 자리를 남긴다).
  Widget _chips(List<String> items, {required bool compact}) => compact
      ? SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [for (final t in items) Padding(padding: const EdgeInsets.only(right: 6), child: _chip(t))]),
        )
      : ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 132),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(spacing: 6, runSpacing: 2, children: [for (final t in items) _chip(t)]),
            ),
          ),
        );

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = widget.compact;
    return Container(
        color: hqPanel,
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!widget.password && _explain != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 14, color: hqOrange),
                const SizedBox(width: 6),
                Expanded(child: Text(_explain!, style: const TextStyle(color: hqOrange, fontSize: 12))),
              ]),
            ),
          if (!widget.password) ...[
            _chips(widget.suggestions.commands, compact: keyboardOpen),
            const SizedBox(height: 6),
            if (widget.place.isNotEmpty)
              Padding(
                key: const Key('chips_place'),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
                child: Pop(
                  trigger: widget.place,
                  scale: 1.15,
                  child: Row(children: [
                    const Icon(Icons.folder_open, size: 14, color: hqOrange),
                    const SizedBox(width: 4),
                    Text(widget.place, style: const TextStyle(color: hqOrange, fontSize: 12, fontFamily: kMono, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            Pop(trigger: widget.place, scale: 1.04, child: _chips(widget.suggestions.args, compact: keyboardOpen)),
            const SizedBox(height: 6),
          ],
          Row(children: [
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const Key('input_field'),
                controller: _ctl,
                focusNode: _focus,
                readOnly: !(widget.editable || widget.password),
                // 비밀번호도 가리지 않는다(게임 속 비밀번호라 숨길 것이 없고, 한글 자판·오타를 눈으로 잡게).
                // 명령·비밀번호 모두 영어 — visiblePassword 는 대부분의 키보드에서 영문 자판으로 뜬다.
                keyboardType: TextInputType.visiblePassword,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(color: hqGreen, fontFamily: kMono),
                decoration: InputDecoration(
                  isDense: true,
                  prefixText: widget.password ? '' : '\$ ',
                  hintText: S.t(widget.password ? 'input_password_hint' : 'input_command_hint'),
                ),
                onChanged: (_) => Sfx().play('key'),
                onSubmitted: (_) => _run(),
                // 키보드 임무는 터미널처럼 계속 친다: 엔터로 실행해도 키보드를 닫지 않는다.
                textInputAction: TextInputAction.send,
                onEditingComplete: widget.editable ? () {} : null,
              ),
            ),
            IconButton(key: const Key('cmd_help'), icon: const Icon(Icons.help_outline), tooltip: S.t('cmd_help_title'), onPressed: _help),
            IconButton(key: const Key('clear_btn'), icon: const Icon(Icons.backspace_outlined), onPressed: () => setState(_ctl.clear)),
            FilledButton(key: const Key('run_btn'), onPressed: _run, child: Text(S.t('btn_run'))),
            const SizedBox(width: 8),
          ]),
        ]),
    );
  }
}

