import SwiftUI

@main
struct AimpPlayerApp: App {
    @StateObject private var audioService = AudioEngineService()
    @StateObject private var fileManagerService = FileManagerService()
    
    var body: some Scene {
        WindowGroup {
            MainPlayerView(
                audioService: audioService,
                fileManagerService: fileManagerService
            )
            .preferredColorScheme(.dark) // AIMP es inherentemente tema oscuro
        }
    }
}
