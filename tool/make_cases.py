# -*- coding: utf-8 -*-
"""사건 파일 12개(assets/cases/c01..c12.json)와 그 문장(ko·en)을 만든다.
로그·메일 원문은 영어 그대로(번역 안 함), 사람이 읽는 글은 @열쇠.
프로젝트 루트에서: python tool/make_cases.py

난이도 원칙(사람 플레이: "단서를 다 안 봐도 맞힌다"):
- 자료 하나로는 안 풀린다. 기록에는 계정·카드·기기 번호와 IP 만, 이름 표는 다른 자료(대개 잠김)에.
- 함정을 하나 이상: 시계 오차, 세계 표준시, 같은 옷, 조작된 작성자, 같은 이름의 와이파이, 엉뚱한 워터마크.
- 자백하는 자료는 없다. 보기는 다 그럴듯하게.
- 1~6번: 질문 3·보기 4. 7~12번: 질문 4~5·보기 5~6. 세 번 틀리면 사건 실패.
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

KO, EN = {}, {}
CASES = []


def t(key, ko, en):
    KO[key], EN[key] = ko, en
    return '@' + key


def case(cid, title, brief, done, docs, questions):
    CASES.append({
        'id': cid,
        'title': t(f'{cid}_title', *title),
        'brief': [t(f'{cid}_brief_{i + 1}', *b) for i, b in enumerate(brief)],
        'done': [t(f'{cid}_done_{i + 1}', *d) for i, d in enumerate(done)],
        'docs': docs,
        'questions': questions,
    })


def q(cid, n, text, options, answer):
    opts = [o if isinstance(o, str) else t(f'{cid}_q{n}_o{i + 1}', *o) for i, o in enumerate(options)]
    return {'q': t(f'{cid}_q{n}', *text), 'options': opts, 'answer': answer}


def doc(cid, name, ko=None, en=None, raw=None, lock=None):
    d = {'name': name, 'text': raw if raw is not None else t(f'{cid}_d_{re.sub(r"[^a-z0-9]", "_", name.lower())}', ko, en)}
    if lock:
        d['lock'] = {'length': lock}
    return d


# ================================================================ c01 — 이름 대신 계정 번호
case('c01',
     ('새어 나간 쿠폰', 'The Leaked Coupon'),
     [('쇼핑몰 직원 전용 90% 할인 쿠폰 목록이 10월 12일 밤 커뮤니티에 파일째 올라왔다.',
       'The staff-only 90% coupon list showed up on a forum as a file on the night of Oct 12.'),
      ('쿠폰은 관리자 화면에서만 볼 수 있다. 누가, 어디서 빼냈는지 찾아 줘.',
       'Coupons are only visible on the admin page. Find out who took it, and from where.')],
     [('A-105, 민호였다. 쉬는 날 집에서 VPN 으로 들어와 목록을 파일로 뽑았다. 서연은 근무 중에 보기만 했을 뿐이고.',
       'A-105, Minho. On his day off he came in over the VPN from home and exported the list. Seoyeon only viewed it during her shift.')],
     [
         doc('c01', 'admin_access.log', raw='10-12 18:02 view    coupon_list      acct=A-102 ip=10.0.0.21\n'
             '10-12 20:15 view    orders           acct=A-107 ip=10.0.0.23\n'
             '10-12 21:47 view    coupon_list      acct=A-105 ip=172.16.4.9\n'
             '10-12 21:49 export  coupon_list.csv  acct=A-105 ip=172.16.4.9\n'
             '10-12 21:58 view    coupon_list      acct=A-107 ip=10.0.0.23'),
         doc('c01', 'forum_post.txt', '익명(22:03): 직원 쿠폰 통째로 풉니다 ㅋㅋ 첨부: coupon_list.csv',
             'Anonymous (22:03): dumping the whole staff coupon list lol. Attachment: coupon_list.csv'),
         doc('c01', 'network_note.txt', '전산팀: 사무실 안 PC 는 10.0.0.x 주소를 받는다. 밖에서 VPN 으로 들어오면 172.16.x.x 가 찍힌다.',
             'IT: office PCs get 10.0.0.x addresses. Anyone coming in from outside over the VPN shows up as 172.16.x.x.'),
         doc('c01', 'shift.csv', raw='name,10-12\njiwoo,09:00-18:30\nminho,off\nseoyeon,13:00-22:00\ndongha,22:00-06:00'),
         doc('c01', 'accounts.csv', raw='acct,name\nA-102,jiwoo\nA-105,minho\nA-107,seoyeon\nA-110,dongha', lock=5),
     ],
     [
         q('c01', 1, ('쿠폰 목록을 파일로 빼낸 계정은?', 'Which account exported the coupon list as a file?'),
           ['A-102', 'A-105', 'A-107', 'A-110'], 1),
         q('c01', 2, ('그 계정의 주인은?', 'Who owns that account?'), ['seoyeon', 'dongha', 'minho', 'jiwoo'], 2),
         q('c01', 3, ('그는 어디서 접속했나?', 'Where did he connect from?'),
           [('근무 중에 사무실 자리에서', 'From his office desk, during his shift'),
            ('쉬는 날 밖에서 VPN 으로', 'From outside over the VPN, on his day off'),
            ('야간 근무 중에 사무실에서', 'From the office, on the night shift'),
            ('다른 직원 자리에서', "From another employee's desk")], 1),
     ])

# ================================================================ c02 — 세계 표준시와 기기 주인
case('c02',
     ('새벽 3시의 로그인', 'The 3 A.M. Login'),
     [('재무팀 공용 계정 finance01 이 일본 IP 로 로그인해 급여 파일을 내려받았다.',
       'The shared finance account finance01 logged in from a Japanese IP and downloaded the payroll file.'),
      ('그 무렵 일본에 다녀온 직원이 둘이다. 해킹인지, 둘 중 누구인지 가려 줘.',
       'Two employees were in Japan around then. Tell me whether it is a hack, and if not, which one.')],
     [('기록은 세계 표준시였다. 한국 시간으로 11일 새벽 3시 12분, 하은 씨는 이미 귀국한 뒤였고 인증은 서준 씨 폰에서 통과됐다.',
       "The log was in UTC. In Korean time it was 3:12 a.m. on the 11th — Ha-eun was already home, and the approval came from Seojun's phone."),
      ('공용 계정은 이제 사람마다 따로 쓰게 바꿨다.', 'The shared account has since been split into personal ones.')],
     [
         doc('c02', 'auth.log', raw='2026-10-10T09:05Z login ok  user=finance01 ip=10.1.1.4     geo=KR device=FIN-PC-02\n'
             '2026-10-10T18:12Z login ok  user=finance01 ip=203.0.113.50 geo=JP 2fa=push device=FIN-PHONE-07\n'
             '2026-10-10T18:40Z download  payroll.xlsx user=finance01'),
         doc('c02', 'server_note.txt', '전산팀: auth.log 의 시각은 세계 표준시(UTC, 끝의 Z)다. 한국과 일본은 둘 다 UTC+9.',
             'IT: times in auth.log are UTC (the trailing Z). Korea and Japan are both UTC+9.'),
         doc('c02', 'calendar.txt', '박서준: 10/9 ~ 10/13 오사카 출장\n김하은: 10/6 ~ 10/10 도쿄 출장 (10/10 오후 비행기로 귀국)',
             'Park Seojun: business trip to Osaka 10/9-10/13\nKim Ha-eun: business trip to Tokyo 10/6-10/10 (flies home the afternoon of 10/10)'),
         doc('c02', 'team_chat.txt', '팀장: 결산 마감, 11일 아침까지예요. / 하은: 저는 오늘 귀국이라 내일 출근해서 할게요. / 서준: 저는 호텔에서 밤에 끝낼게요.',
             "Manager: the closing is due by the morning of the 11th. / Ha-eun: I fly home today, I'll do mine tomorrow at the office. / Seojun: I'll finish mine tonight from the hotel."),
         doc('c02', 'device_list.csv', raw='device,owner\nFIN-PC-02,shared\nFIN-PHONE-03,kim.haeun\nFIN-PHONE-07,park.seojun', lock=6),
     ],
     [
         q('c02', 1, ('일본 IP 로그인을 한국 시간으로 바꾸면?', 'What is the Japanese-IP login in Korean time?'),
           [('10월 10일 18:12', 'Oct 10, 18:12'), ('10월 11일 03:12', 'Oct 11, 03:12'), ('10월 10일 09:12', 'Oct 10, 09:12'), ('10월 11일 12:12', 'Oct 11, 12:12')], 1),
         q('c02', 2, ('로그인한 사람은?', 'Who logged in?'),
           [('외부 공격자', 'An outside attacker'), ('김하은', 'Kim Ha-eun'), ('박서준', 'Park Seojun'), ('팀장', 'The manager')], 2),
         q('c02', 3, ('가장 결정적인 증거는?', 'What is the strongest evidence?'),
           [('IP 가 일본이다', 'The IP is in Japan'), ('출장 일정', 'The trip schedule'), ('팀 채팅', 'The team chat'),
            ('2단계 인증을 통과한 기기의 주인', 'The owner of the device that passed two-factor')], 3),
     ])

# ================================================================ c03 — 주소의 진짜 주인, 누르기와 넣기
case('c03',
     ('가짜 결제 메일', 'The Fake Payment Mail'),
     [('직원들에게 결제 메일이 네 통 왔다. 그중 하나가 피싱이고, 누군가 거기에 비밀번호를 넣었다.',
       'Staff received four payment mails. One is phishing, and someone typed a password into it.'),
      ('가짜를 찾고, 비밀번호까지 넣은 사람을 알아내 줘.', 'Find the fake, and who actually entered a password.')],
     [('주소의 주인은 맨 끝 두 마디, billing-center.net 이었다. 하나 씨는 비밀번호를 넣었고, 준 씨는 열어만 봤다.',
       'The real owner of an address is its last two parts: billing-center.net. Hana entered her password; Jun only opened the page.')],
     [
         doc('c03', 'mail_1.eml', raw='From: "PayPal" <service@paypal.com>\nSubject: Your invoice #8812\nLink: https://www.paypal.com/invoice/8812'),
         doc('c03', 'mail_2.eml', raw='From: "PayPaI Billing" <billing@paypal.com>\nSubject: Receipt\nLink: https://www.paypal.com/receipt/5521'),
         doc('c03', 'mail_3.eml', raw='From: <noreply@paypal.com.billing-center.net>\nSubject: Payment on hold - verify now\nLink: https://paypal.com.billing-center.net/verify'),
         doc('c03', 'mail_4.eml', raw='From: <receipts@paypal.com>\nSubject: Receipt for your payment\nLink: https://www.paypal.com/receipt/7710'),
         doc('c03', 'security_tip.txt', '보안팀: 주소의 진짜 주인은 맨 끝 두 마디(○○.com, ○○.net)다. 앞에 무엇이 붙든 상관없다. 보낸 사람 「표시 이름」은 아무나 아무렇게나 쓸 수 있다.',
             'Security: the real owner of an address is its last two parts (xx.com, xx.net), whatever comes before. The sender display name can be anything anyone types.'),
         doc('c03', 'staff.csv', raw='uid,name\nu17,jun\nu23,hana\nu31,mina\nu40,dohyun'),
         doc('c03', 'proxy.log', raw='09:02 GET  www.paypal.com/invoice/8812             uid=u31\n'
             '09:14 GET  paypal.com.billing-center.net/verify   uid=u23\n'
             '09:15 POST paypal.com.billing-center.net/verify   uid=u23\n'
             '09:41 GET  paypal.com.billing-center.net/verify   uid=u17', lock=5),
     ],
     [
         q('c03', 1, ('피싱 메일은?', 'Which mail is phishing?'), ['mail_1', 'mail_2', 'mail_3', 'mail_4'], 2),
         q('c03', 2, ('그렇게 본 근거는?', 'What gives it away?'),
           [('표시 이름 철자가 이상하다(PayPaI)', 'The display name is misspelled (PayPaI)'),
            ('주소 맨 끝 두 마디가 billing-center.net 이다', 'The last two parts of the address are billing-center.net'),
            ('링크가 https 로 시작한다', 'The link starts with https'), ('제목이 급하다', 'The subject sounds urgent')], 1),
         q('c03', 3, ('비밀번호까지 넣은 직원은?', 'Who actually entered a password?'), ['jun', 'mina', 'dohyun', 'hana'], 3),
     ])

# ================================================================ c04 — 작성자 이름은 조작된다
case('c04',
     ('지워진 커밋', 'The Deleted Commit'),
     [('배포 서버의 비밀 키가 깃 저장소에 올라갔다가 지워졌다. 기록에는 전부 다혜 이름뿐이다.',
       "The deploy server's secret key was pushed to the git repo, then removed. The log shows nothing but Dahye's name."),
      ('정말 다혜인지, 누가 올렸는지 찾아 줘.', 'Is it really Dahye? Find out who pushed it.')],
     [('커밋 작성자 이름은 누구나 적을 수 있다. 서버에 올린 SSH 키는 태호 노트북 것이었다. 다혜는 발견해서 지운 쪽이었고.',
       "Anyone can type any author name on a commit. The SSH key that pushed it was Taeho's laptop. Dahye was the one who found it and removed it.")],
     [
         doc('c04', 'git_log.txt', raw='f7a1  10-02 10:11  author=dahye  add login page\n'
             'a91c  10-02 18:30  author=taeho  update readme\n'
             'c3d9  10-02 23:48  author=dahye  fix typo\n'
             'b2e0  10-03 09:02  author=dahye  remove leaked file'),
         doc('c04', 'git_show_c3d9.txt', raw='commit c3d9  fix typo\n  README.md          | 1 -\n+ config/deploy.key  | 27 +++\n+ -----BEGIN PRIVATE KEY-----'),
         doc('c04', 'push_log.txt', raw='10-02 10:12 push f7a1 key=SHA256:Mx9e\n10-02 18:31 push a91c key=SHA256:Kq7b\n'
             '10-02 23:49 push c3d9 key=SHA256:Zt2c\n10-03 09:03 push b2e0 key=SHA256:Mx9e'),
         doc('c04', 'git_note.txt', '팀 규칙: 커밋의 author 이름은 각자 컴퓨터 설정이라 마음대로 바꿀 수 있다. 실제로 서버에 올린 사람은 push 기록의 SSH 키로 본다.',
             'Team rule: a commit author name is just a local setting anyone can change. Who actually pushed to the server is told by the SSH key in the push log.'),
         doc('c04', 'chat.txt', '다혜: 아침에 키 파일 보고 바로 지웠어요. 근데 제 이름으로 올라가 있어서 놀랐어요. / 태호: 어젯밤엔 집에서 쉬었어요.',
             "Dahye: I saw a key file this morning and removed it right away. But it was under my name, which shocked me. / Taeho: I was resting at home last night."),
         doc('c04', 'ssh_keys.txt', raw='SHA256:Mx9e  dahye  (work laptop)\nSHA256:Kq7b  taeho  (office desktop)\n'
             'SHA256:Zt2c  taeho  (home laptop)\nSHA256:Pp1a  junho  (work laptop)', lock=6),
     ],
     [
         q('c04', 1, ('키 파일이 들어간 커밋은?', 'Which commit added the key file?'), ['f7a1', 'a91c', 'c3d9', 'b2e0'], 2),
         q('c04', 2, ('실제로 올린 사람은?', 'Who actually pushed it?'), ['dahye', 'taeho', 'junho', ('알 수 없음', 'Unknown')], 1),
         q('c04', 3, ('그렇게 본 근거는?', 'What shows it?'),
           [('채팅 내용', 'The chat'), ('커밋 시각', 'The commit time'), ('커밋 작성자 이름', 'The commit author name'),
            ('push 기록의 SSH 키 주인', 'The owner of the SSH key in the push log')], 3),
     ])

# ================================================================ c05 — 빠른 시계, 같은 옷
case('c05',
     ('저녁 7시 40분의 인쇄', 'The 7:40 P.M. Print'),
     [('기밀 문서 merger_plan.pdf 가 인쇄되어 밖으로 나갔다. 인쇄 기록에는 guest 라고만 찍혔다.',
       'The confidential merger_plan.pdf was printed and walked out. The printer log only says guest.'),
      ('출입 기록과 메모로 누가 인쇄했는지 밝혀 줘. 회색 후드를 입은 사람이 둘이다.',
       'Use the badge log and notes to find who printed it. Two people wore gray hoodies.')],
     [('프린터 시계가 12분 빨랐다. 실제 인쇄는 19:40, 그때 3층에 있던 회색 후드는 최 대리뿐이다. 강 사원은 19:44 에 들어왔다.',
       'The printer clock ran 12 minutes fast. The real print time was 19:40, and the only gray hoodie on the third floor then was Choi. Kang came in at 19:44.')],
     [
         doc('c05', 'printer.log', raw='19:52 print merger_plan.pdf user=guest pages=12 printer=3F-B'),
         doc('c05', 'maint_memo.txt', '시설팀 메모: 3F-B 프린터 시계가 12분 빠름. 다음 점검 때 맞출 것.',
             'Facilities memo: the clock on printer 3F-B runs 12 minutes fast. Fix at next service.'),
         doc('c05', 'badge.log', raw='19:31 3F in   card=0418\n19:36 3F in   card=0722\n19:44 3F in   card=0913\n'
             '19:47 3F out  card=0722\n20:02 3F out  card=0913\n20:30 3F out  card=0418'),
         doc('c05', 'guard_note.txt', '경비 메모: 19:38 ~ 19:43 (경비실 시계) 3층 B 프린터 앞에 한 사람만 서 있었다. 회색 후드.',
             'Guard note: 19:38-19:43 (guard room clock), only one person stood at printer 3F-B. Gray hoodie.'),
         doc('c05', 'team_chat.txt', '최: 오늘 회색 후드 입고 왔는데 사무실 춥다 / 강: 헐 나도 회색 후드 ㅋㅋ / 윤: 난 정장',
             "Choi: wore my gray hoodie today, office is cold / Kang: no way, me too lol / Yoon: I'm in a suit"),
         doc('c05', 'cards.csv', raw='card,name\n0418,yoon\n0722,choi\n0913,kang\n1201,seo', lock=6),
     ],
     [
         q('c05', 1, ('실제 인쇄 시각은?', 'What was the real print time?'), ['19:28', '19:40', '19:52', '20:04'], 1),
         q('c05', 2, ('인쇄한 사람은?', 'Who printed it?'),
           [('윤', 'Yoon'), ('강', 'Kang'), ('최', 'Choi'), ('서', 'Seo')], 2),
         q('c05', 3, ('강을 범인에서 빼는 근거는?', 'What rules Kang out?'),
           [('회색 후드를 입지 않았다', 'Kang was not wearing a gray hoodie'), ('인쇄 때 아직 3층에 들어오지 않았다', 'Kang had not entered the third floor yet at print time'),
            ('출입 카드가 없다', 'Kang has no badge'), ('정장을 입었다', 'Kang was in a suit')], 1),
     ])

# ================================================================ c06 — 링크 둘, 바뀐 순서
case('c06',
     ('털린 SNS 계정', 'The Hijacked Account'),
     [('친구 수아의 SNS 계정이 남의 손에 넘어가 「코인 투자」 광고가 올라오고 있다.',
       "My friend Suah's social account was taken over and is posting crypto ads."),
      ('수아는 그날 밤 링크 두 개를 눌렀다고 한다. 어디서 털렸는지, 지금 무엇부터 해야 하는지 알려 줘.',
       'Suah says she tapped two links that night. Find where it leaked and what she should do first.')],
     [('비밀번호는 가짜 고객센터에 넘어갔다. 범인은 비밀번호부터 바꾸고 이메일까지 바꿨다. 원래 이메일로 온 「변경 취소」 링크로 이메일부터 되찾았다.',
       'The password went to the fake help center. The attacker changed the password first, then the email. She took the email back first with the "undo change" link sent to her old address.')],
     [
         doc('c06', 'login_alerts.txt', raw='10-03 21:14 new login        Seoul, Galaxy S23 (suah phone)\n'
             '10-05 02:31 new login        Lagos, Windows PC\n10-05 02:33 password changed\n'
             '10-05 02:34 email changed to s.uah@mai1box.net\n10-05 02:40 two-factor turned ON'),
         doc('c06', 'dm_capture.txt', '10-04 22:10 낯선 계정: 저작권 신고가 접수됐어요. 본인 확인을 안 하면 계정이 삭제됩니다 → insta-help-center.co\n'
             '10-04 22:30 공식 보안 알림: 새 기기 로그인 안내는 help.instagram.com 에서 확인하세요.',
             '10-04 22:10 Unknown account: a copyright report was filed. Verify yourself or your account will be deleted → insta-help-center.co\n'
             '10-04 22:30 Official security notice: check new-device login notices at help.instagram.com.'),
         doc('c06', 'suah_message.txt', '수아: 둘 다 눌렀어. 하나는 로그인하라고 해서 아이디랑 비밀번호를 넣었고, 다른 하나는 읽기만 했어.',
             'Suah: I tapped both. One asked me to log in, so I typed my ID and password; the other one I only read.'),
         doc('c06', 'official_help.txt', '공식 도움말: 계정을 뺏겼다면 ① 원래 이메일로 온 「이메일 변경 취소」 링크로 이메일부터 되돌리고 ② 비밀번호 재설정 ③ 2단계 인증을 본인 기기로 다시 켠다.',
             'Official help: if your account was taken, (1) undo the email change with the link sent to your original email, (2) reset the password, (3) turn two-factor back on with your own device.'),
         doc('c06', 'browser_history.txt', raw='10-04 22:12 insta-help-center.co/login\n10-04 22:13 insta-help-center.co/verified\n'
             '10-04 22:31 help.instagram.com/security', lock=5),
     ],
     [
         q('c06', 1, ('비밀번호가 넘어간 곳은?', 'Where did the password go?'),
           ['insta-help-center.co', 'help.instagram.com', 'mai1box.net', 'instagram.com'], 0),
         q('c06', 2, ('범인이 가장 먼저 바꾼 것은?', 'What did the attacker change first?'),
           [('2단계 인증', 'Two-factor'), ('비밀번호', 'The password'), ('이메일', 'The email'), ('프로필 사진', 'The profile photo')], 1),
         q('c06', 3, ('지금 가장 먼저 할 일은?', 'What should she do first?'),
           [('비밀번호를 바꾼다', 'Change the password'), ('계정을 새로 만든다', 'Make a new account'), ('범인에게 DM 을 보낸다', 'DM the attacker'),
            ('원래 이메일로 온 변경 취소 링크로 이메일부터 되찾는다', 'Take the email back with the undo link sent to her original email')], 3),
     ])

# ================================================================ c07 — 문자 셋, 앱 둘, 숫자 맞추기
case('c07',
     ('택배 문자', 'The Delivery Text'),
     [('엄마 휴대폰에 택배 문자가 세 통 왔다. 그날 이후 친구들에게 이상한 문자가 갔고, 요금이 많이 나왔다.',
       "Mom's phone got three delivery texts. Since that day her friends have been getting strange texts, and the bill went up."),
      ('엄마는 앱을 두 개 깔았다고 한다. 무엇이 진짜고, 누가 문자를 보냈는지 밝혀 줘.',
       'Mom says she installed two apps. Find out which is real and what sent the texts.')],
     [('가짜 앱 delivery_check 가 문자·연락처 권한으로 38통을 보냈다. 엄마가 직접 보낸 건 딸에게 간 1통뿐. 진짜 택배사 앱은 죄가 없었다.',
       "The fake delivery_check app used its SMS and contacts permissions to send 38 texts. Mom herself sent only one, to her daughter. The real courier app was innocent.")],
     [
         doc('c07', 'sms_inbox.txt', raw='[1] [CJ대한통운] 10/6 배송 완료되었습니다. 문의 1588-1255\n'
             '[2] [CJ Logistics] Delivery on hold: address unknown. Confirm: http://cj-de1ivery.top/a7\n'
             '[3] [우체국] 소포 도착 예정입니다. 조회: https://service.epost.go.kr'),
         doc('c07', 'installed_apps.txt', raw='10-06 14:02 installed delivery_check.apk  source=unknown     perms=SMS,Contacts\n'
             '10-06 14:30 installed CJ대한통운          source=Play Store  perms=Notifications'),
         doc('c07', 'mom_chat.txt', '엄마: 링크를 눌렀더니 앱을 깔라고 해서 깔았어. 나중에 진짜 택배사 앱도 받았고. 문자는 너한테 한 통 보낸 게 다야.',
             'Mom: the link told me to install an app, so I did. Later I also got the real courier app. The only text I sent was the one to you.'),
         doc('c07', 'friend_sms.txt', '엄마 번호로 친구가 받은 문자: 택배 주소 확인 부탁해요 http://cj-de1ivery.top/a7',
             "Text a friend got from Mom's number: please confirm your delivery address http://cj-de1ivery.top/a7"),
         doc('c07', 'carrier_bill.txt', raw='2026-10-06  SMS sent: 39'),
         doc('c07', 'sent_sms_log.txt', raw='10-06 14:10-14:12  sent 38  via app=delivery_check  to=contacts\n'
             '10-06 15:00        sent 1   via app=Messages        to=daughter', lock=5),
     ],
     [
         q('c07', 1, ('가짜 문자는?', 'Which text is fake?'),
           [('[1]', '[1]'), ('[2]', '[2]'), ('[3]', '[3]'), ('[1] 과 [2]', '[1] and [2]'), ('없다', 'None')], 1),
         q('c07', 2, ('친구들에게 문자를 보낸 것은?', 'What sent the texts to her friends?'),
           [('엄마가 직접', 'Mom herself'), ('진짜 택배사 앱', 'The real courier app'), ('delivery_check 앱', 'The delivery_check app'),
            ('통신사', 'The carrier'), ('기본 문자 앱', 'The built-in messages app')], 2),
         q('c07', 3, ('그날 엄마가 직접 보낸 문자는 몇 통?', 'How many texts did Mom send herself that day?'), ['0', '1', '38', '39', '40'], 1),
         q('c07', 4, ('가장 먼저 할 일은?', 'What comes first?'),
           [('진짜 택배사 앱을 지운다', 'Delete the real courier app'), ('전화번호를 바꾼다', 'Change the phone number'),
            ('요금부터 환불받는다', 'Get the bill refunded first'), ('delivery_check 를 지우고 지인들에게 알린다', 'Delete delivery_check and warn her contacts'),
            ('아무것도 안 한다', 'Nothing')], 3),
     ])

# ================================================================ c08 — 같은 이름의 와이파이
case('c08',
     ('카페 무료 와이파이', 'The Free Cafe Wi-Fi'),
     [('카페에서 CAFE_LATTE 라는 와이파이가 두 개 잡힌다. 이름이 똑같다. 비밀번호 없이 붙는 쪽에 접속한 손님들의 계정이 털렸다.',
       'Two networks named CAFE_LATTE show up in the cafe. Same name. Customers who joined the one without a password lost their accounts.'),
      ('가짜를 찾고, 어느 자리에서 띄웠는지 알아내 줘.', 'Find the fake and the seat it was broadcast from.')],
     [('가짜는 공유기 스티커에 없는 A4:5E:60:C2:19:03. 신호가 가장 센 곳은 창가 2번, 안테나 달린 노트북 손님 자리였다.',
       "The fake was A4:5E:60:C2:19:03, not on the router sticker. Its signal peaked at window seat 2 — the laptop with the antenna.")],
     [
         doc('c08', 'wifi_scan.txt', raw='SSID CAFE_LATTE     BSSID 7C:2E:0D:11:4A:90  WPA2  ch6\n'
             'SSID CAFE_LATTE     BSSID A4:5E:60:C2:19:03  OPEN  ch11\n'
             'SSID CAFE_LATTE_5G  BSSID 7C:2E:0D:11:4A:91  WPA2  ch36\n'
             'SSID iptime_3F      BSSID 00:26:66:8B:02:10  WPA2  ch1'),
         doc('c08', 'router_sticker.txt', '공유기 뒷면 스티커: MAC 7C:2E:0D:11:4A:90 (2.4G) / 7C:2E:0D:11:4A:91 (5G)',
             'Sticker on the back of the router: MAC 7C:2E:0D:11:4A:90 (2.4G) / 7C:2E:0D:11:4A:91 (5G)'),
         doc('c08', 'owner_note.txt', '사장님: 우리 와이파이는 둘 다 비밀번호가 있어요. 영수증에 적혀 있어요. iptime 은 위층 사무실 거예요.',
             "Owner: both of our networks have a password; it's on the receipt. The iptime one belongs to the office upstairs."),
         doc('c08', 'seat_note.txt', '직원 메모: 창가 2번 — 노트북에 작은 안테나, 3시간째. 창가 5번 — 태블릿 학생. 카운터 옆 — 공유기.',
             'Staff note: window seat 2 — laptop with a small antenna, three hours now. Window seat 5 — a student with a tablet. Next to the counter — the router.'),
         doc('c08', 'victim_note.txt', '손님들: 비밀번호 없이 붙는 CAFE_LATTE 에 연결했더니 「구글로 로그인하고 무료 와이파이 쓰기」 창이 떴어요.',
             'Customers: we joined the CAFE_LATTE that needed no password and got a "Sign in with Google for free Wi-Fi" page.'),
         doc('c08', 'signal_walk.txt', raw='BSSID A4:5E:60:C2:19:03 signal\n  counter        -71 dBm\n  window seat 2  -38 dBm\n'
             '  restroom door  -60 dBm\n  window seat 5  -55 dBm\n(closer to 0 = stronger)', lock=6),
     ],
     [
         q('c08', 1, ('가짜 네트워크는?', 'Which network is fake?'),
           ['7C:2E:0D:11:4A:90', 'A4:5E:60:C2:19:03', '7C:2E:0D:11:4A:91', '00:26:66:8B:02:10', ('없다', 'None')], 1),
         q('c08', 2, ('이름이 같을 때 진짜를 가리는 방법은?', 'With identical names, how do you tell the real one?'),
           [('신호가 센 쪽', 'The stronger signal'), ('채널 번호', 'The channel number'), ('공유기 스티커의 MAC 과 BSSID 를 맞춰 본다', 'Match the BSSID with the MAC on the router sticker'),
            ('비밀번호가 없는 쪽', 'The one without a password'), ('이름 끝에 FREE 가 없는 쪽', 'The one without FREE in its name')], 2),
         q('c08', 3, ('가짜를 띄운 자리는?', 'Which seat was broadcasting it?'),
           [('카운터 옆', 'Next to the counter'), ('창가 2번', 'Window seat 2'), ('창가 5번', 'Window seat 5'), ('화장실 앞', 'By the restroom'), ('위층 사무실', 'The office upstairs')], 1),
         q('c08', 4, ('손님이 지킬 것은?', 'What should customers do?'),
           [('신호가 센 와이파이를 고른다', 'Pick the strongest signal'), ('무료면 괜찮다', 'Free is fine'), ('5G 만 쓴다', 'Use 5G only'),
            ('비밀번호 없는 와이파이에서 계정에 로그인하지 않는다', 'Never log in to accounts on open Wi-Fi'), ('VPN 앱을 아무거나 깐다', 'Install any VPN app')], 3),
     ])

# ================================================================ c09 — 구매자와 고객센터는 같은 번호
case('c09',
     ('중고거래 안전결제', 'The Second-hand Sale'),
     [('중고 게임기를 팔던 지훈이 구매자가 보낸 「안전결제」 링크와 「고객센터」 안내를 받았다.',
       "Jihoon, selling a used console, got a 'safe pay' link from the buyer and then a message from 'support'."),
      ('어느 게 진짜인지, 고객센터가 누구인지 짚어 줘.', 'Tell me what is real and who "support" is.')],
     [('고객센터 abc_support 와 구매자 Gold_Hand 는 같은 번호(…5521)였다. 가짜 사이트는 거래 사흘 전에 만들어졌고. 지훈은 앱 안에서만 거래하고 신고했다.',
       "Support (abc_support) and the buyer (Gold_Hand) shared one number (...5521). The fake site was made three days before the deal. Jihoon stayed in the app and reported it.")],
     [
         doc('c09', 'chat.txt', '구매자 Gold_Hand: 안전결제로 할게요 → https://safe-pay-market.shop/order/8812 / 결제가 막히면 고객센터 abc_support 로 문의하세요',
             "Buyer Gold_Hand: let's use safe pay → https://safe-pay-market.shop/order/8812 / if payment is blocked, contact support at abc_support"),
         doc('c09', 'links.txt', raw='link A (made with the in-app "request payment" button): https://market.app/pay/8812\n'
             'link B (sent by the buyer):                            https://safe-pay-market.shop/order/8812'),
         doc('c09', 'app_notice.txt', '앱 공지: 공식 결제 주소는 market.app/pay/ 로만 시작합니다. 저희는 메신저로 「고객센터」 연락을 하지 않습니다.',
             'App notice: our official payment links only start with market.app/pay/. We never contact you as "support" through messengers.'),
         doc('c09', 'support_chat.txt', 'abc_support: 수수료 3만 원을 먼저 넣어야 안전결제가 풀립니다. 계좌 123-45-6789 / 프로필 연락처 010-****-5521',
             'abc_support: you must deposit a 30,000 won fee first to unlock safe pay. Account 123-45-6789 / profile contact 010-****-5521'),
         doc('c09', 'buyer_reports.txt', 'Gold_Hand 신고 7건 — 「앱 밖 링크로 결제하게 하고 연락이 끊겼다」 / 등록 연락처 끝자리 5521',
             "7 reports on Gold_Hand — 'made me pay through an outside link, then vanished' / registered contact ends in 5521"),
         doc('c09', 'whois.txt', raw='domain:   safe-pay-market.shop\ncreated:  2026-10-07\nregistrant phone: +82-10-****-5521\n'
             '(the deal chat started 2026-10-10)', lock=5),
     ],
     [
         q('c09', 1, ('공식 결제 링크는?', 'Which is the official payment link?'),
           [('링크 A', 'Link A'), ('링크 B', 'Link B'), ('둘 다', 'Both'), ('둘 다 아니다', 'Neither'), ('고객센터가 보낼 링크', 'The one support will send')], 0),
         q('c09', 2, ('고객센터 abc_support 의 정체는?', 'Who is abc_support?'),
           [('진짜 고객센터', 'The real support team'), ('구매자 본인', 'The buyer himself'), ('은행', 'The bank'), ('다른 피해자', 'Another victim'), ('앱 운영자', 'The app operator')], 1),
         q('c09', 3, ('가짜 사이트가 만들어진 날은?', 'When was the fake site created?'),
           ['2026-09-01', '2026-10-10', '2026-10-07', ('거래 당일', 'The day of the deal'), ('알 수 없다', 'Unknown')], 2),
         q('c09', 4, ('지훈이 할 일은?', 'What should Jihoon do?'),
           [('수수료만 먼저 보낸다', 'Send just the fee first'), ('앱 안 버튼으로만 거래하고 신고한다', 'Trade only through the in-app button and report it'),
            ('링크 B 로 결제하되 금액을 낮춘다', 'Pay through link B but for less'), ('고객센터에 계좌를 묻는다', 'Ask support for their account'), ('구매자를 차단만 한다', 'Just block the buyer')], 1),
     ])

# ================================================================ c10 — 워터마크는 함정
case('c10',
     ('단체방에서 샌 사진', 'The Leaked Group-chat Photo'),
     [('동아리 단체방(12명)에만 올린 사진이 학교 커뮤니티에 올라왔다. 사진에는 편집 앱 워터마크 jw_cut 이 찍혀 있다.',
       'A photo posted only in the club group chat (12 people) showed up on the school forum. It carries the editing-app watermark jw_cut.'),
      ('다들 워터마크 주인을 의심한다. 정말 그런지, 누가 퍼뜨렸는지 찾아 줘.', 'Everyone suspects the watermark owner. Check it, and find who spread it.')],
     [('워터마크는 지우가 단체방에 올린 편집본 자체에 찍혀 있었다. 퍼뜨린 건 그걸 저장한 하늘 — 올린 기기도, 커뮤니티 닉네임도 하늘이었다.',
       "The watermark was already on the edit Jiwoo posted in the group chat. The one who spread it was Haneul, who saved it — the device and the forum nickname both pointed to Haneul.")],
     [
         doc('c10', 'photo_meta.txt', raw="forum image: IMG_2231_edit.jpg\nwatermark:   SnapCut 'jw_cut'\nuploaded:    10-09 23:41  device=iPhone 13 mini\nuploader:    하늘색구름"),
         doc('c10', 'group_log.txt', raw="10-09 22:10 jiwoo   posted IMG_2231_edit.jpg  'lol I made a meme'\n"
             '10-09 23:38 haneul  saved IMG_2231_edit.jpg\n10-09 23:39 minji   saved IMG_2231_edit.jpg'),
         doc('c10', 'members.txt', raw='minji   SnapCut: minjj   phone: Galaxy S24\njiwoo   SnapCut: jw_cut  phone: iPhone 15\n'
             'haneul  SnapCut: sky_h   phone: iPhone 13 mini\ndohyun  SnapCut: dh      phone: Galaxy A54\n(+8 more)'),
         doc('c10', 'group_rules.txt', '단체방 공지: 여기 올린 사진은 밖에 올리지 않기.', 'Group rule: photos posted here stay here.'),
         doc('c10', 'club_note.txt', '동아리 회의록: 축제 후기 글은 홍보 담당이 학교 커뮤니티에 올린다.',
             'Club minutes: the festival recap is posted on the school forum by the person in charge of promotion.'),
         doc('c10', 'forum_profile.txt', raw='nickname: 하늘색구름\njoined:   2026-03\nposts:    "our club festival recap" (2026-05)\n'
             '          IMG_2231_edit.jpg (2026-10-09)\nclub role listed in recap: promotion — haneul', lock=6),
     ],
     [
         q('c10', 1, ('워터마크 jw_cut 의 주인은?', 'Who owns the jw_cut watermark?'),
           ['minji', 'jiwoo', 'haneul', 'dohyun', ('알 수 없다', 'Unknown')], 1),
         q('c10', 2, ('워터마크가 범인을 가리키지 못하는 이유는?', 'Why does the watermark not identify the leaker?'),
           [('워터마크가 가짜다', 'The watermark is fake'), ('사진이 흐리다', 'The photo is blurry'), ('SnapCut 은 누구나 쓴다', 'Everyone uses SnapCut'),
            ('워터마크 찍힌 편집본을 단체방 모두가 받을 수 있었다', 'Everyone in the group got the watermarked edit'), ('지우가 탈퇴했다', 'Jiwoo left the club')], 3),
         q('c10', 3, ('퍼뜨린 사람은?', 'Who spread it?'), ['minji', 'jiwoo', 'haneul', 'dohyun', ('외부인', 'An outsider')], 2),
         q('c10', 4, ('결정적인 단서 조합은?', 'Which clues settle it?'),
           [('올린 기기(iPhone 13 mini)와 커뮤니티 닉네임의 글 이력', 'The upload device (iPhone 13 mini) and the forum nickname history'),
            ('워터마크와 편집 시각', 'The watermark and edit time'), ('저장 시각만', 'The save time alone'),
            ('단체방 공지', 'The group rule'), ('사진 파일 이름', 'The file name')], 0),
     ])

# ================================================================ c11 — 공유된 권한은 기한을 따르지 않는다
case('c11',
     ('혼자 열린 도어락', 'The Door That Opened Itself'),
     [('원룸 스마트 도어락이 새벽 2시에 앱으로 열렸다. 집주인은 아무도 안 왔고, 손님 권한은 하루짜리였다고 한다.',
       'The studio apartment smart lock was opened by app at 2 a.m. The owner says nobody came, and the guest access was for one day only.'),
      ('무엇으로, 누가 열었는지 밝혀 줘.', 'Find out what opened it, and who.')],
     [('기사님의 하루짜리 권한(guest_01)은 끝났지만, 그가 「공유」 버튼으로 동료에게 넘긴 guest_02 는 기한이 없었다. 문을 연 폰은 동료의 갤럭시 A54 였다.',
       "The technician's one-day access (guest_01) had expired, but guest_02, which he passed to a coworker with the Share button, had no end date. The phone that opened the door was the coworker's Galaxy A54.")],
     [
         doc('c11', 'lock_log.txt', raw='10-08 14:20 unlock  method=pin  code=one-time (delivery)\n'
             '10-11 02:03 unlock  method=app  user=guest_02  device=SM-A546\n10-11 02:03 door opened\n'
             '10-11 02:05 door closed\n10-11 09:12 unlock  method=fingerprint  user=owner'),
         doc('c11', 'app_users.txt', raw='owner     (me)\nguest_01  created 09-20 by owner     expires 09-21\n'
             'guest_02  created 09-20 by guest_01  expires never'),
         doc('c11', 'memo.txt', '9월 20일, 집 고쳐 주는 기사님께 하루짜리 출입 권한을 줬다. 그날 기사님은 동료와 둘이 왔다.',
             'Sep 20: I gave the repair technician a one-day access. He came with a coworker that day.'),
         doc('c11', 'technician_sms.txt', '기사님: 저는 아이폰을 써요. 그날 일이 길어질까 봐 권한을 동료 폰에도 공유해 뒀었어요.',
             "Technician: I use an iPhone. That day I also shared the access to my coworker's phone in case the job ran long."),
         doc('c11', 'device_note.txt', raw='SM-A546 = Samsung Galaxy A54'),
         doc('c11', 'share_rule.txt', '앱 도움말: 손님도 「공유」 버튼으로 다른 사람에게 권한을 넘길 수 있습니다. 넘겨받은 권한은 원래 기한을 따르지 않으며, 따로 정하지 않으면 무기한입니다.',
             'App help: guests can pass their access on with the Share button. A shared access does not inherit the original end date; unless one is set, it never expires.', lock=7),
     ],
     [
         q('c11', 1, ('문을 연 권한은?', 'Which access opened the door?'),
           ['owner', 'guest_01', 'guest_02', ('택배 일회용 PIN', 'The one-time delivery PIN'), ('복제된 지문', 'A copied fingerprint')], 2),
         q('c11', 2, ('그 권한을 만든 것은?', 'Who created that access?'),
           [('집주인이 직접', 'The owner'), ('기사님이 공유 버튼으로', 'The technician, with the Share button'), ('앱 오류', 'An app bug'), ('해커', 'A hacker'), ('택배 기사', 'The courier')], 1),
         q('c11', 3, ('문을 연 사람은?', 'Who opened the door?'),
           [('집주인', 'The owner'), ('택배 기사', 'The courier'), ('기사님', 'The technician'), ('기사님의 동료', "The technician's coworker"), ('알 수 없다', 'Unknown')], 3),
         q('c11', 4, ('하루짜리였는데 열린 이유는?', 'Why did it work if the access was for one day?'),
           [('시계 오류', 'A clock error'), ('집주인이 연장했다', 'The owner extended it'), ('앱이 기한을 무시했다', 'The app ignored the end date'),
            ('지문이 등록돼 있었다', 'A fingerprint was registered'), ('공유받은 권한은 원래 기한을 따르지 않는다', 'Shared access does not inherit the original end date')], 4),
         q('c11', 5, ('다시 안 생기게 하려면?', 'How do you stop it happening again?'),
           [('손님 권한의 공유를 막고, 공유된 권한까지 기한을 확인해 지운다', 'Block sharing of guest access, and check and remove shared access too'),
            ('도어락을 바꾼다', 'Replace the lock'), ('비밀번호를 길게 한다', 'Use a longer PIN'), ('지문만 쓴다', 'Use fingerprints only'), ('앱을 지운다', 'Delete the app')], 0),
     ])

# ================================================================ c12 — 고스트의 정체
case('c12',
     ('고스트의 정체', "Ghost's Identity"),
     [('고스트가 연락을 끊었다. 마지막 메시지는 「나를 찾아봐」 한 줄.', 'Ghost went silent. The last message was a single line: "Find me."'),
      ('지금까지의 자료를 엮어 고스트가 누구인지 밝혀라. 이름이 그대로 적힌 자료는 없다.',
       'Tie everything together and find out who Ghost is. No file simply names them.')],
     [('찾았네. 퇴사 전에 못다 한 점검을 누군가에게 맡기고 싶었어. 그게 너라서 다행이다. // g',
       'You found me. I wanted someone to finish the checks I left undone when I quit. Glad it was you. // g'),
      ('— 고스트, 아니 이하윤', '— Ghost. Or rather, Lee Hayun')],
     [
         doc('c12', 'last_message.txt', '고스트: 처음 너한테 준 일 기억나? 카페 PC 의 환영 메모. 그건 내가 남긴 거야. 나를 찾아봐. // g',
             'Ghost: remember the first job I gave you? The welcome note on the cafe PC. I left it. Find me. // g'),
         doc('c12', 'welcome_meta.txt', raw='file:     cafe-pc:/welcome.txt\nauthor:   admin\ncreated:  2026-09-01 03:14\nfrom host: sec-lab-07'),
         doc('c12', 'asset_list.csv', raw='asset,team,last user,status\nsec-lab-07,security,lee.hayun,"returned 2026-08-31, remote access still on"\n'
             'FIN-PHONE-07,finance,park.seojun,in use\n3F-B,facilities,-,in use'),
         doc('c12', 'staff_list.csv', raw='id,role,status\nlee.hayun,security engineer,left 2026-08-31\npark.seojun,finance,active\n'
             'min.ho,sales,suspended 2026-10-13\nkim.taeho,developer,active\nhan.dahye,developer,active'),
         doc('c12', 'old_blame.txt', raw='repo: security-checks\nlee.hayun  2026-07-30  # TODO: check cafe-pc, printer 3F-B // g\n'
             'kim.taeho  2026-08-02  # fix typo\nhan.dahye  2026-08-05  # add login page'),
         doc('c12', 'minho_note.txt', '민호: 나 아니야. 정직당해서 회사 시스템엔 접속도 못 하는데 무슨 고스트야.',
             "Minho: not me. I'm suspended and can't even reach the company systems — how would I be Ghost?"),
         doc('c12', 'handover.txt', '인수인계: 남은 점검 목록은 sec-lab-07 에 두고 간다. 이어서 할 사람은 내가 직접 골라서, 이름 없이 일을 보내겠다.',
             'Handover: I am leaving the remaining checks on sec-lab-07. I will pick whoever carries them on myself, and send the jobs without a name.', lock=7),
     ],
     [
         q('c12', 1, ('환영 메모를 만든 기기는?', 'Which machine created the welcome note?'),
           ['cafe-pc', 'sec-lab-07', 'FIN-PHONE-07', '3F-B', ('민호의 노트북', "Minho's laptop"), ('알 수 없다', 'Unknown')], 1),
         q('c12', 2, ('그 기기를 마지막으로 쓴 사람은?', 'Who last used that machine?'),
           ['park.seojun', 'min.ho', 'lee.hayun', 'kim.taeho', 'han.dahye', ('카페 사장', 'The cafe owner')], 2),
         q('c12', 3, ('고스트의 서명 습관은?', "What is Ghost's signature habit?"),
           [('— 고스트', '— Ghost'), ('// g', '// g'), ('ㅋㅋ', 'lol'), ('..', '..'), ('PS', 'PS'), ('없다', 'None')], 1),
         q('c12', 4, ('고스트가 일을 맡긴 이유는?', 'Why did Ghost hand out the jobs?'),
           [('퇴사 전에 못다 한 점검을 이어 가게 하려고', 'To carry on the checks left undone before quitting'), ('돈을 벌려고', 'To make money'),
            ('회사에 복수하려고', 'To get back at the company'), ('그냥 장난', 'Just for fun'), ('민호를 감싸려고', 'To cover for Minho'), ('채용 시험', 'As a hiring test')], 0),
         q('c12', 5, ('고스트는 누구인가?', 'Who is Ghost?'),
           [('박서준', 'Park Seojun'), ('민호', 'Minho'), ('김태호', 'Kim Taeho'), ('이하윤', 'Lee Hayun'), ('한다혜', 'Han Dahye'), ('카페 사장', 'The cafe owner')], 3),
     ])

os.makedirs(os.path.join(ROOT, 'assets', 'cases'), exist_ok=True)
for c in CASES:
    with open(os.path.join(ROOT, 'assets', 'cases', c['id'] + '.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump(c, f, ensure_ascii=False, indent=1)
for code, table in (('ko', KO), ('en', EN)):
    p = os.path.join(ROOT, 'i18n', code + '.json')
    d = json.load(open(p, encoding='utf-8'))
    d = {k: v for k, v in d.items() if not re.match(r'^c\d\d_', k)}  # 사건 열쇠는 매번 새로(번호가 바뀌어도 옛 열쇠가 남지 않게)
    d.update(table)
    json.dump(d, open(p, 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent=2)
print(len(CASES), 'cases,', len(KO), 'keys')
