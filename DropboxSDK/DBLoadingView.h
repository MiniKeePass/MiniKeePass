//
//  DBLoadingView.h
//  DropboxSDK
//
//  Created by Brian Smith on 6/30/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DBLoadingView : UIView {
    UIInterfaceOrientation orientation;
    UILabel* titleLabel;
    UIActivityIndicatorView* activityIndicator;
    UIImageView* imageView;
}

- (id)initWithTitle:(NSString*)title;

- (void)setImage:(UIImage*)image;
- (void)setOrientation:(UIInterfaceOrientation)orientation;

- (void)show;
- (void)dismissAnimated:(BOOL)animated;

//@property (nonatomic, retain) NSString* title;

@end
