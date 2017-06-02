/*
 * Copyright 2016 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit

/*
 * Adapted from SSCheckMark found on Stack Overflow
 */
class CheckMark: UIView {
    var checked = false {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    // Color Declarations
    fileprivate let fillColor = UIColor(red: 0.078, green: 0.435, blue: 0.875, alpha: 1)
    fileprivate let whiteColor = UIColor.white
    
    // Shadow Declarations
    fileprivate let shadowColor = UIColor.black
    fileprivate let shadowOffset = CGSize(width: 0.1, height: -0.1)
    fileprivate let shadowBlurRadius: CGFloat = 2.5
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if (!checked) {
            return
        }

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Sub-rectangle to draw the check mark inside of
        let r = self.bounds.insetBy(dx: 3, dy: 3)
        let x = r.minX
        let y = r.minY
        let w = r.width
        let h = r.height
        
        // Draw the circle background
        context.saveGState()
        context.setShadow(offset: shadowOffset, blur: shadowBlurRadius, color: shadowColor.cgColor)
        fillColor.setFill()
        context.fillEllipse(in: r)
        context.restoreGState()
        
        // Draw the circle
        context.saveGState()
        whiteColor.setStroke()
        context.setLineWidth(1);
        context.strokeEllipse(in: r)
        context.restoreGState()
        
        // Draw the check mark
        context.saveGState()
        whiteColor.setStroke()
        context.setLineWidth(1.3);
        context.setLineCap(CGLineCap.square)
        context.move(to: CGPoint(x: x + 0.27083 * w, y: y + 0.54167 * h))
        context.addLine(to: CGPoint(x: x + 0.41667 * w, y: y + 0.68750 * h))
        context.addLine(to: CGPoint(x: x + 0.75000 * w, y: y + 0.35417 * h))
        context.strokePath()
        context.restoreGState()
    }
}
