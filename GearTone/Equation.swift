import UIKit

//v = (t*(t>>q[0]*(t>>q[1]|t>>q[2])&(q[3]|(t>>q[4])*q[5]>>t|t>>q[6])));
//      v = (t * (t>>q[0] * (t>>q[1] | t>>q[2]) & (q[3] | (t>>q[4]) * q[5] >>  t       | t >> q[6])));
//        v = (t * (t>>model.q[0] * (t>>model.q[1] | t>>model.q[2]) & (model.q[3] | (t>>model.q[4]) * model.q[5] >> (t & 15) | t >> model.q[6])));

let MIN_DELAY = 0
let MAX_DELAY = 10

class Equation
{
    var t : UInt = 0
    var memory = [Float]()
    var mIndex = 0
    
    init() {
        for _ in 0..<Int(MAX_DELAY) {
            memory.append(0)
        }
    }
    
    //   let v = (t*(t>>q[0]*(t>>q[1]|t>>q[2])&(q[3]|(t>>q[4])*q[5]>>t|t>>q[6])));
    var v : UInt = 0
    var bV : UInt8 = 0
    var f : Float = 0.0
    
    func iterate() {

        v  = (t >> model.param[0] | t | t >> ((t >> model.param[1]) & 0xF)) * (1 + model.param[2]) + ((t >> model.param[3]) % (1+model.param[4]));

        bV = UInt8(v & 255)
        
        f = Float(MINPITCH) + Float(PITCH_RANGE) * Float(bV) / Float(256.0)
        
        memory[mIndex] = f
        
        mIndex += 1
        if(mIndex >= Int(MAX_DELAY)) {
            mIndex = 0
        }
        
        t += 1
    }
    
    func noteDelayed(_ delay : Int) -> Float {
        var vDelay = delay
        if(vDelay < Int(MIN_DELAY) || vDelay >= Int(MAX_DELAY)) {
            vDelay = Int(MIN_DELAY)
        }
        
        vDelay = mIndex - vDelay - 1 // -1 = account for ++mIndex in iterate
        if(vDelay < 0) { vDelay += Int(MAX_DELAY) }
        
        return memory[vDelay] 
    }
}
