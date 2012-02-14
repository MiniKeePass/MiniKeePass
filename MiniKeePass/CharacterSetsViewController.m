/*
 * Copyright 2011 Jason Rush and John Flanagan. All rights reserved.
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

enum {
    ROW_UPPER_CASE,
    ROW_LOWER_CASE,
    ROW_DIGITS,
    ROW_MINUS,
    ROW_UNDERLINE,
    ROW_SPACE,
    ROW_SPECIAL,
    ROW_BRACKETS,
    ROW_NUMBER
};

@implementation CharacterSetsViewController

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Character Sets";

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        upperCaseSwitchCell = [[SwitchCell alloc] initWithLabel:@"Upper Case"];
        upperCaseSwitchCell.switchControl.on = [userDefaults boolForKey:@"pwGenUpperCase"];
        
        lowerCaseSwitchCell = [[SwitchCell alloc] initWithLabel:@"Lower Case"];
        lowerCaseSwitchCell.switchControl.on = [userDefaults boolForKey:@"pwGenLowerCase"];
        
        digitsSwitchCell = [[SwitchCell alloc] initWithLabel:@"Digits"];
        digitsSwitchCell.switchControl.on = [userDefaults boolForKey:@"pwGenDigits"];
        
        minusSwitchCell = [[SwitchCell alloc] initWithLabel:@"Minus"];
        minusSwitchCell.switchControl.on = [userDefaults boolForKey:@"pwGenMinus"];
        
        underlineSwitchCell = [[SwitchCell alloc] initWithLabel:@"Underline"];
        underlineSwitchCell.switchControl.on = [userDefaults boolForKey:@"pwGenUnderline"];
        
        spaceSwitchCell = [[SwitchCell alloc] initWithLabel:@"Space"];
        spaceSwitchCell.switchControl.on = [userDefaults boolForKey:@"pwGenSpace"];
        
        specialSwitchCell = [[SwitchCell alloc] initWithLabel:@"Special"];
        specialSwitchCell.switchControl.on = [userDefaults boolForKey:@"pwGenSpecial"];
        
        bracketsSwitchCell = [[SwitchCell alloc] initWithLabel:@"Brackets"];
        bracketsSwitchCell.switchControl.on = [userDefaults boolForKey:@"pwGenBrackets"];
    }
    return self;
}

- (void)dealloc {
    [upperCaseSwitchCell release];
    [lowerCaseSwitchCell release];
    [digitsSwitchCell release];
    [minusSwitchCell release];
    [underlineSwitchCell release];
    [spaceSwitchCell release];
    [specialSwitchCell release];
    [bracketsSwitchCell release];
    [super dealloc];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    [userDefaults setBool:upperCaseSwitchCell.switchControl.on forKey:@"pwGenUpperCase"];
    [userDefaults setBool:lowerCaseSwitchCell.switchControl.on forKey:@"pwGenLowerCase"];
    [userDefaults setBool:digitsSwitchCell.switchControl.on forKey:@"pwGenDigits"];
    [userDefaults setBool:minusSwitchCell.switchControl.on forKey:@"pwGenMinus"];
    [userDefaults setBool:underlineSwitchCell.switchControl.on forKey:@"pwGenUnderline"];
    [userDefaults setBool:spaceSwitchCell.switchControl.on forKey:@"pwGenSpace"];
    [userDefaults setBool:specialSwitchCell.switchControl.on forKey:@"pwGenSpecial"];
    [userDefaults setBool:bracketsSwitchCell.switchControl.on forKey:@"pwGenBrackets"];
}

- (NSString *)getDescription {
    NSMutableString *str = [[NSMutableString alloc] init];
    BOOL prefix = NO;
    
    if ([self isUpperCase]) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Upper"];
        prefix = YES;
    }
    
    if ([self isLowerCase]) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Lower"];
        prefix = YES;
    }
    
    if ([self isDigits]) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Digits"];
        prefix = YES;
    }
    
    if ([self isMinus]) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Minus"];
        prefix = YES;
    }
    
    if ([self isUnderline]) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Underline"];
        prefix = YES;
    }
    
    if ([self isSpace]) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Space"];
        prefix = YES;
    }
    
    if ([self isSpecial]) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Special"];
        prefix = YES;
    }
    
    if ([self isBrackets]) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Brackets"];
        prefix = YES;
    }
    
    if ([str length] == 0) {
        [str appendString:@"None Selected"];
    }
    
    return [str autorelease];
}

- (BOOL)isUpperCase {
    return upperCaseSwitchCell.switchControl.on;
}

- (BOOL)isLowerCase {
    return lowerCaseSwitchCell.switchControl.on;
}

- (BOOL)isDigits {
    return digitsSwitchCell.switchControl.on;
}

- (BOOL)isMinus {
    return minusSwitchCell.switchControl.on;
}

- (BOOL)isUnderline {
    return underlineSwitchCell.switchControl.on;
}

- (BOOL)isSpace {
    return spaceSwitchCell.switchControl.on;
}

- (BOOL)isSpecial {
    return specialSwitchCell.switchControl.on;
}

- (BOOL)isBrackets {
    return bracketsSwitchCell.switchControl.on;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ROW_NUMBER;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case ROW_UPPER_CASE:
            return upperCaseSwitchCell;
        case ROW_LOWER_CASE:
            return lowerCaseSwitchCell;
        case ROW_DIGITS:
            return digitsSwitchCell;
        case ROW_MINUS:
            return minusSwitchCell;
        case ROW_UNDERLINE:
            return underlineSwitchCell;
        case ROW_SPACE:
            return spaceSwitchCell;
        case ROW_SPECIAL:
            return specialSwitchCell;
        case ROW_BRACKETS:
            return bracketsSwitchCell;
        default:
            break;
    }
    
    return nil;
}

@end
