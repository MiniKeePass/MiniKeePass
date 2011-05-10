//
//  ZipInputData.h
//  KeePass2
//
//  Created by Qiang Yu on 2/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <zlib.h>
#import "ByteBuffer.h"
#import "DataSource.h"

#define OUT_BLOCK 32768
#define IN_BLOCK  16384

@interface GZipInputData : NSObject<InputDataSource> {
	z_stream _stream;
	BOOL _eoz; //end of (un)zip
	
	NSObject<InputDataSource> * _zipped;
	ByteBuffer * _in;		
	ByteBuffer * _out;	
	uint32_t _outOffset;
}

-(id)initWithDataSource:(id<InputDataSource>)zippedSource;

@end
