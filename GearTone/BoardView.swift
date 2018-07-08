import UIKit

class BoardView: UIView {
    var background = UIImage()
    
    required init?(coder aDecoder: (NSCoder?)) {
        super.init(coder: aDecoder!)
        background = UIImage(named: "ground.png")!
    }
        
    override func draw(_ rect: CGRect) {
        background.draw(in: bounds)
    }
}

