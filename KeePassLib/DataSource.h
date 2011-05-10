//
//  ReadDataSource.h
//  KeePass2
//
//  Created by Qiang Yu on 1/9/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol InputDataSource <NSObject>
-(NSUInteger)readBytes:(void *)buffer length:(NSUInteger)length;
-(NSUInteger)lengthOfRemainingReadbleBytes;
-(NSUInteger)setReadOffset:(NSUInteger) offset; 
-(NSUInteger)moveReadOffset:(NSInteger) offset; 
@end

@protocol OutputDataSink <NSObject>
-(NSUInteger)writeBytes:(void *)buffer length:(NSUInteger)length;
@end

