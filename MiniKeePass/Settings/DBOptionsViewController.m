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

#import <LocalAuthentication/LocalAuthentication.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MiniKeePassAppDelegate.h"
#import "DBOptionsViewController.h"
#import "SelectionListViewController.h"
#import "Kdb3Node.h"
#import "Kdb4Node.h"
#import "KdbPassword.h"
#import "UUID.h"

enum {
    SECTION_DATABASE_INFO,
    SECTION_ENCRPYTION,
    SECTION_KDF,
};

enum {
    ROW_DATABASE_INFO_NAME,
    ROW_DATABASE_INFO_NUMBER
};

enum {
    ROW_ENCRYPTION_TYPE,
    ROW_ENCRYPTION_NUMBER
};

enum {
    ROW_KDF_TYPE,
    ROW_KDF_ROUNDS_ITER,
    ROW_KDF_MEMORY,
    ROW_KDF_PARALLELISM,
    ROW_KDF_NUMBER
};

@interface DBOptionsViewController ()
@property (nonatomic, strong) Kdb4Tree *kdb4Tree;
@property (nonatomic, strong) Kdb3Tree *kdb3Tree;
@property (nonatomic, strong) DatabaseDocument *databaseDocument;

@end

@implementation DBOptionsViewController {
    NSArray *sections;
    NSArray *kdb3Encryptions;
    NSArray *kdb4Encryptions;
    NSArray *numberCells;
    
    BOOL            validateNumberFields;
    NSInteger       encryptionIndex;
    NSInteger       keyDerivIndex;
    uint64_t        initialSettings[6];
}

- (void)setDocument:(DatabaseDocument *)doc {
    
    self.databaseDocument = doc;
    if( [self.databaseDocument.kdbTree isKindOfClass:[Kdb4Tree class]] ) {
        self.kdb4Tree = (Kdb4Tree*) self.databaseDocument.kdbTree;
        self.kdb3Tree = nil;
    } else {
        self.kdb4Tree = nil;
        self.kdb3Tree = (Kdb3Tree*) self.databaseDocument.kdbTree;
    }
    
    kdb3Encryptions = @[@"AES", @"TwoFish" ];
    kdb4Encryptions = @[@"AES", @"ChaCha20" ];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    validateNumberFields = YES;
    NSString *databaseInfo;

    self.title = NSLocalizedString(@"Database Options", nil);

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
    self.navigationItem.rightBarButtonItem = doneButton;
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    aesRoundsCell = [self createNumberCell:@"Rounds"];
    argon2IterationsCell = [self createNumberCell:@"Iterations"];
    argon2MemoryCell = [self createNumberCell:@"Memory"];
    argon2ParallelismCell = [self createNumberCell:@"Parallelism"];
    
    numberCells = @[aesRoundsCell,argon2IterationsCell,argon2MemoryCell,argon2ParallelismCell];
    
    if( self.kdb3Tree != nil ) {
        databaseInfo = @"(Version 1.x) Database\n";
        if( self.kdb3Tree.flags & FLAG_RIJNDAEL ) {
            encryptionIndex = 0;
        } else {
            encryptionIndex = 1;
        }
        encryptionTypeCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Algorithm", nil)
                                                       choices:kdb3Encryptions
                                                 selectedIndex:encryptionIndex];
        keyDerivIndex = [self setupKeyDerivationValues:nil];
    } else {
        databaseInfo = [self.kdb4Tree.databaseName stringByAppendingString:@" (Version 2.x)\n"];
        databaseInfo = [databaseInfo stringByAppendingString:self.kdb4Tree.databaseDescription];
        if( [self.kdb4Tree.encryptionAlgorithm isEqual:[KdbUUID getAESUUID]]){
            encryptionIndex = 0;
        } else {
            encryptionIndex = 1;
        }
        encryptionTypeCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Algorithm", nil)
                                                       choices:kdb4Encryptions
                                                 selectedIndex:encryptionIndex];
        keyDerivIndex = [self setupKeyDerivationValues:self.kdb4Tree.kdfParams[KDF_KEY_UUID_BYTES]];
    }

    sections = @[
                 [NSNumber numberWithInt:SECTION_DATABASE_INFO],
                 [NSNumber numberWithInt:SECTION_ENCRPYTION],
                 [NSNumber numberWithInt:SECTION_KDF],
                ];

    keyDerivationTypeCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Function", nil)
                                                      choices:@[@"AES-KDF", @"Argon2"]
                                                selectedIndex:keyDerivIndex];
    if( self.kdb3Tree != nil ) {
        keyDerivationTypeCell.userInteractionEnabled = NO;
        [keyDerivationTypeCell setEnabled:NO];
    } else {
        [keyDerivationTypeCell setEnabled:YES];
    }
    [encryptionTypeCell setEnabled:YES];
    
    databaseInfoCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    databaseInfoCell.textLabel.text = databaseInfo;
    databaseInfoCell.backgroundColor = self.view.backgroundColor;
    databaseInfoCell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    databaseInfoCell.textLabel.textColor = UIColor.lightGrayColor;
    databaseInfoCell.textLabel.numberOfLines = 2;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [sections count];
}

- (NSInteger)mappedSection:(NSInteger)section {
    return [((NSNumber *)[sections objectAtIndex:section]) integerValue];
}

- (NSIndexPath *)mappedIndexPath:(NSIndexPath *)indexPAth {
    NSInteger section = [self mappedSection:indexPAth.section];
    return [NSIndexPath indexPathForRow:indexPAth.row inSection:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    section = [self mappedSection:section];
    switch (section) {
        case SECTION_DATABASE_INFO:
            return ROW_DATABASE_INFO_NUMBER;
            
        case SECTION_ENCRPYTION:
            return ROW_ENCRYPTION_NUMBER;
            
        case SECTION_KDF:
            if( keyDerivIndex == 1 ) {
                return 4;
            } else {
                return 2;
            }
    }
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    section = [self mappedSection:section];
    switch (section) {
        case SECTION_DATABASE_INFO:
            return NSLocalizedString(@"Database Information", nil);

        case SECTION_ENCRPYTION:
            return NSLocalizedString(@"Encryption Algorithm", nil);

        case SECTION_KDF:
            return NSLocalizedString(@"Key Derivation Function", nil);
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    section = [self mappedSection:section];
    switch (section) {
        case SECTION_DATABASE_INFO:
            return NSLocalizedString(@"", nil);
            
        case SECTION_ENCRPYTION:
            return NSLocalizedString(@"Algorithm used to encrypt the contents of the database.", nil);
            
        case SECTION_KDF:
            return NSLocalizedString(@"Method used to encrypt the master database password.  More iterations is more secure but requires longer to open the database.", nil);
    }
    return nil;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    indexPath = [self mappedIndexPath:indexPath];
    switch (indexPath.section) {
        case SECTION_DATABASE_INFO:
            switch (indexPath.row) {
                case ROW_DATABASE_INFO_NAME:
                    return databaseInfoCell;
            }
            break;
            
        case SECTION_ENCRPYTION:
            switch (indexPath.row) {
                case ROW_ENCRYPTION_TYPE:
                    return encryptionTypeCell;
            }
            break;
            
        case SECTION_KDF:
            switch (indexPath.row) {
                case ROW_KDF_TYPE:
                    return keyDerivationTypeCell;
                case ROW_KDF_ROUNDS_ITER:
                    if( keyDerivIndex == 0 ) {
                        return aesRoundsCell;
                    } else {
                        return argon2IterationsCell;
                    }
                case ROW_KDF_MEMORY:
                    return argon2MemoryCell;
                case ROW_KDF_PARALLELISM:
                    return argon2ParallelismCell;
            }
            break;
   }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    indexPath = [self mappedIndexPath:indexPath];
    if (indexPath.section == SECTION_ENCRPYTION && indexPath.row == ROW_ENCRYPTION_TYPE) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Encryption Type", nil);
        selectionListViewController.items = encryptionTypeCell.choices;
        selectionListViewController.selectedIndex = encryptionIndex;
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_KDF && indexPath.row == ROW_KDF_TYPE ) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Attempts", nil);
        selectionListViewController.items = keyDerivationTypeCell.choices;
        selectionListViewController.selectedIndex = keyDerivIndex;
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    }
}

- (void)selectionListViewController:(SelectionListViewController *)controller selectedIndex:(NSInteger)selectedIndex withReference:(id<NSObject>)reference {
    NSIndexPath *indexPath = (NSIndexPath *)reference;
    if (indexPath.section == SECTION_ENCRPYTION && indexPath.row == ROW_ENCRYPTION_TYPE) {
        // Save the user setting
        encryptionIndex = selectedIndex;
        
        // Update the cell text
        [encryptionTypeCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_KDF && indexPath.row == ROW_KDF_TYPE) {
        // Save the user setting
        keyDerivIndex = selectedIndex;
        
        // Update the cell text
        [keyDerivationTypeCell setSelectedIndex:selectedIndex];
        [self.tableView reloadData];
    }
    // Close the selection view.
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)donePressed {

    // If a number cell is being edited then validate the contents
    // before leaving the page.
    UITextField *cell;
    for( cell in numberCells ) {
        if( ![self textFieldShouldEndEditing:[cell viewWithTag:1]] ) {
                return;
        }
    }

    [self dismissViewControllerAnimated:YES completion:nil];
    
    uint64_t newSettings[6];
    
    newSettings[0] = encryptionIndex;
    newSettings[1] = keyDerivIndex;
    newSettings[2] = [self getUInt64TextFieldValue:aesRoundsCell];
    newSettings[3] = [self getUInt64TextFieldValue:argon2IterationsCell];
    newSettings[4] = [self getUInt64TextFieldValue:argon2MemoryCell];
    newSettings[5] = [self getUInt32TextFieldValue:argon2ParallelismCell];
    
    BOOL settingsChanged = false;
    for( int i=0; i<6; ++i ) {
        if( newSettings[i] != initialSettings[i] ) {
            settingsChanged = true;
            break;
        }
    }
    
    if( settingsChanged ) {
        // Copy the UI settings into the database tree
        [self changeDatabaseValues];
        // The settings were changed, we need to save the database
        [self.databaseDocument save];
    }
    
}

- (void)cancelPressed {

    validateNumberFields = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextField delegate

- (BOOL) textFieldShouldEndEditing:(UITextField *)textField {
    
    if( !validateNumberFields ) return YES;
    
    NSCharacterSet *numberSet = [NSCharacterSet decimalDigitCharacterSet];
    unichar stringChar;
    BOOL textOK = true;
    
    for(NSUInteger i=0; i<[textField.text length]; ++i ) {
        stringChar = [textField.text characterAtIndex:i];
        if( ![numberSet characterIsMember:stringChar] ) {
            // Found a character other than an integer.
            textOK = false;
        }
    }
    
    if( textOK ) return YES;
    
    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Entry Error"
                                                       message:@"Entry must be a whole number."
                                                      delegate:self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
    [theAlert show];

    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (UITableViewCell *) createNumberCell:(NSString *) label {
    
    UITableViewCell *tvCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];

    tvCell.textLabel.text = label;
    
    CGFloat fontHeight = [tvCell.textLabel.font lineHeight] + 4;

    CGFloat numWidth = 100.0;
    
//    CGRect numFrame = CGRectMake(numX, borderSize, numWidth, tvCell.contentView.frame.size.height - 2*borderSize );
    CGRect numFrame = CGRectMake( 0, 0, numWidth, fontHeight );

    UITextField *numberField = [[UITextField alloc] initWithFrame:numFrame];
//    numberField.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    numberField.translatesAutoresizingMaskIntoConstraints = NO;
    numberField.text = @"1234";
    numberField.textAlignment = NSTextAlignmentRight;
    numberField.borderStyle = UITextBorderStyleRoundedRect;
    numberField.tag = 1;
    numberField.delegate = self;
    numberField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    numberField.returnKeyType = UIReturnKeyDone;
    numberField.spellCheckingType = UITextSpellCheckingTypeNo;
    numberField.autocorrectionType = UITextAutocorrectionTypeNo;
    [tvCell.contentView addSubview:numberField];
    [numberField.rightAnchor constraintEqualToAnchor:tvCell.readableContentGuide.rightAnchor].active = YES;
    [numberField.topAnchor constraintEqualToAnchor:tvCell.readableContentGuide.topAnchor].active = YES;
    [numberField.widthAnchor constraintEqualToConstant:numWidth].active = YES;
    
    return tvCell;
}

- (int) setupKeyDerivationValues:(NSData *) bytes {
    int kdfIndex = 0;
    KdbUUID *uuid;
    
    if( bytes == nil ) {
        uuid = [KdbUUID getAES_KDFUUID];
    } else {
        uuid = [[KdbUUID alloc] initWithData:bytes];
    }
    
    // Setup the default values
    VariantDictionary *kdfDefParams = [KdbPassword getDefaultKDFParameters:[KdbUUID getAES_KDFUUID]];
    uint64_t rounds = [(NSNumber*)kdfDefParams[KDF_AES_KEY_ROUNDS] unsignedLongLongValue];
    [self setUInt64TextFieldValue:aesRoundsCell value:rounds];
    
    kdfDefParams = [KdbPassword getDefaultKDFParameters:[KdbUUID getArgon2UUID]];
    uint64_t iterations = [(NSNumber*)kdfDefParams[KDF_ARGON2_KEY_ITERATIONS] unsignedLongLongValue];
    [self setUInt64TextFieldValue:argon2IterationsCell value:iterations];

    uint64_t memory = [(NSNumber*)kdfDefParams[KDF_ARGON2_KEY_MEMORY] unsignedLongLongValue];
    [self setUInt64TextFieldValue:argon2MemoryCell value:memory/(1024*1024)];
    
    uint32_t parallelism = [(NSNumber*)kdfDefParams[KDF_ARGON2_KEY_PARALLELISM] unsignedIntValue];
    [self setUInt32TextFieldValue:argon2ParallelismCell value:parallelism];

    // Get the database current values
    if( self.kdb4Tree != nil ) {
        if( [uuid isEqual:[KdbUUID getAES_KDFUUID]] ) {
            // Map "Rounds" to the kdfParam NSNumber
            uint64_t rounds = [(NSNumber*)self.kdb4Tree.kdfParams[KDF_AES_KEY_ROUNDS] unsignedLongLongValue];
            [self setUInt64TextFieldValue:aesRoundsCell value:rounds];
            kdfIndex = 0;
        } else if( [uuid isEqual:[KdbUUID getArgon2UUID]] ) {
            // Map "Iterations", "Memory", and "Parallelism" to the kdfParam NSNumbers
            uint64_t iterations = [(NSNumber*)self.kdb4Tree.kdfParams[KDF_ARGON2_KEY_ITERATIONS] unsignedLongLongValue];
            [self setUInt64TextFieldValue:argon2IterationsCell value:iterations];
            
            uint64_t memory = [(NSNumber*)self.kdb4Tree.kdfParams[KDF_ARGON2_KEY_MEMORY] unsignedLongLongValue];
            [self setUInt64TextFieldValue:argon2MemoryCell value:memory/(1024*1024)];
            
            uint32_t parallelism = [(NSNumber*)self.kdb4Tree.kdfParams[KDF_ARGON2_KEY_PARALLELISM] unsignedIntValue];
            [self setUInt32TextFieldValue:argon2ParallelismCell value:parallelism];
            kdfIndex = 1;
        }
    } else {
        // KDB 1.x file.
        [self setUInt64TextFieldValue:aesRoundsCell value:self.kdb3Tree.rounds];
    }
    
    // Save the initial settings.
    initialSettings[0] = encryptionIndex;
    initialSettings[1] = kdfIndex;
    initialSettings[2] = [self getUInt64TextFieldValue:aesRoundsCell];
    initialSettings[3] = [self getUInt64TextFieldValue:argon2IterationsCell];
    initialSettings[4] = [self getUInt64TextFieldValue:argon2MemoryCell];
    initialSettings[5] = [self getUInt32TextFieldValue:argon2ParallelismCell];
    
    return kdfIndex;
}

- (void) changeDatabaseValues {
    if( self.kdb3Tree != nil ) {
        if( encryptionIndex == 0 ) {
            self.kdb3Tree.flags = FLAG_RIJNDAEL;
        } else if( encryptionIndex == 1 ) {
            self.kdb3Tree.flags = FLAG_TWOFISH;
        }
        self.kdb3Tree.rounds = (uint32_t)[self getUInt64TextFieldValue:aesRoundsCell];
    } else {
        if( encryptionIndex == 0 ) {
            self.kdb4Tree.encryptionAlgorithm = [KdbUUID getAESUUID];
        } else if( encryptionIndex == 1 ) {
            self.kdb4Tree.encryptionAlgorithm = [KdbUUID getChaCha20UUID];
        }
        
        if( keyDerivIndex == 0 ) {
            // Map "Rounds" to the kdfParam NSNumber
            [self.kdb4Tree.kdfParams addByteArray:[[KdbUUID getAES_KDFUUID] getData] forKey:KDF_KEY_UUID_BYTES];
            uint64_t rounds = [self getUInt64TextFieldValue:aesRoundsCell];
            [self.kdb4Tree.kdfParams addUInt64:rounds forKey:KDF_AES_KEY_ROUNDS];
        } else if( keyDerivIndex == 1 ) {
            // Map "Iterations", "Memory", and "Parallelism" to the kdfParam NSNumbers
            [self.kdb4Tree.kdfParams addByteArray:[[KdbUUID getArgon2UUID] getData] forKey:KDF_KEY_UUID_BYTES];
            uint64_t iterations = [self getUInt64TextFieldValue:argon2IterationsCell];
            [self.kdb4Tree.kdfParams addUInt64:iterations forKey:KDF_ARGON2_KEY_ITERATIONS];
            uint64_t memory = [self getUInt64TextFieldValue:argon2MemoryCell];
            [self.kdb4Tree.kdfParams addUInt64:memory*1024*1024 forKey:KDF_ARGON2_KEY_MEMORY];
            uint32_t parallelism = [self getUInt32TextFieldValue:argon2ParallelismCell];
            [self.kdb4Tree.kdfParams addUInt32:parallelism forKey:KDF_ARGON2_KEY_PARALLELISM];
        }
    }
}

- (void) setUInt64TextFieldValue:(UITableViewCell *) cell value:(uint64_t)value {
    UITextField *tf = [cell viewWithTag:1];
    tf.text = [NSString stringWithFormat:@"%llu", value];
}

- (uint64_t) getUInt64TextFieldValue:(UITableViewCell *) cell {
    UITextField *tf = [cell viewWithTag:1];
    uint64_t value = [tf.text longLongValue];
    
    return value;
}

- (void) setUInt32TextFieldValue:(UITableViewCell *) cell value:(uint32_t)value {
    UITextField *tf = [cell viewWithTag:1];
    tf.text = [NSString stringWithFormat:@"%u", value];
}

- (uint32_t) getUInt32TextFieldValue:(UITableViewCell *) cell {
    UITextField *tf = [cell viewWithTag:1];
    uint32_t value = [tf.text intValue];
    
    return value;
}

@end
