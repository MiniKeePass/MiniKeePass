//
//  WrapperNSData.h
//  KeePass2
//
//  Created by Qiang Yu on 1/10/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataSource.h"

@interface WrapperNSData : NSObject<InputDataSource> {
	NSData * _nsdata;
	NSUInteger _offset;
}

-initWithContentsOfMappedFile:(NSString *)filename;
-initWithNSData:(NSData *)data;

@end
