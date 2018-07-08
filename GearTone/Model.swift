import Foundation
import UIKit

let NUM_WHEELS = 10
let NUM_SONGS  = 10

let MAX_PARAM = 8
let MINSIZE:CGFloat = 25
let MAXSIZE:CGFloat = 225
let MINPITCH:CGFloat = -2400.0
let MAXPITCH:CGFloat = +2400.0
let MINRATE:CGFloat =  1.0/32.0
let MAXRATE:CGFloat =  4.0
let MINVOLUME = CGFloat(0)
let MAXVOLUME = CGFloat(1.0)

let PITCH_RANGE = Float(MAXPITCH - MINPITCH)
let DEFAULT_RATE = Float((MINRATE+MAXRATE)/2.0)
let RATE_RANGE = Float(MAXRATE - MINRATE)

struct Voice: RawRepresentable {
    var pitch:Float = 0.0
    var rate:Float = 0.0
    var volume:Float = 0.0
    var tIndex = 0
    
    init() {}
    
    init?(rawValue: NSDictionary) {
        pitch = rawValue["pitch"] as! Float
        rate = rawValue["rate"] as! Float
        volume = rawValue["volume"] as! Float
        tIndex = rawValue["tIndex"] as! Int
    }
    
    var rawValue: NSDictionary {
        return [
            "pitch": pitch,
            "rate": rate,
            "volume": volume,
            "tIndex": tIndex
        ]
    }
}

var tones = [Tone]()

let TCOUNT = 11
let tNames:[String] = [ "choir2.wav","piano.wav","tone2.wav","tone4.wav","tone5.wav","tone6.wav","tone7.wav","tone8.wav",
    "B_SNARE_1.wav","A_HAT_1.WAV","A_TOM_1.WAV"]

struct WheelView {
    var view = UIImageView()
    
    init() {
        view = UIImageView()
        vc.view.addSubview(view)
    }
}

var wheelView = [WheelView]()

var mIndex = -1

struct WheelData {
    var centerX:CGFloat
    var centerY:CGFloat
    var radius:CGFloat
    var pitch:CGFloat
    var rate:CGFloat
    var myIndex:Int

    var rotation:CGFloat
    var rotationAmount:CGFloat
    var type:Int
    var beepCount:Int
    var connected:Bool
    var parent:Int
    
    init() {
        centerX = 0;        centerY = 0
        radius = 0;         pitch = 0
        rate = 0;           myIndex = 0
        rotation = 0;       rotationAmount = 0
        type = 0;           beepCount = 0
        connected = false;  parent = 0
    }
    
    init?(rawValue: NSDictionary) {
        self.init()
        
        centerX = rawValue["centerX"] as! CGFloat
        centerY = rawValue["centerY"] as! CGFloat
        radius = rawValue["radius"] as! CGFloat
        pitch = rawValue["pitch"] as! CGFloat
        rate = rawValue["rate"] as! CGFloat
        myIndex = rawValue["myIndex"] as! Int
    }
    
    var rawValue: NSDictionary {
        return [
            "centerX": centerX,
            "centerY": centerY,
            "radius": radius,
            "pitch": pitch,
            "rate": rate,
            "myIndex" : myIndex
        ]
    }

    mutating func updateRect() {
        let dia = radius * 2.0
        wheelView[myIndex].view.frame = CGRect(x: centerX - radius,y: centerY - radius,width: dia,height: dia)
    }
    
    func pointInRect(_ pt:CGPoint) -> Bool {
        return wheelView[myIndex].view.frame.contains(pt)
    }
    
    mutating func update() {
        type = 0
        if(connected) {
            type = 1
            
            rotation += rotationAmount * speedFactor
            
            let circle = CGFloat(360)
            
            if(rotation < 0) {
                rotation += circle
                type = 2
                beepCount = 5
                soundTone()
            }
            else
                if(rotation >= circle) {
                    rotation -= circle
                    beepCount = 5
                    soundTone()
            }
        }
        
        if(connected) {
            if(beepCount > 0) {
                beepCount -= 1
                type = 2
            }
        }
        
        if(myIndex == 0) { type = 2 } // hub wheel
        
        if(myIndex == mIndex) {
            type += 3
        }
        
        wheelView[myIndex].view.image = gears[type].rotated(rotation)
    }
    
    func soundTone() {
        if(myIndex > 0) {
            let v = tones[myIndex].toneClamp(model.equation.noteDelayed(0) + Float(pitch))
            tones[myIndex ].play(v)
            
            model.equation.iterate()
        }
        
        // print(NSString(format:"soundTone %d",index), appendNewline: true)
    }
    
}

// MARK:
// MARK: class Model

class Model
{
    var equation = Equation()
    var voice = [Voice]()
    var wheel = [WheelData]()
    var param = [UInt]()
    
    init() {
        for i:Int in 0..<NUM_WHEELS {
            voice.append(Voice())
            voice[i].pitch = 0.0
            voice[i].rate = 1.0
            voice[i].volume = 0.0
            voice[i].tIndex = 1
        }
        
        for _ in 0..<MAX_PARAM {
            param.append(0)
        }
        
        for i:Int in 0..<TCOUNT {
            tones.append(Tone())
            tones[i].initialize(tNames[i])
            tones[i].setVolume(1)
        }
        
        for _ in 0 ..< NUM_WHEELS {
            wheelView.append(WheelView())
        }

        for i in 0 ..< NUM_WHEELS {
            let wd = WheelData()
            wheel.append(wd)
            wheel[i].myIndex = i
            wheel[i].radius = 30.0 + CGFloat(arc4random_uniform(UInt32(120)))
            
            let dx = i % 4
            let dy = i / 4
            
            wheel[i].centerX = CGFloat(150 + dx * 200)
            wheel[i].centerY = CGFloat(200 + dy * 200)
            wheel[i].updateRect()
            
            if(i == 0) {
                wheel[i].connected = true
                wheel[i].type = 1
                wheel[i].rotationAmount = 3
            }
        }
        
    }
    
    // MARK:

    func equationLegend() -> String {
        let s = NSString(format:"(t >> A(%d) | t | t >> (t >> B(%d))) * (1 + C(%d)) + ((t >> D(%d)) %% (1 + E(%d)))",
            param[0],param[1],param[2],param[3],param[4])
        return s as String
    }
    
    // MARK:
    
    func step() {
        for i in 1 ..< NUM_WHEELS {  // break all connections
            wheel[i].connected = false
            wheel[i].rotationAmount = 0
        }
        
        while(true) {
            connectionMade = false
            
            for child in 1 ..< NUM_WHEELS {
                if(wheel[child].connected) { continue }
                
                let f1X = wheel[child].centerX
                let f1Y = wheel[child].centerY
                
                for parent in 0 ..< NUM_WHEELS {
                    if(parent == child) { continue }
                    if(!wheel[parent].connected) { continue }
                    
                    let f2X = wheel[parent].centerX
                    let f2Y = wheel[parent].centerY
                    let distance = hypotf(Float(f1X-f2X),Float(f1Y-f2Y))
                    
                    if(fabs(distance - Float(wheel[parent].radius + wheel[child].radius)) < 15.0) {
                        wheel[child].connected = true
                        wheel[child].parent = parent
                        wheel[child].rotationAmount = -wheel[parent].rotationAmount * wheel[parent].radius / wheel[child].radius
                        connectionMade = true
                        break
                    }
                }
            }
            
            if(!connectionMade) { break }
        }
        
        for i in 0 ..< NUM_WHEELS {
            wheel[i].update()
        }
    }
    
    // MARK:
    // MARK: adjustConnections
    
    func adjustConnections(_ checkAll:Int) {
        for i in 1 ..< NUM_WHEELS {
            
            if(checkAll==0 && i == mIndex) { continue }
            if(!wheel[i].connected) { continue }
            
            let w1 = wheel[i]
            let w2 = wheel[w1.parent]
            let desiredDistance = Float(w1.radius + w2.radius)
            let dx = Float(w2.centerX - w1.centerX)
            let dy = Float(w2.centerY - w1.centerY)
            let angle = atan2f(dy,dx)
            
            wheel[i].centerX = CGFloat(Float(w2.centerX) - cosf(angle) * desiredDistance)
            wheel[i].centerY = CGFloat(Float(w2.centerY) - sinf(angle) * desiredDistance)
            wheel[i].updateRect()
        }
    }
    
    // MARK:

    func fileName(_ index:Int) -> String {
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return "" }
        return documentsPath + (NSString(format:"/Song%d",index) as String)
    }
    
    // MARK:
    // MARK: save
    
    func saveSong(_ index:Int) {
        let logPath = fileName(index)
        
        let plist: NSDictionary = [
            "voices": voice.map { v in v.rawValue },
            "wheels": wheel.map { w in w.rawValue },
            "params": param
        ]
        
        do {
            let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: PropertyListSerialization.PropertyListFormat.binary, options: 0)
            try plistData.write(to: URL(fileURLWithPath: logPath), options: [])
        } catch _ {
        }
    }
    
    // MARK:
    // MARK: load
    
    func loadSong(_ index:Int) {
        let logPath = fileName(index)
        let plist: NSDictionary
        
        if(FileManager().fileExists(atPath: logPath)) {
            do {
                let plistData = try Data(contentsOf: URL(fileURLWithPath: logPath), options: [])
                plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as! NSDictionary
            } catch _ {
                return
            }
        }
        else {
            return
        }
        
        voice = (plist["voices"] as! [NSDictionary]).map { dict in Voice(rawValue: dict)! }
        wheel = (plist["wheels"] as! [NSDictionary]).map { dict in WheelData(rawValue: dict)! }
        param = plist["params"] as! [UInt]
        
        for i in 0 ..< NUM_WHEELS {
            wheel[i].updateRect()
            
            if(i == 0) {
                wheel[i].connected = true
                wheel[i].type = 1
                wheel[i].rotationAmount = 3
            }
            
            let index = voice[i].tIndex
            tones[i].initialize(tNames[index])
        }
        
        vc.view.setNeedsDisplay()
        vc.updateEquationWidgets()
        vc.updateSelectedWheelData()
    }
}
