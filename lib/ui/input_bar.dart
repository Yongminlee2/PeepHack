import 'package:flutter/material.dart';

import '../engine/shell.dart';
import '../sfx.dart';
import '../strings.dart';
import 'theme.dart';

/// 칩 두 줄(명령·인자) + 입력칸 + 실행. 칩을 누르면 입력칸에 낱말이 들어간다.
/// `editable=false` 면 입력칸은 읽기 전용(칩만). 비밀번호 대기 중엔 칩을 숨기고 입력칸을 연다.
class InputBar extends StatefulWidget {
  final Suggestions suggestions;
  final bool editable;
  final bool password;
  final void Function(String line) onRun;
  const InputBar({super.key, required this.suggestions, required this.editable, required this.password, required this.onRun});
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

  void _append(String token) {
    Sfx().play('tap');
    setState(() => _ctl.text = '${_ctl.text}$token ');
  }

  void _run() {
    final line = _ctl.text.trim();
    _ctl.clear();
    if (line.isEmpty) return;
    Sfx().play('run');
    widget.onRun(line);
  }

  // 줄을 바꿔 전부 보이게 한다. 옆으로 밀어야 나오는 칩은 실기기에서 아무도 못 찾았다.
  // 너무 많으면(키보드 챕터) 세 줄 높이에서 위아래로 민다.
  Widget _chips(List<String> items, {required bool compact}) => ConstrainedBox(
        // 키보드가 떠 있으면 한 줄만(터미널 자리를 남긴다)
        constraints: BoxConstraints(maxHeight: compact ? 40 : 132),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(spacing: 6, runSpacing: 2, children: [
              for (final t in items)
                ActionChip(
                  key: Key('chip_$t'),
                  label: Text(t),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () => _append(t),
                ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Container(
        color: hqPanel,
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!widget.password) ...[
            _chips(widget.suggestions.commands, compact: keyboardOpen),
            const SizedBox(height: 6),
            _chips(widget.suggestions.args, compact: keyboardOpen),
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
                obscureText: widget.password,
                // 명령은 영어로 친다. visiblePassword 는 대부분의 키보드에서 영문 자판으로 뜬다.
                keyboardType: widget.password ? TextInputType.text : TextInputType.visiblePassword,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(color: hqGreen, fontFamily: 'monospace'),
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
            IconButton(key: const Key('clear_btn'), icon: const Icon(Icons.backspace_outlined), onPressed: () => setState(_ctl.clear)),
            FilledButton(key: const Key('run_btn'), onPressed: _run, child: Text(S.t('btn_run'))),
            const SizedBox(width: 8),
          ]),
        ]),
    );
  }
}
