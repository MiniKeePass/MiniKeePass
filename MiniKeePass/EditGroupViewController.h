//
//  EditGroupViewController.h
//  MiniKeePass
//
//  Created by Jason Rush on 6/23/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FormViewController.h"
#import "ImagesViewController.h"

@interface EditGroupViewController : FormViewController <ImagesViewControllerDelegate> {
    UITextField *nameTextField;
    UIButton *imageButton;
    NSUInteger selectedImageIndex;
}

@property (nonatomic, readonly) UITextField *nameTextField;
@property (nonatomic, readonly) UIButton *imageButton;
@property (nonatomic, assign) NSUInteger selectedImageIndex;

@end
