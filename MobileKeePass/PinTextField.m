//
//  PinTextField.m
//  MobileKeePass
//
//  Created by John on 5/3/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "PinTextField.h"

@implementation PinTextField

@synthesize label;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.image = [UIImage imageNamed:@"box"];
        
        CGFloat w = frame.size.width;
        CGFloat h = frame.size.height - 4;
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w, h)];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:32.0f];
        [self addSubview:label];
    }
    return self;
}

- (void)dealloc {
    [label release];
    [super dealloc];
}

@end
