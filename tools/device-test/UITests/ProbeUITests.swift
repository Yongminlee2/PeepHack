import XCTest

/// 순서를 짜려고 화면 요소(Flutter 가 내주는 이름)를 읽고 찍는다.
final class ProbeUITests: XCTestCase {
    var app: XCUIApplication!
    var step = 0

    func snap(_ name: String) {
        step += 1
        let n = String(format: "%02d_", step) + name
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = n; shot.lifetime = .keepAlways; add(shot)
        let t = XCTAttachment(string: app.debugDescription)
        t.name = n + "_tree"; t.lifetime = .keepAlways; add(t)
    }

    /// 종류를 가리지 않고 이름으로 찾는다(Flutter 카드는 글자 요소로 잡힌다).
    func el(_ label: String, exact: Bool = false) -> XCUIElement {
        let p = exact ? NSPredicate(format: "label == %@", label) : NSPredicate(format: "label BEGINSWITH %@", label)
        return app.descendants(matching: .any).matching(p).firstMatch
    }

    func tap(_ label: String, exact: Bool = false, wait: UInt32 = 2) {
        let e = el(label, exact: exact)
        XCTAssertTrue(e.waitForExistence(timeout: 8), label)
        e.tap(); sleep(wait)
    }

    func testProbe() {
        continueAfterFailure = true
        app = XCUIApplication(bundleIdentifier: "com.peep.hack")
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        sleep(4)
        tap("> Jack in")
        tap("Operations")
        snap("inbox")
        tap("First Connection")
        snap("brief")
        tap("> Connect", wait: 4)
        snap("mission")
        for line in [["scan"], ["connect", "cafe-pc"], ["open", "welcome.txt"]] {
            for tok in line { tap(tok, exact: true, wait: 1) }
            tap("Run", exact: true, wait: 2)
        }
        snap("file")
    }
}
