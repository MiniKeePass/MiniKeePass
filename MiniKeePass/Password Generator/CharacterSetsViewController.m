/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "CharacterSetsViewController.h"
#import "AppSettings.h"

#define NUMBER_CHARACTER_SETS    8

@implementation CharacterSetsViewController

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"Character Sets", nil);

        NSInteger charSets = [[AppSettings sharedInstance] pwGenCharSets];
        
        upperCaseSwitchCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Upper Case", nil)];
        upperCaseSwitchCell.switchControl.on = charSets & CHARACTER_SET_UPPER_CASE;
        
        lowerCaseSwitchCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Lower Case", nil)];
        lowerCaseSwitchCell.switchControl.on = charSets & CHARACTER_SET_LOWER_CASE;
        
        digitsSwitchCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Digits", nil)];
        digitsSwitchCell.switchControl.on = charSets & CHARACTER_SET_DIGITS;
        
        minusSwitchCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Minus", nil)];
        minusSwitchCell.switchControl.on = charSets & CHARACTER_SET_MINUS;
        
        underlineSwitchCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Underline", nil)];
        underlineSwitchCell.switchControl.on = charSets & CHARACTER_SET_UNDERLINE;
        
        spaceSwitchCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Space", nil)];
        spaceSwitchCell.switchControl.on = charSets & CHARACTER_SET_SPACE;
        
        specialSwitchCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Special", nil)];
        specialSwitchCell.switchControl.on = charSets & CHARACTER_SET_SPECIAL;
        
        bracketsSwitchCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Brackets", nil)];
        bracketsSwitchCell.switchControl.on = charSets & CHARACTER_SET_BRACKETS;
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated {
    NSInteger charSets = 0;
    if (upperCaseSwitchCell.switchControl.on) {
        charSets |= CHARACTER_SET_UPPER_CASE;
    }
    if (lowerCaseSwitchCell.switchControl.on) {
        charSets |= CHARACTER_SET_LOWER_CASE;
    }
    if (digitsSwitchCell.switchControl.on) {
        charSets |= CHARACTER_SET_DIGITS;
    }
    if (minusSwitchCell.switchControl.on) {
        charSets |= CHARACTER_SET_MINUS;
    }
    if (underlineSwitchCell.switchControl.on) {
        charSets |= CHARACTER_SET_UNDERLINE;
    }
    if (spaceSwitchCell.switchControl.on) {
        charSets |= CHARACTER_SET_SPACE;
    }
    if (specialSwitchCell.switchControl.on) {
        charSets |= CHARACTER_SET_SPECIAL;
    }
    if (bracketsSwitchCell.switchControl.on) {
        charSets |= CHARACTER_SET_BRACKETS;
    }
    
    [[AppSettings sharedInstance] setPwGenCharSets:charSets];
    
    [super viewWillDisappear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return NUMBER_CHARACTER_SETS;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (1 << indexPath.row) {
        case CHARACTER_SET_UPPER_CASE:
            return upperCaseSwitchCell;
        case CHARACTER_SET_LOWER_CASE:
            return lowerCaseSwitchCell;
        case CHARACTER_SET_DIGITS:
            return digitsSwitchCell;
        case CHARACTER_SET_MINUS:
            return minusSwitchCell;
        case CHARACTER_SET_UNDERLINE:
            return underlineSwitchCell;
        case CHARACTER_SET_SPACE:
            return spaceSwitchCell;
        case CHARACTER_SET_SPECIAL:
            return specialSwitchCell;
        case CHARACTER_SET_BRACKETS:
            return bracketsSwitchCell;
        default:
            break;
    }
    
    return nil;
}

@end
