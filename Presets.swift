import Foundation
struct BluesPreset: Identifiable, Equatable { let id = UUID(); let name:String; let style:BluesStyle; let key:NoteName; let bpm:Double; let drive:Double; let brightness:Double; let delayMs:Double; let reverb:Double; let mood:Mood; let swing:Double; let intensity:Double; let cabIRMix:Double }
enum Presets { static let all:[BluesPreset] = [
.init(name:"SRV Texas Boogie", style:.texasBoogie, key:.E, bpm:96, drive:0.58, brightness:2300, delayMs:160, reverb:0.14, mood:.classic, swing:0.12, intensity:0.75, cabIRMix:0.6),
.init(name:"Kingfish Thick", style:.texasBoogie, key:.G, bpm:92, drive:0.62, brightness:2100, delayMs:140, reverb:0.20, mood:.smooth, swing:0.10, intensity:0.8, cabIRMix:0.7),
.init(name:"Marcus Vintage", style:.chicago, key:.A, bpm:98, drive:0.42, brightness:2600, delayMs:180, reverb:0.14, mood:.classic, swing:0.16, intensity:0.6, cabIRMix:0.5),
.init(name:"Chicago Shuffle", style:.swingShuffle, key:.A, bpm:112, drive:0.48, brightness:2400, delayMs:150, reverb:0.16, mood:.raw, swing:0.3, intensity:0.7, cabIRMix:0.55),
.init(name:"Slow 6/8", style:.slowBlues, key:.D, bpm:72, drive:0.52, brightness:2200, delayMs:180, reverb:0.22, mood:.smooth, swing:0.25, intensity:0.55, cabIRMix:0.65),
.init(name:"Soul Ballad", style:.soulBallad, key:.C, bpm:70, drive:0.35, brightness:2500, delayMs:200, reverb:0.24, mood:.smooth, swing:0.18, intensity:0.45, cabIRMix:0.5)
] }