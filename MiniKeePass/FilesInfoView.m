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
    UIView *containerView;
    CGFloat containerWidth;
    CGFloat containerHeight;
}
@end

@implementation FilesInfoView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        
        CGFloat viewWidth = CGRectGetWidth(self.frame);
        UIImage *image = [UIImage imageNamed:@"background"];
        
        CGFloat imageWidth = image.size.width;
        CGFloat imageHeight = image.size.height;        

        CGFloat spacerHeight = 40.0f;

        CGFloat labelWidth = 320.0f;
        CGFloat labelHeight = 40.0f;
        
        containerWidth = labelWidth;
        containerHeight = imageHeight + labelHeight + spacerHeight;

        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake((containerWidth - image.size.width) / 2.0f, 0, imageWidth, imageHeight);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, imageHeight + spacerHeight, labelWidth, labelHeight)];
        label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.numberOfLines = 0;
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.textColor = [UIColor grayColor];
        label.text = NSLocalizedString(@"You do not have any KeePass files available for MiniKeePass to open.", nil);
        
        CGFloat y = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 240.0f : 40.0f;
        containerView = [[UIView alloc] initWithFrame:CGRectMake((viewWidth - containerWidth) / 2.0f, y, containerWidth, containerHeight)];
        containerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [containerView addSubview:imageView];
        [containerView addSubview:label];
        
        [self addSubview:containerView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // Nothing to be done for iPad; return
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) return;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect newFrame = containerView.frame;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        newFrame.origin.y = 5.0f;
        newFrame.size.height = 225.0f;
    } else {
        newFrame.origin.y = 40.0f;
        newFrame.size.height = containerHeight;
    }
    containerView.frame = newFrame;
}

@end
