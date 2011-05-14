//
//  ChoiceCell.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/14/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectionListViewController.h"

@interface ChoiceCell : UITableViewCell {
    NSString *prefix;
    NSArray *choices;
}

@property (nonatomic, copy) NSString *prefix;
@property (nonatomic, retain) NSArray *choices;

- (id)initWithLabel:(NSString*)labelText choices:(NSArray*)newChoices selectedIndex:(NSInteger)selectedIndex;
- (void)setEnabled:(BOOL)enabled;
- (void)setSelectedIndex:(NSInteger)selectedIndex;

@end
