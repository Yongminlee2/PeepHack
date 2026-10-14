import XCTest

/// 실기기 점검: 시뮬레이터로는 볼 수 없는 것을 실제 아이폰에서 누르고 찍는다.
/// - 첫 실행 → 첫 임무를 칩으로 끝까지 → 둘째 임무의 비밀번호를 **아이폰 키보드로** 친다
///   (영문 자판인지, ' " 가 둥근 따옴표로·-- 가 긴 줄표로·첫 글자가 대문자로 바뀌지 않는지 — 칸의 값을 그대로 남긴다)
/// - 홈으로 나갔다 돌아와도 그 자리인지
/// - 화면 왼쪽 끝에서 쓸어 뒤로 가기
/// - 한국어로 다시 켜기
/// 앱은 처음 깐 상태여야 한다(run.sh 에 APP= 를 주면 지웠다 다시 깐다).
final class DeviceWalkthroughUITests: XCTestCase {
    var app: XCUIApplication!
    var step = 0

    func snap(_ name: String) {
        step += 1
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = String(format: "%02d_", step) + name; shot.lifetime = .keepAlways; add(shot)
    }

    func note(_ name: String, _ text: String) {
        step += 1
        let a = XCTAttachment(string: text)
        a.name = String(format: "%02d_", step) + name; a.lifetime = .keepAlways; add(a)
    }

    func el(_ label: String, exact: Bool = false) -> XCUIElement {
        let p = exact ? NSPredicate(format: "label == %@", label) : NSPredicate(format: "label BEGINSWITH %@", label)
        return app.descendants(matching: .any).matching(p).firstMatch
    }

    func tap(_ label: String, exact: Bool = false, wait: UInt32 = 2) {
        let e = el(label, exact: exact)
        XCTAssertTrue(e.waitForExistence(timeout: 8), label)
        e.tap(); sleep(wait)
    }

    /// 명령 칩. 지도에도 같은 이름(서버)이 있어서, 같은 이름 중 화면 맨 아래(칩 줄)를 누른다.
    func chip(_ label: String) {
        let q = app.buttons.matching(NSPredicate(format: "label == %@", label))
        XCTAssertTrue(q.firstMatch.waitForExistence(timeout: 8), label)
        let all = q.allElementsBoundByIndex.filter { $0.isHittable }
        (all.max { $0.frame.minY < $1.frame.minY } ?? q.firstMatch).tap()
        sleep(1)
    }

    func run(_ toks: [String]) {
        for t in toks { chip(t) }
        tap("Run", exact: true, wait: 2)
    }

    func launch(_ lang: String) {
        app = XCUIApplication(bundleIdentifier: "com.peep.hack")
        app.launchArguments = ["-AppleLanguages", "(\(lang))", "-AppleLocale", lang == "ko" ? "ko_KR" : "en_US"]
        app.launch()
        sleep(4)
    }

    func testWalkthrough() {
        continueAfterFailure = true
        launch("en")
        snap("title")
        tap("> Jack in")
        snap("modes")
        tap("Operations")
        tap("First Connection")
        snap("brief")
        tap("> Connect", wait: 4)
        snap("mission_start")
        run(["scan"]); run(["connect", "cafe-pc"]); run(["open", "welcome.txt"])
        snap("file")
        tap("Mission complete ▶", wait: 4)
        snap("result")

        // 둘째 임무: 잠긴 서버 → 비밀번호를 키보드로
        tap("Next mission", wait: 2)
        tap("> Connect", wait: 4)
        run(["scan"]); run(["connect", "vault-box"])
        snap("password_prompt")
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "입력칸")
        field.tap(); sleep(2)
        snap("keyboard")
        let probe = "it's \"ok\" -- test"
        field.typeText(probe); sleep(1)
        snap("typed_punctuation")
        let got = (field.value as? String) ?? "(값 없음)"
        note("typed_value", "친 글: \(probe)\n칸의 값: \(got)\n같은가: \(got.hasSuffix(probe) || got == probe)")
        XCTAssertTrue(got.contains(probe), "스마트 구두점·자동 대문자로 바뀜: \(got)")
        tap("Run", exact: true, wait: 2)                 // 틀린 비밀번호
        snap("wrong_password")                           // 틀리면 명령 입력으로 돌아간다(안드로이드와 같음)
        run(["connect", "vault-box"])
        let field2 = app.textFields.firstMatch
        XCTAssertTrue(field2.waitForExistence(timeout: 5), "입력칸")
        field2.typeText("opensesame"); sleep(1)
        tap("Run", exact: true, wait: 3)
        snap("unlocked")

        // 홈으로 나갔다가 돌아오기
        XCUIDevice.shared.press(.home); sleep(3)
        app.activate(); sleep(3)
        snap("after_resume")
        XCTAssertTrue(el("vault-box").exists || el("my-laptop").exists, "돌아온 뒤 임무 화면이 그대로")

        // 뒤로 쓸기: 사건 파일 → 사건 1 → 자료 → 왼쪽 끝에서 쓸기
        tap("Exit", exact: true, wait: 2)
        app.terminate()
        launch("en")
        tap("> Jack in")
        tap("Case files")
        tap("Case 1")
        snap("case")
        tap("admin_access.log", exact: true)
        snap("doc")
        let w = app.windows.firstMatch
        w.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: w.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)))
        sleep(2)
        snap("after_swipe_back")
        XCTAssertTrue(el("// Evidence").exists || el("admin_access.log", exact: true).exists, "사건 화면으로 돌아옴")

        // 브리치 1단계 연습판
        app.terminate()
        launch("en")
        tap("> Jack in")
        tap("Breach")
        snap("breach_list")

        // 한국어로 다시 켜기
        app.terminate()
        launch("ko")
        snap("title_ko")
        tap("> 접속 시작")
        snap("modes_ko")
    }
}
