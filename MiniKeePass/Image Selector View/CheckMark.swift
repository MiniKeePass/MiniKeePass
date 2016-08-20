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
    private let fillColor = UIColor(red: 0.078, green: 0.435, blue: 0.875, alpha: 1)
    private let whiteColor = UIColor.whiteColor()
    
    // Shadow Declarations
    private let shadowColor = UIColor.blackColor()
    private let shadowOffset = CGSizeMake(0.1, -0.1)
    private let shadowBlurRadius: CGFloat = 2.5
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        if (!checked) {
            return
        }

        let context = UIGraphicsGetCurrentContext();
        
        // Sub-rectangle to draw the check mark inside of
        let r = CGRectInset(self.bounds, 3, 3)
        let x = CGRectGetMinX(r)
        let y = CGRectGetMinY(r)
        let w = CGRectGetWidth(r)
        let h = CGRectGetHeight(r)
        
        // Draw the circle background
        CGContextSaveGState(context)
        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadowColor.CGColor)
        fillColor.setFill()
        CGContextFillEllipseInRect(context, r)
        CGContextRestoreGState(context)
        
        // Draw the circle
        CGContextSaveGState(context)
        whiteColor.setStroke()
        CGContextSetLineWidth(context, 1);
        CGContextStrokeEllipseInRect(context, r)
        CGContextRestoreGState(context)
        
        // Draw the check mark
        CGContextSaveGState(context)
        whiteColor.setStroke()
        CGContextSetLineWidth(context, 1.3);
        CGContextSetLineCap(context, CGLineCap.Square)
        CGContextMoveToPoint(context, x + 0.27083 * w, y + 0.54167 * h)
        CGContextAddLineToPoint(context, x + 0.41667 * w, y + 0.68750 * h)
        CGContextAddLineToPoint(context, x + 0.75000 * w, y + 0.35417 * h)
        CGContextStrokePath(context)
        CGContextRestoreGState(context)
    }
}
