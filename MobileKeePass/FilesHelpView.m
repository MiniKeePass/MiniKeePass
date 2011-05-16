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

#import "FilesHelpView.h"

@implementation FilesHelpView

@synthesize navigationController;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        
        UIImage *image = [UIImage imageNamed:@"background.png"];
        
        CGFloat y = 16;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake(160 - image.size.width / 2.0, y, image.size.width, image.size.height);
        [self addSubview:imageView];
        [imageView release];
        
        y += imageView.frame.size.height + 16;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 320, 40)];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.numberOfLines = 0;
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.text = @"You do not have any KeePass files available for MobileKeePass to open.";
        [self addSubview:label];
        [label release];
        
        y += label.frame.size.height + 16;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, y, 320, 20);
        [button setTitle:@"Sync with iTunes" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(iTunesPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        
        y += button.frame.size.height + 16;
        
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, y, 320, 20);
        [button setTitle:@"Sync with Dropbox" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(dropboxPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
    }
    return self;
}

- (void)dealloc {
    [navigationController release];
    [super dealloc];
}

- (void)pushWebView:(NSString*)resource {
    UIWebView *webView = [[UIWebView alloc] init];
	webView.backgroundColor = [UIColor whiteColor];
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:resource ofType:@"html"]];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.view = webView;
    [webView release];
    
    [self.navigationController pushViewController:viewController animated:YES];
    
    [viewController release];
}

- (void)iTunesPressed:(id)sender {
    [self pushWebView:@"itunes"];
}

- (void)dropboxPressed:(id)sender {
    [self pushWebView:@"dropbox"];
}

@end
