//
//  FolderCell.h
//  MiniKeePass
//
//  Created by John Flanagan on 2/1/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DirectoryCellDelegate;

@interface DirectoryCell : UITableViewCell {
    NSString *directoryName;
}

@property (nonatomic, copy) NSString *directoryName;
@property (nonatomic, retain) id<DirectoryCellDelegate> delegate;

@end

@protocol DirectoryCellDelegate <NSObject>
- (void)directoryCell:(DirectoryCell*)directoryCell wasChosenWithPath:(NSString*)path;
@end
