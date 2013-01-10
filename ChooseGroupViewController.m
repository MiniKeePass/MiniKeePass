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

#import "ChooseGroupViewController.h"
#import "MiniKeePassAppDelegate.h"

#define INDENT_LEVEL 3
#define KEY_VALID    @"valid"
#define KEY_GROUP    @"group"
#define KEY_LEVEL    @"level"
#define KEY_NAME     @"name"

@interface ChooseGroupViewController () {
    NSMutableArray *allGroups;
    MiniKeePassAppDelegate *appDelegate;
}

- (void)addGroups:(NSArray *)groups toArray:(NSMutableArray *)array atLevel:(NSInteger)level;

@end

@implementation ChooseGroupViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.title = NSLocalizedString(@"Choose Group", nil);
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalViewControllerAnimated:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        [cancelButton release];

        appDelegate = (MiniKeePassAppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (void)dealloc {
    [allGroups release];
    [super dealloc];
}

- (void)viewDidLoad {
    // Get parameters for the root
    KdbGroup *rootGroup = appDelegate.databaseDocument.kdbTree.root;
    NSString *filename = [appDelegate.databaseDocument.filename lastPathComponent];
    BOOL valid = [self.delegate checkChoiceValidity:rootGroup];

    // Add root group
    allGroups = [[NSMutableArray alloc] init];
    [allGroups addObject:@{KEY_GROUP : rootGroup, KEY_LEVEL : [NSNumber numberWithUnsignedInteger:0], KEY_NAME : filename, KEY_VALID : [NSNumber numberWithBool:valid]}];

    // Recursivly add subgroups
    [self addGroups:rootGroup.groups toArray:allGroups atLevel:INDENT_LEVEL];
}

- (void)addGroups:(NSArray *)groups toArray:(NSMutableArray *)array atLevel:(NSInteger)level {
    // Sort all the sub-groups
    NSArray *sortedGroups = [groups sortedArrayUsingComparator:^NSComparisonResult(KdbGroup *group1, KdbGroup *group2) {
        return [group1.name localizedCaseInsensitiveCompare:group2.name];
    }];

    // Add sub-groups
    for (KdbGroup *group in sortedGroups) {
        // Add this group
        BOOL valid = [self.delegate checkChoiceValidity:group];
        [array addObject:@{KEY_GROUP : group, KEY_LEVEL : [NSNumber numberWithUnsignedInteger:level], KEY_VALID : [NSNumber numberWithBool:valid]}];

        // Add its subgroups
        [self addGroups:group.groups toArray:array atLevel:level + INDENT_LEVEL];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [allGroups count];
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = [allGroups objectAtIndex:indexPath.row];
    return [[dict objectForKey:KEY_LEVEL] integerValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    NSDictionary *dict = [allGroups objectAtIndex:indexPath.row];
    KdbGroup *group = [dict objectForKey:KEY_GROUP];
    
    NSString *name = [dict objectForKey:KEY_NAME];
    cell.textLabel.text = name ? name : group.name;
    cell.imageView.image = [appDelegate loadImage:group.image];
    
    BOOL valid = [[dict objectForKey:KEY_VALID] boolValue];
    if (valid) {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    } else {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *groupDict = [allGroups objectAtIndex:indexPath.row];

    BOOL valid = [[groupDict objectForKey:KEY_VALID] boolValue];
    if (valid) {
        KdbGroup *chosenGroup = [groupDict objectForKey:KEY_GROUP];
        [self.delegate chooseGroup:chosenGroup];
        [self dismissModalViewControllerAnimated:YES];
    }
}

@end
