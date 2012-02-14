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

#import "NumberSelectionViewController.h"

@implementation NumberSelectionViewController

@synthesize selectedValue;

- (id)initWithMinValue:(NSInteger)minimumValue maxValue:(NSInteger)maximumValue {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        minValue = minimumValue;
        maxValue = maximumValue;
        selectedValue = minValue;
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return maxValue - minValue + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSInteger value = minValue + indexPath.row;
    
    // Configure the cell
    cell.textLabel.text = [[NSNumber numberWithInteger:value] stringValue];
    if (value == selectedValue) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    NSInteger value = minValue + indexPath.row;
    if (value != selectedValue) {
        // Remove the checkmark from the current selection
        cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedValue - minValue inSection:0]];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor blackColor];
        
        // Add the checkmark to the new selection
        cell = [tableView cellForRowAtIndexPath: indexPath]; 
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = [UIColor colorWithRed:0.243 green:0.306 blue:0.435 alpha:1];
        
        selectedValue = value;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
