import SwiftUI; import AVFoundation
@main struct InfiniteBluesApp: App { @StateObject private var engine = AudioEngine()
var body: some Scene { WindowGroup { ContentView().environmentObject(engine).onAppear{ engine.configureAudioSession() } } } }