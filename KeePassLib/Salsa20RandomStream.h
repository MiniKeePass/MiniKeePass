//
//  Salsa20RandomStream.h
//  KeePass2
//
//  Created by Qiang Yu on 2/28/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataSource.h"
#import "RandomStream.h"

@interface Salsa20RandomStream : NSObject </*InputDataSource,*/ RandomStream> {
	//id<InputDataSource> _source;
	
	uint32_t _state[16];
	uint32_t _index;
	uint8_t _keyStream[64];
}

//@property(nonatomic, retain) id<InputDataSource> _source;

//-(id)init:(uint8_t *)key len:(uint32_t)len input:(id<InputDataSource>)source;
-(id)init:(uint8_t *)key len:(uint32_t)len;
//-(NSUInteger)readBytes:(void *)buffer length:(NSUInteger)length;

@end
