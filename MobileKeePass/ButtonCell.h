//
//  ButtonCell.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/14/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ButtonCell : UITableViewCell {
    
}

- (id)initWithLabel:(NSString*)labelText;
- (void)setEnabled:(BOOL)enabled;

@end
