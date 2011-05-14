//
//  ButtonCell.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/14/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "ButtonCell.h"

@implementation ButtonCell

- (id)initWithLabel:(NSString*)labelText {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (self) {
        // Initialization code
        self.textLabel.text = labelText;
        self.textLabel.textAlignment = UITextAlignmentCenter;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
    [super dealloc];
}

- (void)setEnabled:(BOOL)enabled {
    self.selectionStyle = enabled ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
    self.textLabel.enabled = enabled;
}

@end
