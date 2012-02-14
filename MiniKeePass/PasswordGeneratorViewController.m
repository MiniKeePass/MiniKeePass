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

#import "PasswordGeneratorViewController.h"
#import "NumberSelectionViewController.h"
#import "Salsa20RandomStream.h"

#define CHARSET_LOWER_CASE @"abcdefghijklmnopqrstuvwxyz"
#define CHARSET_UPPER_CASE @"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define CHARSET_DIGITS     @"0123456789"
#define CHARSET_MINUS      @"-"
#define CHARSET_UNDERLINE  @"_"
#define CHARSET_SPACE      @" "
#define CHARSET_SPECIAL    @"!@#$%^&*_-+=?"
#define CHARSET_BRACKETS   @"(){}[]<>"

enum {
    SECTION_SETTINGS,
    SECTION_PASSWORD,
    SECTION_NUMBER
};

enum {
    ROW_SETTINGS_LENGTH,
    ROW_SETTINGS_CHARSET,
    ROW_SETTINGS_NUMBER
};

enum {
    ROW_PASSWORD_VALUE,
    ROW_PASSWORD_NUMBER
};

@implementation PasswordGeneratorViewController

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Generator";
        self.tableView.delaysContentTouches = YES;

        lengthCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        lengthCell.textLabel.text = @"Length";
        lengthCell.detailTextLabel.text = @"10"; // FIXME
        lengthCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        characterSetsViewController = [[CharacterSetsViewController alloc] init];

        characterSetsCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        characterSetsCell.textLabel.text = @"Character Sets";
        characterSetsCell.detailTextLabel.text = @" ";
        characterSetsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        UIImage *image = [UIImage imageNamed:@"gear"];
        
        UIButton *regenerateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        regenerateButton.frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
        [regenerateButton setImage:image forState:UIControlStateNormal];
        [regenerateButton addTarget:self action:@selector(generatePassword) forControlEvents:UIControlEventTouchUpInside];
        
        passwordCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        passwordCell.textLabel.text = @" "; // FIXME Why do I have to pass a space in?
        passwordCell.accessoryView = regenerateButton;
    }
    return self;
}

- (void)dealloc {
    [lengthCell release];
    [characterSetsViewController release];
    [characterSetsCell release];
    [passwordCell release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    characterSetsCell.detailTextLabel.text = [characterSetsViewController getDescription];
}

- (NSString *)getPassword {
    return passwordCell.textLabel.text;
}

- (void)generatePassword {
    NSMutableString *charSet = [NSMutableString string];
    
    if ([characterSetsViewController isUpperCase]) {
        [charSet appendString:CHARSET_UPPER_CASE];
    }
    if ([characterSetsViewController isLowerCase]) {
        [charSet appendString:CHARSET_LOWER_CASE];
    }
    if ([characterSetsViewController isDigits]) {
        [charSet appendString:CHARSET_DIGITS];
    }
    if ([characterSetsViewController isMinus]) {
        [charSet appendString:CHARSET_MINUS];
    }
    if ([characterSetsViewController isUnderline]) {
        [charSet appendString:CHARSET_UNDERLINE];
    }
    if ([characterSetsViewController isSpace]) {
        [charSet appendString:CHARSET_SPACE];
    }
    if ([characterSetsViewController isSpecial]) {
        [charSet appendString:CHARSET_SPECIAL];
    }
    
    RandomStream *cryptoRandomStream = [[Salsa20RandomStream alloc] init];
    
    NSInteger length = [lengthCell.detailTextLabel.text integerValue];
    
    NSMutableString *password = [NSMutableString string];
    for (NSUInteger i = 0; i < length; i++) {
        NSUInteger idx = [cryptoRandomStream getInt] % [charSet length];
	        [password appendString:[charSet substringWithRange:NSMakeRange(idx, 1)]];
    }
    
    [cryptoRandomStream release];
    
    passwordCell.textLabel.text = password;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_NUMBER;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SECTION_SETTINGS:
            return ROW_SETTINGS_NUMBER;
            
        case SECTION_PASSWORD:
            return ROW_PASSWORD_NUMBER;
    }
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_SETTINGS:
            return NSLocalizedString(@"Settings", nil);
            
        case SECTION_PASSWORD:
            return NSLocalizedString(@"Password", nil);
    }
    return nil;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case SECTION_SETTINGS:
            switch (indexPath.row) {
                case ROW_SETTINGS_LENGTH:
                    return lengthCell;
                case ROW_SETTINGS_CHARSET:
                    return characterSetsCell;
            }
            break;
            
        case SECTION_PASSWORD:
            switch (indexPath.row) {
                case ROW_PASSWORD_VALUE:
                    return passwordCell;
            }
            break;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_SETTINGS && indexPath.row == ROW_SETTINGS_LENGTH) {
        NumberSelectionViewController *numberSelectionViewController = [[NumberSelectionViewController alloc] initWithMinValue:1 maxValue:25];
        numberSelectionViewController.title = NSLocalizedString(@"Length", nil);
        numberSelectionViewController.selectedValue = 1; // FIXME
        [self.navigationController pushViewController:numberSelectionViewController animated:YES];
        [numberSelectionViewController release];
    } else if (indexPath.section == SECTION_SETTINGS && indexPath.row == ROW_SETTINGS_CHARSET) {
        [self.navigationController pushViewController:characterSetsViewController animated:YES];
    }
}

@end
