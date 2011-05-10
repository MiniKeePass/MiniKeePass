//
//  Password.h
//  KeePass2
//
//  Created by Qiang Yu on 1/5/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ByteBuffer.h"

@interface KdbPassword : NSObject {
	ByteBuffer * _masterSeed;
	ByteBuffer * _transformSeed;	
	uint64_t _rounds;	
}

@property(nonatomic, retain) ByteBuffer * _masterSeed;
@property(nonatomic, retain) ByteBuffer * _transformSeed;
@property(nonatomic, assign) uint64_t _rounds;

-(ByteBuffer *)createFinalKey32ForPasssword:(NSString *)password coding:(NSStringEncoding)coding kdbVersion:(uint8_t)ver;

@end
