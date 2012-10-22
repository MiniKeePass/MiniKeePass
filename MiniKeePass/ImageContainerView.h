//
//  ImageContainerView.h
//  MiniKeePass
//
//  Created by John Flanagan on 6/28/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageContainerView : UIView {
    NSMutableArray *imageViews;
    UIImageView *selectedImageView;
}

- (void)setSelectedImage:(NSUInteger)index;

@end
