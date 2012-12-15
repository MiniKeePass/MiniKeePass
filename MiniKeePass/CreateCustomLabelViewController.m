//
//  CreateCustomLabelViewController.m
//  MiniKeePass
//
//  Created by John on 12/15/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "CreateCustomLabelViewController.h"

@interface CreateCustomLabelViewController () {
    UIBarButtonItem *saveButton;
}

@property (nonatomic, readonly) UITextField *textField;
@end

@implementation CreateCustomLabelViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = NSLocalizedString(@"Custom Label", nil);
        self.tableView.allowsSelection = NO;

        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        [cancelButton release];

        saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
        saveButton.enabled = NO;
        self.navigationItem.rightBarButtonItem = saveButton;

        _textField = [[UITextField alloc] initWithFrame:CGRectZero];
        self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.textField.placeholder = NSLocalizedString(@"Custom Label", nil);
        self.textField.returnKeyType = UIReturnKeyDone;
        self.textField.delegate = self;
    }
    return self;
}

- (void)dealloc {
    [_textField release];
    [saveButton release];
    [super dealloc];
}

- (void)save {
    if (self.textField.text.length == 0) {
        return;
    }

    [self.delegate createCustomLabelViewController:self createdLabel:self.textField.text];
}

- (void)cancelPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.textField becomeFirstResponder];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    // Configure the cell...
    CGRect frame = CGRectInset(cell.contentView.bounds, 11, 0);
    self.textField.frame = frame;
    [cell.contentView addSubview:self.textField];

    return cell;
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self save];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSMutableString *testString = [NSMutableString stringWithString:textField.text];
    [testString replaceCharactersInRange:range withString:string];
    saveButton.enabled = testString.length > 0;
    return YES;
}

@end
