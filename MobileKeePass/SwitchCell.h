//
//  SwitchCell.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/14/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SwitchCell : UITableViewCell {
    UISwitch *switchControl;
}

@property (nonatomic, retain) UISwitch *switchControl;

- (id)initWithLabel:(NSString*)labelText;
- (void)setEnabled:(BOOL)enabled;

@end
