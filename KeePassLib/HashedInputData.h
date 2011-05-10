//
//  HashedInputData.h
//  KeePass2
//
//  Created by Qiang Yu on 1/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataSource.h"
#import "ByteBuffer.h"

@interface HashedInputData : NSObject <InputDataSource> {
	id <InputDataSource>  _dataSource;
	uint32_t _blockIndex;
	ByteBuffer * _block;
	uint32_t _blockOffset;
	BOOL _eof;
}

@property (nonatomic, retain) id<InputDataSource> _dataSource;

-(id)initWithDataSource:(id<InputDataSource>)input;

@end
