# -*- coding: utf-8 -*-
"""사건 파일 6개(assets/cases/c0N.json)와 그 문장(ko·en)을 만든다.
로그·메일 원문은 영어 그대로(번역 안 함), 사람이 읽는 글은 @열쇠.
프로젝트 루트에서: python tool/make_cases.py
"""
import json
import os

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


# ---------------------------------------------------------------- c01
case('c01',
     ('새어 나간 쿠폰', 'The Leaked Coupon'),
     [('쇼핑몰 직원 전용 90% 할인 쿠폰 SAVE90 이 10월 12일 밤 커뮤니티에 올라왔다.',
       'The staff-only 90% coupon SAVE90 showed up on a forum on the night of Oct 12.'),
      ('쿠폰은 관리자 화면에서만 볼 수 있다. 누가 빼냈는지 찾아 줘.',
       'Coupons are only visible on the admin page. Find out who took it.')],
     [('민호는 쉬는 날 집에서 회사 VPN 으로 들어와 목록을 뽑았다. 퇴사자 계정 정리가 시급하군.',
       "Minho got in through the company VPN from home on his day off. Somebody needs to clean up those accounts.")],
     [
         {'name': 'admin_access.log', 'text': '10-12 18:02 view   coupon_list  user=jiwoo\n10-12 21:47 view   coupon_list  user=minho\n10-12 21:49 export coupon_list.csv user=minho\n10-12 22:15 view   orders       user=jiwoo'},
         {'name': 'shift.csv', 'text': 'name,10-12\njiwoo,09:00-18:30\nminho,off\nseoyeon,13:00-22:00'},
         {'name': 'forum_post.txt', 'text': t('c01_d_post', '익명: 오늘 밤 직원 쿠폰 SAVE90 공유합니다 ㅋㅋ (게시 22:03)', 'Anonymous: sharing the staff coupon SAVE90 tonight lol (posted 22:03)')},
         {'name': 'minho_dm.txt', 'lock': {'length': 5},
          'text': t('c01_d_dm', '민호 → 친구: 회사 VPN 아직 살아 있어서 쿠폰 목록 뽑았어. 비밀이다?', "Minho → friend: the company VPN still works so I pulled the coupon list. Keep it quiet?")},
     ],
     [
         q('c01', 1, ('쿠폰 목록을 밖으로 빼낸 계정은?', 'Which account exported the coupon list?'), ['jiwoo', 'minho', 'seoyeon'], 1),
         q('c01', 2, ('그 계정이 수상한 이유는?', 'Why is that account suspicious?'),
           [('그날 쉬는 날인데 관리자 화면에 들어왔다', 'It was his day off, yet he used the admin page'),
            ('근무 중에 쿠폰 목록을 봤다', 'He viewed the list during his shift'),
            ('쿠폰을 직접 결제에 썼다', 'He used the coupon to pay')], 0),
     ])

# ---------------------------------------------------------------- c02
case('c02',
     ('새벽 3시의 로그인', 'The 3 A.M. Login'),
     [('재무팀 계정 finance01 이 새벽 3시 12분에 일본 IP 로 로그인했다. 급여 파일까지 내려받았다.',
       'Finance account finance01 logged in at 3:12 a.m. from a Japanese IP and even downloaded the payroll file.'),
      ('해킹인지, 출장 중인 직원인지 가려 줘.', 'Tell me whether this is a hack or an employee on a business trip.')],
     [('본인 휴대폰으로 2단계 인증을 통과했고 출장 일정과도 맞는다. 결산 마감에 쫓긴 박서준 대리였다.',
       'Two-factor passed on his own phone and it matches the trip schedule. It was Park Seojun, racing a deadline.')],
     [
         {'name': 'auth.log', 'text': '03:12 login ok   user=finance01 ip=203.0.113.50 country=JP\n03:12 2fa   ok   device=finance01-phone\n03:40 download   payroll.xlsx user=finance01'},
         {'name': 'calendar.txt', 'text': t('c02_d_cal', '재무팀 박서준 대리: 10/9 ~ 10/13 오사카 출장 (일본과 한국은 시차 없음)', 'Finance, Park Seojun: business trip to Osaka 10/9-10/13 (no time difference between Japan and Korea)')},
         {'name': 'team_chat.txt', 'text': t('c02_d_chat', '팀장: 서준 씨, 결산 마감 오늘 새벽까지 부탁해요. / 서준: 네, 호텔에서 접속해서 끝낼게요.', 'Manager: Seojun, please wrap up the closing by early morning. / Seojun: Sure, I will log in from the hotel and finish it.')},
     ],
     [
         q('c02', 1, ('새벽에 로그인한 사람은?', 'Who logged in at dawn?'),
           [('외부 공격자', 'An outside attacker'), ('출장 중인 박서준 대리', 'Park Seojun, on his trip'), ('다른 팀 직원', 'Someone from another team')], 1),
         q('c02', 2, ('가장 결정적인 증거는?', 'What is the strongest evidence?'),
           [('IP 가 일본이다', 'The IP is in Japan'), ('본인 휴대폰으로 2단계 인증을 통과했다', 'Two-factor passed on his own phone'), ('새벽 시간이다', 'It was before dawn')], 1),
     ])

# ---------------------------------------------------------------- c03
case('c03',
     ('가짜 결제 메일', 'The Fake Payment Mail'),
     [('직원들에게 결제 확인 메일이 세 통 왔다. 그중 하나는 피싱이다.', 'Staff received three payment mails. One of them is phishing.'),
      ('가짜를 찾고, 누가 링크를 눌렀는지도 알아내 줘.', 'Find the fake and who clicked its link.')],
     [('l 대신 숫자 1. 고전적인 수법이다. 하나 씨 비밀번호는 바로 바꾸게 했다.', 'A digit 1 instead of an l. Classic. Hana has already changed her password.')],
     [
         {'name': 'mail_1.eml', 'text': 'From: billing@paypal.com\nSubject: Your invoice #8812\nLink: https://www.paypal.com/invoice/8812'},
         {'name': 'mail_2.eml', 'text': 'From: service@paypa1.com\nSubject: Payment on hold - verify now\nLink: http://paypa1-secure.com/login'},
         {'name': 'mail_3.eml', 'text': 'From: noreply@paypal.com\nSubject: Receipt for your payment\nLink: https://www.paypal.com/receipt/5521'},
         {'name': 'security_tip.txt', 'text': t('c03_d_tip', '보안팀: 보낸 사람 주소의 철자를 한 글자씩 보세요. 숫자 1 과 영문 l 은 거의 똑같아 보입니다.', 'Security team: check the sender address letter by letter. The digit 1 and the letter l look almost the same.')},
         {'name': 'click_log.csv', 'lock': {'length': 5}, 'text': 'time,mail,user\n09:02,mail_1,jun\n09:14,mail_2,hana\n09:20,mail_3,mina'},
     ],
     [
         q('c03', 1, ('피싱 메일은?', 'Which mail is phishing?'), ['mail_1', 'mail_2', 'mail_3'], 1),
         q('c03', 2, ('그렇게 본 근거는?', 'What gives it away?'),
           [('주소에 영문 l 대신 숫자 1 이 있다', 'The address has a digit 1 instead of an l'), ('제목이 영어다', 'The subject is in English'), ('링크가 https 로 시작한다', 'The link starts with https')], 0),
         q('c03', 3, ('가짜 링크를 누른 직원은?', 'Who clicked the fake link?'), ['jun', 'hana', 'mina'], 1),
     ])

# ---------------------------------------------------------------- c04
case('c04',
     ('지워진 커밋', 'The Deleted Commit'),
     [('배포 서버의 비밀 키가 깃 저장소에 올라갔다가 지워졌다.', "The deploy server's secret key was pushed to the git repo, then removed."),
      ('누가 올렸는지 찾아 줘. 지운 사람은 범인이 아닐 수도 있다.', 'Find who pushed it. Whoever removed it may not be the culprit.')],
     [('「오타 수정」 이라는 커밋에 키 파일을 슬쩍 넣었군. 다혜 씨는 그걸 발견해서 지운 쪽이었다.',
       'He slipped the key into a commit called "fix typo". Dahye was the one who found and removed it.')],
     [
         {'name': 'git_log.txt', 'text': 'f7a1  10-02 10:11  dahye  add login page\nc3d9  10-02 23:48  taeho  fix typo\nb2e0  10-03 09:02  dahye  remove leaked file'},
         {'name': 'git_show_c3d9.txt', 'text': 'commit c3d9  fix typo\n  README.md        | 1 -\n+ config/deploy.key | 27 +++\n+-----BEGIN PRIVATE KEY-----'},
         {'name': 'chat.txt', 'text': t('c04_d_chat', '다혜: 아침에 보니 저장소에 키 파일이 있어서 바로 지웠어요. 누가 올린 건지는 모르겠어요.', 'Dahye: I saw a key file in the repo this morning and removed it right away. No idea who pushed it.')},
         {'name': 'reflog.txt', 'lock': {'length': 6}, 'text': 'b2e0 dahye: remove config/deploy.key (added in c3d9 by taeho)\nc3d9 taeho: commit (amend)'},
     ],
     [
         q('c04', 1, ('키를 올린 사람은?', 'Who pushed the key?'), ['dahye', 'taeho', 'unknown'], 1),
         q('c04', 2, ('그 커밋이 수상한 이유는?', 'Why is that commit suspicious?'),
           [('메시지(오타 수정)와 실제 변경(키 파일 추가)이 다르다', 'Its message (fix typo) does not match the change (adding a key file)'),
            ('밤 늦게 올렸다', 'It was pushed late at night'), ('파일 이름이 길다', 'The file name is long')], 0),
     ])

# ---------------------------------------------------------------- c05
case('c05',
     ('저녁 7시 40분의 인쇄', 'The 7:40 P.M. Print'),
     [('기밀 문서 merger_plan.pdf 가 인쇄되어 밖으로 나갔다. 인쇄 기록에는 guest 라고만 찍혔다.',
       'The confidential merger_plan.pdf was printed and walked out. The printer log only says guest.'),
      ('출입 기록과 메모로 누가 인쇄했는지 밝혀 줘.', 'Use the badge log and notes to find who printed it.')],
     [('최 대리는 인쇄 10분 뒤에 바로 나갔고, 회색 후드도 그였다. 게스트 계정으로 이름을 숨기려 했군.',
       'Choi left ten minutes after the print, and the gray hoodie was his. He tried to hide behind the guest account.')],
     [
         {'name': 'printer.log', 'text': '19:40 print merger_plan.pdf user=guest pages=12 printer=3F-B'},
         {'name': 'badge.log', 'text': '19:31 3F in   card=0418 (yoon)\n19:36 3F in   card=0722 (choi)\n19:52 3F out  card=0722 (choi)\n20:30 3F out  card=0418 (yoon)'},
         {'name': 'guard_note.txt', 'text': t('c05_d_guard', '경비 메모: 19:38 ~ 19:45 3층 B 프린터 앞에 한 사람만 서 있었다. 회색 후드를 입었다.', 'Guard note: 19:38-19:45, only one person stood at printer 3F-B, wearing a gray hoodie.')},
         {'name': 'team_chat.txt', 'lock': {'length': 6},
          'text': t('c05_d_chat', '최: 오늘 회색 후드 입고 왔는데 사무실 너무 춥다 / 윤: 나는 정장이라 괜찮아', "Choi: wore my gray hoodie today, the office is freezing / Yoon: I'm fine, I'm in a suit")},
     ],
     [
         q('c05', 1, ('문서를 인쇄한 사람은?', 'Who printed the document?'), [('윤', 'Yoon'), ('최', 'Choi'), ('외부인', 'An outsider')], 1),
         q('c05', 2, ('인쇄 기록에 guest 로 찍힌 이유는?', 'Why does the log say guest?'),
           [('게스트 계정으로 인쇄해 이름을 숨겼다', 'He printed from the guest account to hide his name'),
            ('외부인이 들어왔다', 'An outsider got in'), ('프린터가 고장 났다', 'The printer was broken')], 0),
     ])

# ---------------------------------------------------------------- c06
case('c06',
     ('고스트의 정체', "Ghost's Identity"),
     [('고스트가 연락을 끊었다. 마지막 메시지는 「나를 찾아봐」 한 줄.', 'Ghost went silent. The last message was a single line: "Find me."'),
      ('지금까지의 자료로 고스트가 누구인지 밝혀라.', "Use everything you have to find out who Ghost is.")],
     [('찾았네. 퇴사 전에 못다 한 점검을 누군가에게 맡기고 싶었어. 그게 너라서 다행이다.',
       'You found me. I wanted someone to finish the checks I left undone when I quit. Glad it was you.'),
      ('— 고스트, 아니 이하윤', '— Ghost. Or rather, Lee Hayun')],
     [
         {'name': 'last_message.txt', 'text': t('c06_d_msg', '고스트: 처음 너한테 준 일 기억나? 카페 PC 의 환영 메모. 그걸 쓴 사람이 나야.', 'Ghost: remember the first job I gave you? The welcome note on the cafe PC. I wrote it.')},
         {'name': 'welcome_meta.txt', 'text': 'file: cafe-pc:/welcome.txt\nauthor: lee.hayun\ncreated: 2026-09-01'},
         {'name': 'staff_list.csv', 'text': 'id,role,status\nlee.hayun,security engineer,left 2026-08\npark.seojun,finance,active\nmin.ho,sales,suspended'},
         {'name': 'handover.txt', 'lock': {'length': 7},
          'text': t('c06_d_handover', '인수인계: 남은 점검은 내가 고른 신입에게 맡긴다. 의뢰는 「고스트」 라는 이름으로 보낸다. — 이하윤', 'Handover: the remaining checks go to a rookie I pick. I will send the jobs as "Ghost". — Lee Hayun')},
     ],
     [
         q('c06', 1, ('고스트는 누구인가?', 'Who is Ghost?'),
           [('이하윤, 전 보안 엔지니어', 'Lee Hayun, former security engineer'), ('박서준, 재무팀', 'Park Seojun, finance'), ('카페 사장', 'The cafe owner')], 0),
         q('c06', 2, ('고스트가 신입에게 일을 맡긴 이유는?', 'Why did Ghost hand jobs to a rookie?'),
           [('퇴사 전에 못다 한 점검을 맡기려고', 'To finish the checks left undone before quitting'), ('돈을 벌려고', 'To make money'), ('그냥 장난', 'Just for fun')], 0),
     ])

os.makedirs(os.path.join(ROOT, 'assets', 'cases'), exist_ok=True)
for c in CASES:
    with open(os.path.join(ROOT, 'assets', 'cases', c['id'] + '.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump(c, f, ensure_ascii=False, indent=1)
for code, table in (('ko', KO), ('en', EN)):
    p = os.path.join(ROOT, 'i18n', code + '.json')
    d = json.load(open(p, encoding='utf-8'))
    d.update(table)
    json.dump(d, open(p, 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent=2)
print(len(CASES), 'cases,', len(KO), 'keys')
