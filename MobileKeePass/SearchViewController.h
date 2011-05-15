//
//  SearchViewController.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/15/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchViewController : UIViewController
<UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate> {
	UITableView *tableView;
	UISearchBar *searchBar;
	UIView *disableViewOverlay;
    
	NSMutableArray *results;
}

- (void)clearResults;
- (void)setSearchBar:(UISearchBar*)control active:(BOOL)active;

@end
