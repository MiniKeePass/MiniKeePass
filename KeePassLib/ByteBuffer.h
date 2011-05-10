//
//  ByteBuffer.h
//  KeePass2
//
//  Created by Qiang Yu on 1/4/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataSource.h"

@interface ByteBuffer : NSObject {
	uint8_t * _bytes;
	NSUInteger _size;
}

@property(nonatomic, readonly) uint8_t * _bytes;
@property(nonatomic, assign) NSUInteger _size;

-(id)initWithSize:(NSUInteger)size;
-(id)initWithSize:(NSUInteger)size dataSource:(id<InputDataSource>)datasource;
@end
