import Foundation
import AVFoundation

class Tone
{
    fileprivate var audioEngn : AVAudioEngine!
    fileprivate var audioFile : AVAudioFile!
    fileprivate var audioNode : AVAudioPlayerNode!
    fileprivate var pitch : AVAudioUnitTimePitch!
    var reverb : AVAudioUnitReverb!
    var mixer : AVAudioMixerNode!
    var volume:Float = 1
    fileprivate var isInitialized = false
    
    // MARK:
    // MARK: initialize
    
    func initialize(_ filename :String) {
        let currentVolume:Float = isInitialized ? mixer.outputVolume : 0.0
        let currentRate:Float = isInitialized ? pitch.rate : 1.0
        
        if let filePath = Bundle.main.path(forResource: filename, ofType:nil) {
            let filePathURL = URL(fileURLWithPath: filePath)
            
            audioEngn = AVAudioEngine()
            
            do {
                try audioFile = AVAudioFile(forReading: filePathURL)
                
                audioNode = AVAudioPlayerNode()
                
                pitch = AVAudioUnitTimePitch()
                pitch.pitch = 1.0
                pitch.rate = 1.0
                
                reverb = AVAudioUnitReverb()
                reverb.loadFactoryPreset(AVAudioUnitReverbPreset.largeChamber)
                reverb.wetDryMix = 0
                
                mixer = AVAudioMixerNode()
                
                audioEngn.reset()
                audioEngn.attach(audioNode)
                audioEngn.attach(reverb)
                audioEngn.attach(pitch)
                audioEngn.attach(mixer)
                
                audioEngn.connect(audioNode, to: pitch, format: nil)
                audioEngn.connect(pitch, to: reverb, format: nil)
                audioEngn.connect(reverb, to: mixer, format: nil)
                audioEngn.connect(mixer, to: audioEngn.outputNode, format: nil)
                
                try audioEngn.start()
                
                mixer.outputVolume = currentVolume
                setRate(currentRate)

            } catch _ {
            }
        }
        
        if(audioFile == nil) {
            print("audio file not loaded: \(filename)")
            exit(0)
        }
        else {
            isInitialized = true;
        }
    }
    
    func setVolume(_ v:Float) {
        volume = v
        mixer.outputVolume = Float(v)
    }
    
    func getVolume() -> Float { return volume }
    
    func isPlaying() -> Bool {
        return mixer.outputVolume  > 0.0
    }
    
    func setReverb(_ v:Float) {
        reverb.wetDryMix = Float(v)
    }
    
    func setRate(_ value :Float) {
        if isInitialized {
            pitch.rate = Float(value)
        }
    }
    
    func getRate() -> Float {
        return pitch.rate
    }
    
    func toneClamp(_ v :Float) -> Float {
        var value = v
        
        if(value < Float(MINPITCH)) {
            value = Float(MINPITCH)
        } else {
            if(value > Float(MAXPITCH)) {
                value = Float(MAXPITCH)
            }
        }
        
        return value
    }
    
    // MARK:
    // MARK: play
    
    func play(_ pitchValue :Float) {
        if isInitialized {
            audioNode.stop()
            audioNode.scheduleFile(audioFile, at: nil, completionHandler:nil)
            
            pitch.pitch = Float(toneClamp(pitchValue))
            
            audioNode.play()
        }
    }
}
