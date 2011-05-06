//
//  TextViewCell.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EntryViewController;

@interface TextViewCell : UITableViewCell <UITextViewDelegate> {
    EntryViewController *entryViewController;
	UITextView *textView;
}

@property (nonatomic, retain) UITextView *textView;

- (id)initWithParent:(EntryViewController*)parent;

@end
