//
//  DBLoadingView.m
//  DropboxSDK
//
//  Created by Brian Smith on 6/30/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "DBLoadingView.h"


#define kPadding 10


@interface DBLoadingView ()

- (CGRect)beveledBoxFrame;

@end


@implementation DBLoadingView

- (id)init {
    return [self initWithTitle:nil];
}

- (id)initWithTitle:(NSString*)theTitle {
    CGRect frame = [[UIApplication sharedApplication] keyWindow].frame;
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        activityIndicator = 
            [[UIActivityIndicatorView alloc] 
             initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:activityIndicator];
        
        imageView = [[UIImageView alloc] init];
        [self addSubview:imageView];

        titleLabel = [UILabel new];
        titleLabel.text = theTitle;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = UITextAlignmentCenter;
        [self addSubview:titleLabel];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGRect contentFrame = [self beveledBoxFrame];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat fillColor[] = { 0, 0, 0, 128.0/255 };
    CGContextSetFillColor(context, fillColor);
    CGFloat radius = 6;
    CGContextMoveToPoint(context, contentFrame.origin.x + radius, contentFrame.origin.y);
    CGContextAddArcToPoint(context, 
            CGRectGetMaxX(contentFrame), contentFrame.origin.y, 
            CGRectGetMaxX(contentFrame), CGRectGetMaxY(contentFrame), radius);
    CGContextAddArcToPoint(context, 
            CGRectGetMaxX(contentFrame), CGRectGetMaxY(contentFrame), 
            contentFrame.origin.x, CGRectGetMaxY(contentFrame), radius);
    CGContextAddArcToPoint(context, 
            contentFrame.origin.x, CGRectGetMaxY(contentFrame), 
            contentFrame.origin.x, contentFrame.origin.y, radius);
    CGContextAddArcToPoint(context, 
            contentFrame.origin.x, contentFrame.origin.y, 
            CGRectGetMaxX(contentFrame), contentFrame.origin.y, radius);
    CGContextClosePath(context);
    CGContextFillPath(context);
}

- (void)layoutSubviews {
    CGRect contentFrame = [self beveledBoxFrame];
    
    activityIndicator.center = CGPointMake(
        floor(contentFrame.origin.x + contentFrame.size.width/2), 
        floor(contentFrame.origin.y + contentFrame.size.height/2) - kPadding);

    CGFloat titleLeading = titleLabel.font.leading;
    CGRect titleFrame = CGRectMake(
            contentFrame.origin.x + kPadding, 
            CGRectGetMaxY(contentFrame) - 2*kPadding - titleLeading, 
            contentFrame.size.width - 2*kPadding, titleLeading);
    titleLabel.frame = titleFrame;

    CGRect imageFrame = imageView.frame;
    imageFrame.origin.x = contentFrame.origin.x + floor(contentFrame.size.width/2 - imageFrame.size.width/2);
    imageFrame.origin.y = contentFrame.origin.y + floor(contentFrame.size.height/2 - imageFrame.size.height/2);
    imageView.frame = imageFrame;
}

- (void)dealloc {
    [activityIndicator release];
    [imageView release];
    [titleLabel release];
    [super dealloc];
}

- (void)setImage:(UIImage*)image {
    imageView.image = image;
    [imageView sizeToFit];
    
    [self setNeedsLayout];
}

- (void)setOrientation:(UIInterfaceOrientation)newOrientation {
    if (newOrientation == orientation) return;
    orientation = newOrientation;
    
    if (orientation == UIInterfaceOrientationPortrait) {
        self.transform = CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        self.transform = CGAffineTransformMakeRotation(M_PI);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        self.transform = CGAffineTransformMakeRotation(M_PI/2);
    } else {
        self.transform = CGAffineTransformMakeRotation(-M_PI/2);
    }
}

- (void)show {
    if (!imageView.image) {
        // Only show activity indicator when we don't have an image
        [activityIndicator startAnimating];
    }
    UIWindow* window = [[UIApplication sharedApplication] keyWindow];
    self.frame = window.frame;
    [window addSubview:self];
}

- (void)finishDismiss {
    [activityIndicator stopAnimating];
    [self removeFromSuperview];
}

- (void)dismissAnimated:(BOOL)animated {
    if (!animated) {
        [self finishDismiss];
    } else {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.8];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(finishDismiss)];

        self.alpha = 0;

        [UIView commitAnimations];
    }
}

- (CGRect)beveledBoxFrame {
    CGSize contentSize = self.bounds.size;
    CGSize boxSize = CGSizeMake(160, 160);
    CGFloat yOffset = UIInterfaceOrientationIsPortrait(orientation) ? 18 : 0;
    return CGRectMake(
        floor(contentSize.width/2 - boxSize.width/2),
        floor(contentSize.height/2 - boxSize.height/2) + yOffset,
        boxSize.width, boxSize.height);
}

@end
