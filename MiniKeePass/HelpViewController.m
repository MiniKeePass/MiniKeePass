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

#import "HelpViewController.h"

@implementation HelpViewController

typedef struct {
    NSString *title;
    NSString *resource;
} help_topic_t;

help_topic_t help_topics[] = {
    {@"iTunes Import/Export", @"itunes"},
    {@"Dropbox Import/Export", @"dropbox"},
    {@"Safari/Email Import", @"safariemail"},
    {@"Create New Database", @"createdb"},
    {@"Key Files", @"keyfiles"}
};

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"Help", nil);
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sizeof(help_topics) / sizeof(help_topic_t);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Configure the cell
    cell.textLabel.text = NSLocalizedString(help_topics[indexPath.row].title, nil);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Get the title and resource of the selected help page
    NSString *title = help_topics[indexPath.row].title;
    NSString *resource = help_topics[indexPath.row].resource;
    
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *localizedResource = [NSString stringWithFormat:@"%@-%@", language, resource];

    NSString *path = [[NSBundle mainBundle] pathForResource:localizedResource ofType:@"html"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        path = [[NSBundle mainBundle] pathForResource:resource ofType:@"html"];
    }
    
    // Get the URL of the respurce
    NSURL *url = [NSURL fileURLWithPath:path];
    
    // Create a web view to display the help page
    UIWebView *webView = [[UIWebView alloc] init];
    webView.backgroundColor = [UIColor whiteColor];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.title = NSLocalizedString(title, nil);
    viewController.view = webView;
    [webView release];
    
    [self.navigationController pushViewController:viewController animated:YES];
    
    [viewController release];
}

@end
