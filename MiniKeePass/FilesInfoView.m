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

#import "FilesInfoView.h"

@interface FilesInfoView ()  {
    UILabel *label;
}
@end

@implementation FilesInfoView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width - 20.0f, 0)];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.textColor = [UIColor grayColor];
        label.text = NSLocalizedString(@"Tap the + button to add a new KeePass file.", nil);
        [label sizeToFit];
        [self addSubview:label];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // Resize the label to the width of the screen in case we've rotated
    label.frame = CGRectMake(0, 0, self.bounds.size.width - 20.0f, 0);
    [label sizeToFit];

    // Center the label, in iOS 7 account for the layout guides
    if ([self.viewController respondsToSelector:@selector(topLayoutGuide)]) {
        CGFloat top = self.viewController.topLayoutGuide.length;
        CGFloat bottom = self.viewController.bottomLayoutGuide.length;
        label.center = CGPointMake(self.bounds.size.width / 2.0f, (self.bounds.size.height - top - bottom) / 2.0f + top);
    } else {
        label.center = CGPointMake(self.bounds.size.width / 2.0f, self.bounds.size.height / 2.0f);
    }
}

@end
