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

#import "InfoBar.h"

#define AUTO_HIDE_INTERVAL 4.0

@implementation InfoBar

@synthesize label;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = CGRectMake(self.frame.origin.x, -self.frame.size.height, self.frame.size.width, self.frame.size.height);
        
        self.backgroundColor = [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0];
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.textAlignment = UITextAlignmentCenter;
        label.text = @"Finished";
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        [self addSubview:label];
        
        self.hidden = YES;
    }
    return self;
}

- (void)showBar {
    if (self.hidden) {
        self.hidden = NO;
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut
                         animations: ^{
                             self.frame = CGRectMake(self.frame.origin.x, 0, self.frame.size.width, self.frame.size.height);
						 }
                         completion:Nil];
    }
    
    autoHideCount++;
    
    [self performSelector:@selector(autoHide) withObject:Nil afterDelay:AUTO_HIDE_INTERVAL];
}

- (void)hideBar {
    if (!self.hidden) {
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut
                         animations: ^{
                             self.frame = CGRectMake(self.frame.origin.x, -self.frame.size.height, self.frame.size.width, self.frame.size.height);
						 } completion: ^(BOOL done){self.hidden = YES;}];
    }
}

- (void)autoHide {
    if (--autoHideCount == 0) {
        [self hideBar];
    }
}

@end
