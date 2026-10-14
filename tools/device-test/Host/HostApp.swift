import SwiftUI

// UI 테스트를 돌리려면 테스트 대상 앱이 하나 있어야 해서 둔 빈 앱. 실제로 누르는 것은 HackQuest(com.peep.hack)다.
@main
struct HostApp: App {
    var body: some Scene { WindowGroup { Text("HackQuest device test") } }
}
