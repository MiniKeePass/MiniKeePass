//
//  MKPDocument.h
//  MiniKeePass
//
//  Created by John on 12/18/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MKPDocumentType) {
    MKPLocalDocument,
    MKPDropBoxDocument
};

@interface MKPDocument : NSObject

@property (nonatomic, copy) NSString *filename;
@property (nonatomic, retain) UIImage *customImage;
@property (nonatomic, assign) MKPDocumentType type;

@end
