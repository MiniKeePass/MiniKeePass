//
//  ImagesViewController.h
//  MiniKeePass
//
//  Created by Jason Rush on 6/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ImagesViewControllerDelegate;

@interface ImagesViewController : UIViewController {
    UIView *imagesView;
    NSMutableArray *imageViews;
    UIImageView *selectedImageView;
    id<ImagesViewControllerDelegate> delegate;
}

@property (nonatomic, retain) id<ImagesViewControllerDelegate> delegate;

- (void)setSelectedImage:(NSUInteger)index;

@end

@protocol ImagesViewControllerDelegate <NSObject>
- (void)imagesViewController:(ImagesViewController*)controller imageSelected:(NSUInteger)index;
@end
