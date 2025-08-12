import SwiftUI
struct ContentView: View {
    @EnvironmentObject var engine: AudioEngine; @State private var isPlaying=false; @State private var presetIndex=0; @State private var tapTimes:[Date]=[]
    var body: some View {
        ZStack { SunburstBackground(); VStack(spacing:16){
            Text("INFINITE BLUES").font(.system(size:28,weight:.heavy,design:.rounded)).foregroundColor(Theme.ink).shadow(radius:8)
            VStack(alignment:.leading, spacing:10){
                HStack{ Text("Preset").font(.caption).foregroundColor(.white.opacity(0.7)); Spacer(); Text(Presets.all[presetIndex].name).font(.headline).foregroundColor(Theme.ink) }
                HStack{ Button("◀︎"){prevPreset()}.buttonStyle(BigGlass()); Button("▶︎"){nextPreset()}.buttonStyle(BigGlass()); Spacer(); Button("Tap Tempo"){tapTempo()}.buttonStyle(SmallGlass()) }
            }.padding(14).background(Theme.card).cornerRadius(16)
            VStack(spacing:10){
                HStack{
                    Picker("Key", selection:$engine.state.key){ ForEach(NoteName.allCases, id:\.self){ Text($0.rawValue).tag($0)} }.pickerStyle(.segmented)
                    Picker("Style", selection:$engine.state.style){ ForEach(BluesStyle.allCases, id:\.self){ Text($0.title).tag($0)} }.pickerStyle(.menu)
                }
                LabeledSlider("Tempo", value:$engine.state.bpm, range:60...140, step:1, suffix:"bpm")
                HStack{ LabeledSlider("Drive", value:$engine.state.drive, range:0...1, step:0.01); LabeledSlider("Tone", value:$engine.state.brightness, range:1200...3500, step:1) }
                HStack{ LabeledSlider("Delay", value:$engine.state.delayMs, range:60...320, step:1, suffix:"ms"); LabeledSlider("Reverb", value:$engine.state.reverbMix, range:0...1, step:0.01) }
                HStack{ LabeledSlider("Swing", value:$engine.state.swing, range:0...0.5, step:0.01); LabeledSlider("Intensity", value:$engine.state.intensity, range:0.2...1.0, step:0.01) }
                LabeledSlider("Cab IR Mix", value:$engine.state.cabIRMix, range:0...1, step:0.01)
                Toggle("Humanize timing & accents", isOn:$engine.state.humanize); Toggle("Stop-time fills", isOn:$engine.state.stopTime)
            }.padding(14).background(Theme.card).cornerRadius(16)
            HStack(spacing:12){
                Button(action:toggle){ Text(isPlaying ? "Pause":"Start").font(.system(size:20,weight:.heavy)).padding(.vertical,14).padding(.horizontal,22).foregroundColor(.black).background(Theme.accent).cornerRadius(16).shadow(radius:10) }
                Button("Save as Default"){engine.saveDefault()}.buttonStyle(SmallGlass())
            }
        }.padding(16)} }.onReceive(engine.$isRunning){isPlaying=$0}.onAppear{applyPreset()} }
    func applyPreset(){ engine.apply(preset: Presets.all[presetIndex]) }
    func nextPreset(){ presetIndex=(presetIndex+1)%Presets.all.count; applyPreset() }
    func prevPreset(){ presetIndex=(presetIndex-1+Presets.all.count)%Presets.all.count; applyPreset() }
    func tapTempo(){ let now=Date(); tapTimes.append(now); tapTimes=tapTimes.suffix(4); if tapTimes.count>=2{ let intervals=zip(tapTimes.dropFirst(),tapTimes).map{$0.0.timeIntervalSince($0.1)}; let avg=intervals.reduce(0,+)/Double(intervals.count); engine.state.bpm=max(50,min(160,60.0/avg)) } }
    func toggle(){ isPlaying ? engine.pause() : engine.start() }
}
struct LabeledSlider: View{ let title:String; @Binding var value:Double; let range:ClosedRange<Double>; var step:Double=1; var suffix:String=""
    var body: some View{
        VStack(alignment:.leading, spacing:4){
            HStack{ Text(title).font(.caption).foregroundColor(.white.opacity(0.75)); Spacer(); Text(suffix.isEmpty ? String(format:"%.0f",value):String(format:"%.0f %@",value,suffix)).font(.caption).foregroundColor(.white.opacity(0.75)) }
            Slider(value:$value, in:range, step:step)
        }
    }
}
struct SmallGlass: ButtonStyle{ func makeBody(configuration: Configuration)->some View{ configuration.label.foregroundColor(Theme.ink).padding(.vertical,8).padding(.horizontal,12).background(Theme.card).cornerRadius(12).opacity(configuration.isPressed ? 0.7:1.0) } }
struct BigGlass: ButtonStyle{ func makeBody(configuration: Configuration)->some View{ configuration.label.font(.system(size:18,weight:.heavy)).foregroundColor(Theme.ink).padding(.vertical,10).padding(.horizontal,16).background(Theme.card).cornerRadius(12).opacity(configuration.isPressed ? 0.7:1.0) } }