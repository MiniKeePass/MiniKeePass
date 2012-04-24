/*
 * Copyright 2011 Jason Rush and John Flanagan. All rights reserved.
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

@implementation FilesInfoView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        
        CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
        
        UIImage *image = [UIImage imageNamed:@"background"];
        
        CGFloat y;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            y = 240.0f;
        } else {
            y = 40.0f;
        }

        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake((screenWidth - image.size.width) / 2.0, y, image.size.width, image.size.height);
        [self addSubview:imageView];
        [imageView release];
        
        y += imageView.frame.size.height + 40;
        
        CGFloat labelWidth = 320.0f;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth - labelWidth) / 2.0, y, labelWidth, 40)];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.numberOfLines = 0;
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.textColor = [UIColor grayColor];
        label.text = NSLocalizedString(@"You do not have any KeePass files available for MiniKeePass to open.", nil);
        [self addSubview:label];
        [label release];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

@end
