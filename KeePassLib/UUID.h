//
//  UUID.h
//  KeePass2
//
//  Created by Qiang Yu on 1/2/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ByteBuffer.h"

@interface UUID : ByteBuffer {

}
+(UUID*)getAESUUID;
@end
