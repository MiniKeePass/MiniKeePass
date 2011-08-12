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

#import "ChoiceCell.h"

@implementation ChoiceCell

@synthesize prefix;
@synthesize choices;

- (id)initWithLabel:(NSString*)labelText choices:(NSArray*)newChoices selectedIndex:(NSInteger)selectedIdx {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (self) {
        // Initialization code
        self.prefix = labelText;
        self.choices = newChoices;
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        [self setSelectedIndex:selectedIdx];
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

- (NSInteger)selectedIndex {
    return selectedIndex;
}

- (void)setSelectedIndex:(NSInteger)selectedIdx {
    selectedIndex = selectedIdx;
    self.textLabel.text = [NSString stringWithFormat:@"%@: %@", prefix, [choices objectAtIndex:selectedIndex]];
}

- (NSString *)getSelectedItem {
    return [choices objectAtIndex:selectedIndex];
}

@end
