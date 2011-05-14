//
//  ChoiceCell.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/14/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "ChoiceCell.h"

@implementation ChoiceCell

@synthesize prefix;
@synthesize choices;

- (id)initWithLabel:(NSString*)labelText choices:(NSArray*)newChoices selectedIndex:(NSInteger)selectedIndex {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (self) {
        // Initialization code
        self.prefix = labelText;
        self.choices = newChoices;
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        [self setSelectedIndex:selectedIndex];
    }
    return self;
}

- (void)dealloc {
    [prefix release];
    [choices release];
    [super dealloc];
}

- (void)setEnabled:(BOOL)enabled {
    self.selectionStyle = enabled ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
    self.textLabel.enabled = enabled;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    self.textLabel.text = [NSString stringWithFormat:@"%@: %@", prefix, [choices objectAtIndex:selectedIndex]];
}

@end
