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
     [('민호는 쉬는 날 집에서 회사 VPN 으로 들어와 목록을 뽑았다. 쉬는 날에도 관리자 화면이 열려 있던 게 구멍이었군.',
       "Minho got in through the company VPN from home on his day off. The hole was an admin page open even on days off.")],
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
     ('털린 SNS 계정', 'The Hijacked Account'),
     [('친구 수아의 SNS 계정이 남의 손에 넘어가 「코인 투자」 광고가 올라오고 있다.',
       "My friend Suah's social account was taken over and is posting crypto ads."),
      ('어떻게 털렸는지, 지금 뭘 해야 하는지 알려 줘.', 'Find out how it happened and what she should do now.')],
     [('가짜 고객센터 링크에 비밀번호를 넣은 게 시작이었다. 공식 복구 절차로 되찾고 2단계 인증을 켜게 했다.',
       'It started with a password typed into a fake help-center link. She recovered it through the official process and turned on two-factor.')],
     [
         {'name': 'login_alerts.txt', 'text': '10-03 21:14 new login  Seoul, Galaxy S23 (suah phone)\n10-05 02:31 new login  Lagos, Windows PC\n10-05 02:33 password changed\n10-05 02:34 email changed to s.uah@mai1box.net'},
         {'name': 'dm_capture.txt', 'text': t('c06_d_dm', '10-04 22:10 낯선 계정: 수아님 사진이 저작권 침해로 신고됐어요. 아래 링크에서 본인 확인을 안 하면 계정이 삭제됩니다 → insta-help-center.co', '10-04 22:10 Unknown account: your photo was reported for copyright. Verify yourself at the link below or your account will be deleted → insta-help-center.co')},
         {'name': 'suah_message.txt', 'text': t('c06_d_suah', '수아: 그 링크에서 아이디랑 비밀번호를 넣었어… 진짜 고객센터인 줄 알았어.', 'Suah: I typed my ID and password on that link… I thought it was the real help center.')},
         {'name': 'browser_history.txt', 'lock': {'length': 5}, 'text': '10-04 22:12 insta-help-center.co/login\n10-04 22:13 insta-help-center.co/verified'},
     ],
     [
         q('c06', 1, ('계정은 어떻게 털렸나?', 'How was the account stolen?'),
           [('비밀번호가 너무 쉬워서', 'The password was too easy'), ('가짜 고객센터 링크에 비밀번호를 넣어서', 'She typed it into a fake help-center link'), ('공용 와이파이 때문에', 'Because of public Wi-Fi')], 1),
         q('c06', 2, ('범인이 접속한 곳은?', 'Where did the attacker log in from?'), [('서울', 'Seoul'), ('라고스(나이지리아)', 'Lagos (Nigeria)'), ('부산', 'Busan')], 1),
         q('c06', 3, ('지금 가장 먼저 할 일은?', 'What should she do first?'),
           [('비밀번호만 바꾼다', 'Just change the password'), ('공식 복구 절차로 계정·이메일을 되찾고 2단계 인증을 켠다', 'Recover the account and email through the official process and turn on two-factor'), ('계정을 새로 만든다', 'Make a new account')], 1),
     ])

# ---------------------------------------------------------------- c07
case('c07',
     ('택배 문자', 'The Delivery Text'),
     [('엄마 휴대폰에 「택배 주소 확인」 문자가 와서 링크를 눌렀다. 그 뒤로 친구들에게 이상한 문자가 간다.',
       "Mom tapped a link in a 'confirm your delivery address' text. Since then her friends have been getting strange texts."),
      ('무슨 일이 벌어진 건지 밝혀 줘.', 'Figure out what happened.')],
     [('가짜 택배 앱이 문자·연락처 권한으로 엄마 이름을 빌려 퍼지고 있었다. 앱을 지우고 지인들에게 알렸다.',
       "A fake delivery app was spreading itself in Mom's name using its SMS and contacts permissions. We removed it and warned her friends.")],
     [
         {'name': 'sms.txt', 'text': '[CJ Logistics] Delivery on hold: address unknown. Confirm here: http://cj-de1ivery.top/a7'},
         {'name': 'installed_apps.txt', 'text': '10-06 14:02 installed  delivery_check.apk (unknown source)\n10-06 14:03 permission granted: SMS, Contacts'},
         {'name': 'mom_chat.txt', 'text': t('c07_d_mom', '엄마: 링크를 누르니까 앱을 깔라고 해서 깔았지. 그 뒤로 친구들한테 이상한 문자가 갔대.', 'Mom: the link told me to install an app, so I did. Since then my friends say they got weird texts.')},
         {'name': 'friend_sms.txt', 'lock': {'length': 5}, 'text': t('c07_d_friend', '엄마 번호로 친구에게 온 문자: 택배 주소 확인 부탁해요 http://cj-de1ivery.top/a7', "Text a friend got from Mom's number: please confirm your delivery address http://cj-de1ivery.top/a7")},
     ],
     [
         q('c07', 1, ('진짜 택배사 문자가 아니라는 근거는?', 'What shows it is not a real courier text?'),
           [('주소에 l 대신 숫자 1, 이상한 .top 주소', 'A digit 1 instead of an l, and an odd .top address'), ('문자가 너무 짧다', 'The text is too short'), ('저녁에 왔다', 'It came in the evening')], 0),
         q('c07', 2, ('친구들에게 문자가 간 이유는?', 'Why did her friends get texts?'),
           [('설치한 가짜 앱이 문자·연락처 권한으로 대신 보냈다', 'The fake app used its SMS and contacts permissions to send them'), ('엄마가 실수로 보냈다', 'Mom sent them by mistake'), ('통신사 오류', 'A carrier glitch')], 0),
     ])

# ---------------------------------------------------------------- c08
case('c08',
     ('카페 무료 와이파이', 'The Free Cafe Wi-Fi'),
     [('카페에서 와이파이가 두 개 잡힌다: CAFE_LATTE 와 CAFE_LATTE_FREE. 한쪽에 접속한 손님들의 계정이 털렸다.',
       'Two Wi-Fi networks show up in the cafe: CAFE_LATTE and CAFE_LATTE_FREE. Customers on one of them lost their accounts.'),
      ('가짜를 찾고 누가 깔았는지 알아내 줘.', 'Find the fake and who set it up.')],
     [('창가 손님의 노트북이 진짜와 비슷한 이름의 무료 와이파이를 띄워 로그인을 가로채고 있었다.',
       "The laptop at the window seat was broadcasting a free network with a look-alike name and capturing logins.")],
     [
         {'name': 'wifi_scan.txt', 'text': 'SSID: CAFE_LATTE        security: WPA2   source: router at the counter\nSSID: CAFE_LATTE_FREE   security: OPEN   strongest near: window seat'},
         {'name': 'owner_note.txt', 'text': t('c08_d_owner', '사장님: 우리 가게 와이파이는 하나뿐이에요. 비밀번호는 영수증에 적혀 있어요.', 'Owner: we only have one Wi-Fi network. The password is printed on the receipt.')},
         {'name': 'seat_note.txt', 'text': t('c08_d_seat', '직원 메모: 창가 자리 손님이 노트북을 켜 둔 채 3시간째 앉아 있다. 노트북에 작은 안테나가 달려 있었다.', 'Staff note: the customer at the window seat has had a laptop open for three hours. It had a small antenna attached.')},
         {'name': 'login_page.txt', 'lock': {'length': 6}, 'text': "CAFE_LATTE_FREE login page: 'Sign in with your Google account to use free Wi-Fi'\nform posts to http://10.0.0.1/collect"},
     ],
     [
         q('c08', 1, ('가짜 와이파이는?', 'Which network is fake?'), ['CAFE_LATTE', 'CAFE_LATTE_FREE'], 1),
         q('c08', 2, ('깔아 둔 사람으로 보이는 쪽은?', 'Who most likely set it up?'),
           [('사장님', 'The owner'), ('창가 자리 노트북 손님', 'The laptop customer at the window'), ('직원', 'A staff member')], 1),
         q('c08', 3, ('이런 일을 피하려면?', 'How do you avoid this?'),
           [('비밀번호 없는 무료 와이파이에서 계정에 로그인하지 않고, 가게에 진짜 이름을 물어본다', 'Do not log in to accounts on open free Wi-Fi, and ask the shop for the real network name'),
            ('신호가 가장 센 것을 고른다', 'Pick the strongest signal'), ('무료면 다 괜찮다', 'Free is always fine')], 0),
     ])

# ---------------------------------------------------------------- c09
case('c09',
     ('중고거래 안전결제', 'The Second-hand Sale'),
     [('중고 게임기를 팔던 지훈이 구매자가 보낸 「안전결제」 링크에 계좌를 넣을 뻔했다.',
       "Jihoon, selling a used game console, almost entered his bank details into a 'safe payment' link from the buyer."),
      ('수상한 점을 짚어 줘.', 'Point out what is wrong.')],
     [('앱 밖 링크로 결제하자는 순간부터 사기였다. 지훈은 앱 안 버튼으로만 거래했다.',
       'It was a scam the moment they asked to pay through a link outside the app. Jihoon stuck to the in-app button.')],
     [
         {'name': 'chat.txt', 'text': t('c09_d_chat', '구매자: 안전결제로 할게요, 링크 보내 드릴게요 / 지훈: 앱 안에서 하면 안 돼요? / 구매자: 수수료 아끼려고요 ㅎㅎ 이 링크가 공식이에요', "Buyer: let's use safe pay, I'll send a link / Jihoon: can't we do it in the app? / Buyer: saves the fee lol, this link is official")},
         {'name': 'link.txt', 'text': 'https://safe-pay-market.shop/order/8812'},
         {'name': 'app_notice.txt', 'text': t('c09_d_notice', '앱 공지: 저희는 앱 밖 링크로 결제를 받지 않습니다. 앱 안 「안전결제」 버튼만 쓰세요.', "App notice: we never take payment through links outside the app. Use only the in-app 'Safe pay' button.")},
         {'name': 'buyer_reports.txt', 'lock': {'length': 5}, 'text': t('c09_d_reports', '이 구매자 닉네임 신고 7건: 「앱 밖 링크로 결제하게 하고 연락이 끊겼다」', "7 reports on this buyer's nickname: 'made me pay through an outside link, then vanished'")},
     ],
     [
         q('c09', 1, ('가장 수상한 점은?', 'What is the biggest red flag?'),
           [('앱 밖 링크로 결제하자고 한다', 'They want to pay through a link outside the app'), ('가격을 깎자고 한다', 'They want a discount'), ('답장이 빠르다', 'They reply fast')], 0),
         q('c09', 2, ('진짜 안전결제인지 확인하는 법은?', 'How do you know it is real safe pay?'),
           [('앱 공지대로 앱 안 버튼만 쓴다', 'Use only the in-app button, as the notice says'), ('주소에 safe 가 들어 있으면 안전하다', "It is safe if the address contains 'safe'"), ('구매자가 공식이라고 했으니 믿는다', 'Trust the buyer who said it is official')], 0),
     ])

# ---------------------------------------------------------------- c10
case('c10',
     ('단체방에서 샌 사진', 'The Leaked Group-chat Photo'),
     [('동아리 단체방(12명)에만 올린 사진이 학교 커뮤니티에 올라왔다.', 'A photo posted only in the club group chat (12 people) showed up on the school forum.'),
      ('누가 퍼뜨렸는지 찾아 줘.', 'Find out who spread it.')],
     [('편집 앱 워터마크가 그대로 남아 있었다. 지우는 사과하고 글을 지웠다.', 'The editing app watermark gave it away. Jiwoo apologized and took the post down.')],
     [
         {'name': 'photo_meta.txt', 'text': "posted image: IMG_2231_edit.jpg\nedited with: SnapCut v2 (watermark: 'made by jw_cut')"},
         {'name': 'members.txt', 'text': 'minji   nickname: minjj\njiwoo   nickname: jw_cut\nhaneul  nickname: sky_h\n(+9 more)'},
         {'name': 'group_rules.txt', 'text': t('c10_d_rules', '단체방 공지: 여기 올린 사진은 밖에 올리지 않기.', 'Group rule: photos posted here stay here.')},
         {'name': 'dm.txt', 'lock': {'length': 6}, 'text': t('c10_d_dm', '지우 → 다른 친구: 이거 너무 웃겨서 커뮤에 올렸어 ㅋㅋ 아무도 모르겠지', 'Jiwoo → another friend: this was too funny so I posted it on the forum lol, nobody will know')},
     ],
     [
         q('c10', 1, ('사진을 퍼뜨린 사람은?', 'Who spread the photo?'), ['minji', 'jiwoo', 'haneul'], 1),
         q('c10', 2, ('결정적인 단서는?', 'What is the key clue?'),
           [('편집 앱 워터마크(jw_cut)가 지우의 닉네임과 같다', "The editing watermark (jw_cut) matches Jiwoo's nickname"), ('사진이 웃기다', 'The photo is funny'), ('올린 시간', 'The posting time')], 0),
     ])

# ---------------------------------------------------------------- c11
case('c11',
     ('혼자 열린 도어락', 'The Door That Opened Itself'),
     [('원룸 스마트 도어락이 새벽 2시에 열렸다는 기록이 있다. 집주인은 아무도 안 왔다고 한다.',
       "The smart lock on a studio apartment logged an unlock at 2 a.m. The owner says nobody came."),
      ('어떻게 열렸는지 찾아 줘.', 'Find out how it opened.')],
     [('지우지 않은 임시 손님 권한이 다른 사람 폰까지 퍼져 있었다. 권한을 지우고 기한을 정하는 습관을 들였다.',
       "A temporary guest access that was never removed had spread to someone else's phone. It is gone now, and guest access always gets an end date.")],
     [
         {'name': 'lock_log.txt', 'text': '02:03 unlock  method=app  user=guest_temp\n02:03 door opened\n02:05 door closed\n09:12 unlock  method=fingerprint  user=owner'},
         {'name': 'app_users.txt', 'text': 'owner        (me)\nguest_temp   created 09-20 by owner   expires: never'},
         {'name': 'memo.txt', 'text': t('c11_d_memo', '9월 20일에 집 고쳐 주는 기사님한테 임시 출입 권한을 줬었다. 지우는 걸 깜빡했다.', 'On Sep 20 I gave temporary access to the repair technician. I forgot to remove it.')},
         {'name': 'technician_sms.txt', 'lock': {'length': 7}, 'text': t('c11_d_tech', '기사님 문자: 그 권한이 제 동료 폰에도 공유돼 있었어요. 죄송합니다, 바로 지울게요.', "Technician's text: that access was shared to my coworker's phone too. Sorry, removing it now.")},
     ],
     [
         q('c11', 1, ('문은 어떻게 열렸나?', 'How did the door open?'),
           [('지문이 복제됐다', 'The fingerprint was copied'), ('지우지 않은 임시 손님 권한(guest_temp)으로 앱에서 열었다', 'Someone used the never-removed guest access (guest_temp) in the app'), ('도어락 고장', 'The lock malfunctioned')], 1),
         q('c11', 2, ('다시 안 생기게 하려면?', 'How do you stop it happening again?'),
           [('임시 권한은 기한을 정하고 끝나면 지운다', 'Give temporary access an end date and remove it after'), ('도어락을 바꾼다', 'Replace the lock'), ('비밀번호를 길게 한다', 'Use a longer PIN')], 0),
     ])

# ---------------------------------------------------------------- c12
case('c12',
     ('고스트의 정체', "Ghost's Identity"),
     [('고스트가 연락을 끊었다. 마지막 메시지는 「나를 찾아봐」 한 줄.', 'Ghost went silent. The last message was a single line: "Find me."'),
      ('지금까지의 자료로 고스트가 누구인지 밝혀라.', "Use everything you have to find out who Ghost is.")],
     [('찾았네. 퇴사 전에 못다 한 점검을 누군가에게 맡기고 싶었어. 그게 너라서 다행이다.',
       'You found me. I wanted someone to finish the checks I left undone when I quit. Glad it was you.'),
      ('— 고스트, 아니 이하윤', '— Ghost. Or rather, Lee Hayun')],
     [
         {'name': 'last_message.txt', 'text': t('c12_d_msg', '고스트: 처음 너한테 준 일 기억나? 카페 PC 의 환영 메모. 그걸 쓴 사람이 나야.', 'Ghost: remember the first job I gave you? The welcome note on the cafe PC. I wrote it.')},
         {'name': 'welcome_meta.txt', 'text': 'file: cafe-pc:/welcome.txt\nauthor: lee.hayun\ncreated: 2026-09-01'},
         {'name': 'staff_list.csv', 'text': 'id,role,status\nlee.hayun,security engineer,left 2026-08\npark.seojun,finance,active\nmin.ho,sales,suspended'},
         {'name': 'handover.txt', 'lock': {'length': 7},
          'text': t('c12_d_handover', '인수인계: 남은 점검은 내가 고른 신입에게 맡긴다. 의뢰는 「고스트」 라는 이름으로 보낸다. — 이하윤', 'Handover: the remaining checks go to a rookie I pick. I will send the jobs as "Ghost". — Lee Hayun')},
     ],
     [
         q('c12', 1, ('고스트는 누구인가?', 'Who is Ghost?'),
           [('이하윤, 전 보안 엔지니어', 'Lee Hayun, former security engineer'), ('박서준, 재무팀', 'Park Seojun, finance'), ('카페 사장', 'The cafe owner')], 0),
         q('c12', 2, ('고스트가 신입에게 일을 맡긴 이유는?', 'Why did Ghost hand jobs to a rookie?'),
           [('퇴사 전에 못다 한 점검을 맡기려고', 'To finish the checks left undone before quitting'), ('돈을 벌려고', 'To make money'), ('그냥 장난', 'Just for fun')], 0),
     ])

os.makedirs(os.path.join(ROOT, 'assets', 'cases'), exist_ok=True)
for c in CASES:
    with open(os.path.join(ROOT, 'assets', 'cases', c['id'] + '.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump(c, f, ensure_ascii=False, indent=1)
import re
for code, table in (('ko', KO), ('en', EN)):
    p = os.path.join(ROOT, 'i18n', code + '.json')
    d = json.load(open(p, encoding='utf-8'))
    d = {k: v for k, v in d.items() if not re.match(r'^c\d\d_', k)}  # 사건 열쇠는 매번 새로(번호가 바뀌어도 옛 열쇠가 남지 않게)
    d.update(table)
    json.dump(d, open(p, 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent=2)
print(len(CASES), 'cases,', len(KO), 'keys')
