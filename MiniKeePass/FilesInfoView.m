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
        
        UIImage *image = [UIImage imageNamed:@"background"];
        
        CGFloat y = 40;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake(160 - image.size.width / 2.0, y, image.size.width, image.size.height);
        [self addSubview:imageView];
        [imageView release];
        
        y += imageView.frame.size.height + 40;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 320, 40)];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.numberOfLines = 0;
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.textColor = [UIColor grayColor];
        label.text = @"You do not have any KeePass files available for MiniKeePass to open.";
        [self addSubview:label];
        [label release];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

@end
