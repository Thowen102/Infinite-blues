import Foundation, AVFoundation, MediaPlayer, Accelerate, UIKit
enum NoteName:String, CaseIterable{case C="C",Csh="C#",D="D",Dsh="D#",E="E",F="F",Fsh="F#",G="G",Gsh="G#",A="A",Ash="A#",B="B"}
enum BluesStyle:CaseIterable{case texasBoogie,swingShuffle,slowBlues,chicago,soulBallad; var title:String{switch self{case .texasBoogie:"Texas Boogie";case .swingShuffle:"Swing Shuffle";case .slowBlues:"Slow Blues";case .chicago:"Chicago";case .soulBallad:"Soul Ballad"}}}
enum Mood:CaseIterable{case raw,classic,smooth; var title:String{switch self{case .raw:"Raw";case .classic:"Classic";case .smooth:"Smooth"}}}
struct EngineState{var key:NoteName=.E; var style:BluesStyle=.texasBoogie; var bpm:Double=96; var brightness:Double=2400; var drive:Double=0.55; var delayMs:Double=160; var reverbMix:Double=0.15; var humanize:Bool=true; var stopTime:Bool=true; var mood:Mood=.classic; var swing:Double=0.15; var intensity:Double=0.7; var cabIRMix:Double=0.6}
final class AudioEngine:ObservableObject{
    @Published var isRunning=false; @Published var state=EngineState()
    let engine=AVAudioEngine(); let master=AVAudioMixerNode(); let leadMixer=AVAudioMixerNode(); let rhythmMixer=AVAudioMixerNode(); let bassMixer=AVAudioMixerNode(); let drumMixer=AVAudioMixerNode()
    let leadDist=AVAudioUnitDistortion(); let leadDelay=AVAudioUnitDelay(); let leadVerb=AVAudioUnitReverb(); let leadEQ=AVAudioUnitEQ(numberOfBands:4)
    let masterComp=AVAudioUnitDynamicsProcessor()
    let leadPlayer=AVAudioPlayerNode(); let rhythmPlayer=AVAudioPlayerNode(); let bassPlayer=AVAudioPlayerNode(); let drumPlayer=AVAudioPlayerNode()
    var displayLink:CADisplayLink?; var nextBeatTime:AVAudioTime?; let lookaheadBeats:Double=0.75; var barCount=0; var beatCount=0
    let brain=BluesBrain()
    init(){ setupGraph(); setupRemote() }
    func configureAudioSession(){ do{ let s=AVAudioSession.sharedInstance(); try s.setCategory(.playback, mode:.default, options:[.allowBluetooth,.mixWithOthers]); try s.setActive(true) }catch{ print(error)} }
    func start(){ if !engine.isRunning{ try? engine.start() }; isRunning=true; scheduleTransportStart(); startSchedulerLoop(); updateFX(); updateNowPlaying(play:true) }
    func pause(){ isRunning=false; stopSchedulerLoop(); [leadPlayer,rhythmPlayer,bassPlayer,drumPlayer].forEach{$0.pause()}; updateNowPlaying(play:false) }
    func apply(preset:BluesPreset){ state.key=preset.key; state.style=preset.style; state.bpm=preset.bpm; state.drive=preset.drive; state.brightness=preset.brightness; state.delayMs=preset.delayMs; state.reverbMix=preset.reverb; state.mood=preset.mood; state.swing=preset.swing; state.intensity=preset.intensity; state.cabIRMix=preset.cabIRMix; updateFX(); updateNowPlaying(play:isRunning) }
    func saveDefault(){}; func loadDefaultPresetIndex()->Int?{nil}
    func setupGraph(){ engine.attach(leadMixer); engine.attach(rhythmMixer); engine.attach(bassMixer); engine.attach(drumMixer); engine.attach(leadDist); engine.attach(leadDelay); engine.attach(leadVerb); engine.attach(leadEQ); engine.attach(masterComp); engine.attach(leadPlayer); engine.attach(rhythmPlayer); engine.attach(bassPlayer); engine.attach(drumPlayer); engine.attach(master)
        engine.connect(leadPlayer, to:leadDist, format:nil); engine.connect(leadDist, to:leadEQ, format:nil); engine.connect(leadEQ, to:leadDelay, format:nil); engine.connect(leadDelay, to:leadVerb, format:nil); engine.connect(leadVerb, to:leadMixer, format:nil)
        engine.connect(rhythmPlayer, to:rhythmMixer, format:nil); engine.connect(bassPlayer, to:bassMixer, format:nil); engine.connect(drumPlayer, to:drumMixer, format:nil)
        engine.connect(leadMixer, to:masterComp, format:nil); engine.connect(rhythmMixer, to:masterComp, format:nil); engine.connect(bassMixer, to:masterComp, format:nil); engine.connect(drumMixer, to:masterComp, format:nil); engine.connect(masterComp, to:master, format:nil); engine.connect(master, to:engine.outputNode, format:engine.outputNode.inputFormat(forBus:0))
        leadDist.loadFactoryPreset(.multiDistortedCubed); leadDist.preGain = -6; leadDist.wetDryMix=35; leadDelay.wetDryMix=22; leadDelay.feedback=18; leadDelay.delayTime=0.16; leadVerb.loadFactoryPreset(.plate2); leadVerb.wetDryMix=12; let b=leadEQ.bands; b[0].filterType=.highPass; b[0].frequency=110; b[1].filterType=.parametric; b[1].frequency=800; b[1].gain=-2; b[1].bandwidth=1.0; b[2].filterType=.parametric; b[2].frequency=2400; b[2].gain=1.5; b[2].bandwidth=0.7; b[3].filterType=.lowPass; b[3].frequency=5800; master.outputVolume=0.9; masterComp.threshold=-6; masterComp.attackTime=0.003; masterComp.releaseTime=0.06; try? engine.start() }
    func updateFX(){ leadDist.wetDryMix=Float(20+state.drive*50); leadEQ.bands[3].frequency=Float(state.brightness); leadDelay.delayTime=state.delayMs/1000.0; leadVerb.wetDryMix=Float(state.reverbMix*100)}
    func scheduleTransportStart(){ let now=engine.outputNode.lastRenderTime ?? AVAudioTime(hostTime: mach_absolute_time()); nextBeatTime = AVAudioTime(hostTime: now.hostTime); [leadPlayer,rhythmPlayer,bassPlayer,drumPlayer].forEach{$0.play(at: nextBeatTime)}; barCount=0; beatCount=0 }
    func startSchedulerLoop(){ stopSchedulerLoop(); displayLink = CADisplayLink(target:self, selector:#selector(step)); displayLink?.preferredFramesPerSecond=60; displayLink?.add(to:.current, forMode:.common) }
    func stopSchedulerLoop(){ displayLink?.invalidate(); displayLink=nil }
    @objc func step(){ guard isRunning, let ref=engine.outputNode.lastRenderTime, let pt=leadPlayer.playerTime(forNodeTime: ref) else {return}; let beatDur=60.0/state.bpm; let nowSec=Double(pt.sampleTime)/pt.sampleRate; var nextSec=nextBeatTimeSec(); while nextSec < nowSec + lookaheadBeats*beatDur { scheduleBeat(timeSec: nextSec, beatDur: beatDur); nextSec += beatDur; nextBeatTime = timeFromStart(seconds: nextSec) } }
    func nextBeatTimeSec()->Double{ guard let start=engine.outputNode.lastRenderTime, let _=leadPlayer.playerTime(forNodeTime:start), let next=nextBeatTime, let nb=leadPlayer.playerTime(forNodeTime: next) else {return 0}; return Double(nb.sampleTime)/nb.sampleRate }
    func timeFromStart(seconds:Double)->AVAudioTime{ let sr=engine.outputNode.outputFormat(forBus:0).sampleRate; return AVAudioTime(sampleTime: AVAudioFramePosition(seconds*sr), atRate: sr) }
    func scheduleBeat(timeSec:Double, beatDur:Double){ let swingPush = (beatCount % 2 == 1) ? state.swing*beatDur*0.5 : 0; let t = timeSec + swingPush; if Double.random(in:0...1) < state.intensity { let rootMidi = 57; let ev = LeadEvent(midi:rootMidi+12, durBeats:0.5, vel:0.95, bendSemis:1, slide:false, doubleStop:false, hammer:false, offset:0, rake:true, vibratoDepth:0.2); scheduleLead(event: ev, at: t) } beatCount += 1 }
    func scheduleLead(event:LeadEvent, at:Double){ let sr=engine.outputNode.outputFormat(forBus:0).sampleRate; var buf=Synthesis.makeLeadBuffer(sampleRate: sr, event: event, brightness: state.brightness, drive: state.drive, mood: state.mood); leadPlayer.scheduleBuffer(buf, at: timeFromStart(seconds: at), options: [], completionHandler: nil) }
    func setupRemote(){ let c=MPRemoteCommandCenter.shared(); c.playCommand.addTarget{ _ in self.start(); return .success }; c.pauseCommand.addTarget{ _ in self.pause(); return .success }; c.togglePlayPauseCommand.addTarget{ _ in self.isRunning ? self.pause() : self.start(); return .success } }
    func updateNowPlaying(play:Bool){ var info=[String:Any](); info[MPMediaItemPropertyTitle]="Infinite Blues"; info[MPNowPlayingInfoPropertyPlaybackRate]=play ? 1.0 : 0.0; MPNowPlayingInfoCenter.default().nowPlayingInfo=info }
}
struct LeadEvent { var midi:Int; var durBeats:Double; var vel:Double; var bendSemis:Double; var slide:Bool; var doubleStop:Bool; var hammer:Bool; var offset:Double; var rake:Bool=false; var vibratoDepth:Double=0.0 }
enum Synthesis {
    static func makeLeadBuffer(sampleRate:Double, event:LeadEvent, brightness:Double, drive:Double, mood:Mood)->AVAudioPCMBuffer{
        let dur = max(0.12, event.durBeats * 0.6)
        let frames = AVAudioFrameCount(max(1, dur * sampleRate))
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buf.frameLength = frames
        let p = buf.floatChannelData![0]
        var phase = 0.0; let f0 = 440.0; let bendTarget = f0 * pow(2.0, event.bendSemis/12.0)
        for n in 0..<Int(frames) {
            let t = Double(n)/sampleRate
            let prog = min(1.0, t/0.15)
            let f = f0 + (bendTarget - f0) * prog
            phase += 2.0 * .pi * f / sampleRate
            let env = exp(-t*6.0)
            p[n] = Float(sin(phase) * env * event.vel)
        }
        return buf
    }
}