//
//  TextViewCell.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextViewCell : UITableViewCell <UITextViewDelegate> {
    UITableView *parentTableView;
	UITextView *textView;
}

@property (nonatomic, retain) UITextView *textView;

- (id)initWithParent:(UITableView*)parent;

@end
