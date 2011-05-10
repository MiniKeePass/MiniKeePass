//
//  RandomStream.h
//  KeePass2
//
//  Created by Qiang Yu on 3/1/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RandomStream <NSObject>
-(NSString *)xor:(NSData *)data;
@end
