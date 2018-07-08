import UIKit

var vc = ViewController()
var model = Model()
var gears = [UIImage]()

var connectionMade = false
var speedFactor:CGFloat = 1.0

let SLOWEST_SPEED = Int(100)

class ViewController: UIViewController,UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate {
    
    var speed = 3

    @IBOutlet var boardView: BoardView!
    @IBOutlet var frame1: UIView!
    @IBOutlet var frame2: UIView!
    @IBOutlet var frame3: UIView!
    @IBOutlet var frame4: UIView!
    @IBOutlet var pitch: UISlider!
    @IBOutlet var rate: UISlider!
    @IBOutlet var size: UISlider!
    @IBOutlet var volume: UISlider!
    @IBOutlet var equA: UISlider!
    @IBOutlet var equB: UISlider!
    @IBOutlet var equC: UISlider!
    @IBOutlet var equD: UISlider!
    @IBOutlet var equE: UISlider!
    @IBOutlet var voiceSelect: UIButton!
    @IBOutlet var equationLegend: UILabel!
    
    func displayName(_ index:Int) -> String {
        return (NSString(format:"Song #%d",index) as String)
    }
    
    // MARK:
    // MARK: save/load 
    
    @IBAction func saveSong(_ sender: UIButton) {
        let alert = UIAlertController(title: "Save Song", message: "Select storage location", preferredStyle: .actionSheet)
        
        for i:Int in 1...NUM_SONGS {
            let sa = UIAlertAction(title: displayName(i), style: .default) { action -> Void in model.saveSong(i) }
            alert.addAction(sa)
        }
        
        alert.view.subviews[0].subviews[0].backgroundColor = UIColor.black
        alert.popoverPresentationController?.sourceView = sender
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func loadSong(_ sender: UIButton) {
        let alert = UIAlertController(title: "Load Song", message: "Select storage location", preferredStyle: .actionSheet)
        
        for i:Int in 1...NUM_SONGS {
            let sa = UIAlertAction(title: displayName(i), style: .default) { action -> Void in model.loadSong(i) }
            alert.addAction(sa)
        }
        
        alert.view.subviews[0].subviews[0].backgroundColor = UIColor.darkGray
        alert.popoverPresentationController?.sourceView = sender
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK:

    @IBAction func pitchChanged(_ s: UISlider) {
        if(mIndex >= 0 && mIndex < NUM_WHEELS) {
            model.wheel[mIndex].pitch = MINPITCH + CGFloat(s.value) * (MAXPITCH-MINPITCH)
        }
    }
    
    @IBAction func rateChanged(_ s: UISlider) {
        if(mIndex >= 0 && mIndex < NUM_WHEELS) {
            tones[mIndex].setRate(Float(MINRATE) + s.value * Float(MAXRATE-MINRATE))
        }
    }

    @IBAction func sizeChanged(_ s: UISlider) {
        if(mIndex >= 0 && mIndex < NUM_WHEELS) {
            model.wheel[mIndex].radius = MINSIZE + CGFloat(s.value) * (MAXSIZE-MINSIZE)
            model.wheel[mIndex].updateRect()
            model.adjustConnections(1)
        }
    }
    
    @IBAction func volumeChanged(_ s: UISlider) {
        if(mIndex >= 0 && mIndex < NUM_WHEELS) {
            tones[mIndex].setVolume(Float(MINVOLUME) + s.value * Float(MAXVOLUME-MINVOLUME))
        }
    }
    
    @IBAction func reverbChanged(_ s: UISlider) {
        for i:Int in 0 ..< NUM_WHEELS {
            tones[i].setReverb(s.value * 100.0)
        }
    }
    
    func sliderScaled(_ value:CGFloat, min:CGFloat,max:CGFloat) -> Float {
        var value = value
        value -= min
        return Float(value / (max-min))
    }
    
    // MARK:
    // MARK: updateSelectedWheelData
    
    func updateSelectedWheelData() {
        if(mIndex >= 0 && mIndex < NUM_WHEELS) {
            voiceSelect.setTitle(tNames[model.voice[mIndex].tIndex], for: UIControlState())
            pitch.value = sliderScaled(CGFloat(tones[mIndex].getRate()), min:MINRATE, max:MAXRATE)
            volume.value = sliderScaled(CGFloat(tones[mIndex].getVolume()), min:MINVOLUME, max:MAXVOLUME)
            rate.value = sliderScaled(CGFloat(tones[mIndex].getRate()), min:MINRATE, max:MAXRATE)

            let w = model.wheel[mIndex]
            size.value = sliderScaled(w.radius, min:MINSIZE, max:MAXSIZE)
            pitch.value = sliderScaled(w.pitch, min:MINPITCH, max:MAXPITCH)
        }
    }
    
    func voiceAssigned(_ index:Int, sender:UIButton) {
        model.voice[mIndex].tIndex = index
        tones[mIndex].initialize(tNames[index])
        updateSelectedWheelData()
    }
    
    func assignVoice(_ sender: UIButton) {
        let title = "Select Voice"
        let alert = UIAlertController(title:title, message: "", preferredStyle: .actionSheet)
        
        for i:Int in 0..<TCOUNT {
            let sa = UIAlertAction(title: tNames[i], style: .default) {
                _ in self.voiceAssigned(i, sender:sender)
            }
            alert.addAction(sa)
        }
        
        let v2 = alert.view.subviews[0].subviews[0]
        v2.backgroundColor = UIColor.black
        v2.tintColor = UIColor.red
        
        alert.popoverPresentationController?.sourceView = sender
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func voiceChanged(_ s: UIButton) {
        if(mIndex >= 0 && mIndex < NUM_WHEELS) {
            assignVoice(s)
        }
    }
 
    //----------------
    
    @IBAction func equAChanged(_ s: UISlider) {  updateEquationParam(0, value:s.value)  }
    @IBAction func equBChanged(_ s: UISlider) {  updateEquationParam(1, value:s.value)  }
    @IBAction func equCChanged(_ s: UISlider) {  updateEquationParam(2, value:s.value)  }
    @IBAction func equDChanged(_ s: UISlider) {  updateEquationParam(3, value:s.value)  }
    @IBAction func equEChanged(_ s: UISlider) {  updateEquationParam(4, value:s.value)  }
    @IBAction func speedChanged(_ s: UISlider) { speedFactor = CGFloat(s.value)  }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vc = self
        
        gears.append(UIImage(named: "gear1.png")!)
        gears.append(UIImage(named: "gear2.png")!)
        gears.append(UIImage(named: "gear3.png")!)
        gears.append(UIImage(named: "gear1B.png")!)
        gears.append(UIImage(named: "gear2B.png")!)
        gears.append(UIImage(named: "gear3B.png")!)
        
        adjustFrame(frame1)
        adjustFrame(frame2)
        adjustFrame(frame3)
        adjustFrame(frame4)
        
        updateEquationWidgets()

        let timer = CADisplayLink(target: self, selector: #selector(ViewController.step))
        timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    // MARK:
    // MARK: touch
    var touchBeganPoint = CGPoint.zero
   
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let pt = touch.location(in: self.view)
            for i in 0 ..< NUM_WHEELS {
                if(model.wheel[i].pointInRect(pt)) {
                    touchBeganPoint = pt
                    mIndex = i
                    updateSelectedWheelData()
                    break
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if(mIndex >= 0) {
                let pt = touch.location(in: self.view)
                model.wheel[mIndex].centerX = pt.x
                model.wheel[mIndex].centerY = pt.y
                model.wheel[mIndex].updateRect()
                model.adjustConnections(0)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        model.adjustConnections(1)
    }

    // MARK:
    func updateEquationWidgets() {
        equationLegend.text = model.equationLegend()
        equA.value = sliderScaled(CGFloat(model.param[0]), min:0, max:15)
        equB.value = sliderScaled(CGFloat(model.param[1]), min:0, max:15)
        equC.value = sliderScaled(CGFloat(model.param[2]), min:0, max:15)
        equD.value = sliderScaled(CGFloat(model.param[3]), min:0, max:15)
        equE.value = sliderScaled(CGFloat(model.param[4]), min:0, max:15)
    }
    
    func updateEquationParam(_ index:Int, value:Float) {
        model.param[index] = UInt(value * 15.0)
        updateEquationWidgets()
    }
    
    func step() { model.step() }
    
    // MARK:

    func adjustFrame(_ frame : UIView) {
        frame.layer.isOpaque = true
        frame.layer.cornerRadius = CGFloat(12.0)
        frame.layer.shadowColor = UIColor.black.cgColor
        frame.layer.shadowOffset = CGSize(width: 2, height: 2)
        frame.layer.shadowOpacity = 1.0
        frame.layer.shadowRadius = 2
    }
    
    override var prefersStatusBarHidden : Bool { return true;  }
}

// MARK:

extension UIImage {
    public func rotated(_ degrees: CGFloat) -> UIImage {
        let degreesToRadians: (CGFloat) -> CGFloat = { return $0 / 180.0 * CGFloat(Float.pi) }
        
        UIGraphicsBeginImageContext(size)
        let bitmap = UIGraphicsGetCurrentContext()
        let center = size.width / 2.0
        
        bitmap?.translateBy(x: center,y: center)
        bitmap?.rotate(by: degreesToRadians(CGFloat(degrees)))
        bitmap?.draw(cgImage!, in: CGRect(x: -center, y: -center, width: size.width, height: size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}



