/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
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

#import "PinTextField.h"

@implementation PinTextField

@synthesize label;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat w = frame.size.width;
        CGFloat h = frame.size.height;
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w, h)];
        label.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"box"]];
        label.textAlignment = UITextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:32.0f];
        [self addSubview:label];
    }
    return self;
}

@end
