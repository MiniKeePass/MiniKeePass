//
//  KdbReader.h
//  KeePass2
//
//  Created by Qiang Yu on 3/6/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb.h"
#import "WrapperNSData.h"

@protocol KdbReader<NSObject>
-(id<KdbTree>)load:(WrapperNSData *)input withPassword:(NSString *)password;
-(id<KdbTree>)getKdbTree;
@end

