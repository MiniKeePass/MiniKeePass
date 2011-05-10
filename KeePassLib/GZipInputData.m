//
//  ZipInputData.m
//  KeePass2
//
//  Created by Qiang Yu on 2/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GZipInputData.h"

@interface GZipInputData(PrivateMethods)
-(BOOL)readBlock;
@end


@implementation GZipInputData

#pragma mark -
#pragma mark alloc/dealloc

-(id)initWithDataSource:(id<InputDataSource>)zippedSource{
	if(self=[super init]){
		_eoz = NO;
		
		_stream.avail_in = _stream.avail_out = 0;
		_stream.next_in = _stream.next_out = nil;		
		_stream.zalloc = Z_NULL; _stream.zfree = Z_NULL; _stream.opaque = Z_NULL;		
		
		if(inflateInit2(&_stream, (15+32)))
			@throw [NSException exceptionWithName:@"AppError" reason:@"InflateInitFailure" userInfo:nil];
		
		_out = [[ByteBuffer alloc] initWithSize:OUT_BLOCK]; _out._size = 0;
		_in = [[ByteBuffer alloc] initWithSize:IN_BLOCK]; _in._size = 0;
		
		_zipped = zippedSource;
		
		[_zipped retain];
	}
	return self;
}

-(void)dealloc{
	[_in release];
	[_out release];
	[_zipped release];
	[super dealloc];
}


#pragma mark -
#pragma mark private methods

// read a block of data
// returning YES means _out is OK to read;
// returning NO means _out is no longer OK to read;
-(BOOL)readBlock{		
	if(_eoz){
		_out._size = 0;
		return NO;
	}
	
	int32_t ret = 0;
	
	_stream.avail_out = OUT_BLOCK;
	_stream.next_out = _out._bytes;
	
	do{
		if(!_stream.avail_in){ 
			_in._size = [_zipped readBytes:_in._bytes length:IN_BLOCK];
			if(!_in._size){
					@throw [NSException exceptionWithName:@"InvalidData" reason:@"UnzipError" userInfo:nil];
			}
			else{
				_stream.avail_in = _in._size;
				_stream.next_in = _in._bytes;
			}			
		}
	
		ret = inflate(&_stream, Z_NO_FLUSH);
		
		if(ret){
			inflateEnd(&_stream);
			if(ret!=Z_STREAM_END)
				@throw [NSException exceptionWithName:@"InvalidData" reason:@"UnzipError" userInfo:nil];
			else{
				_eoz = YES;
				break;
			}
		}
	}while(_stream.avail_out);

	if(_eoz){
		_out._size = OUT_BLOCK - _stream.avail_out;
	}else{
		_out._size = OUT_BLOCK;
	}
	return YES;
}


#pragma mark -
#pragma mark InputDataSource interface
-(NSUInteger)readBytes:(void *)buffer length:(NSUInteger)length{
	NSUInteger remaining = length; //number of remaining bytes to read
	NSUInteger bufferOffset = 0;
	while (remaining>0) {
		if(_outOffset == _out._size){
			_outOffset = 0; 
			if(![self readBlock]){
				return length - remaining;
			}
		}
		
		NSUInteger bytesToCopy = MIN(remaining, _out._size - _outOffset);
		
		memcpy(buffer+bufferOffset, _out._bytes+_outOffset, bytesToCopy);
		
		_outOffset+=bytesToCopy; bufferOffset+=bytesToCopy;remaining -= bytesToCopy;
	}
	return length;	
}

-(NSUInteger)lengthOfRemainingReadbleBytes{
	@throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"UnsupportedMethod" userInfo:nil];
}

-(NSUInteger)setReadOffset:(NSUInteger) offset{
	@throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"UnsupportedMethod" userInfo:nil];
}

-(NSUInteger)moveReadOffset:(NSInteger) offset{
	@throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"UnsupportedMethod" userInfo:nil];
}

@end
