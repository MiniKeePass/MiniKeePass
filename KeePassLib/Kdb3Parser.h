//
//  Kdb3Parser.h
//  KeePass2
//
//  Created by Qiang Yu on 2/13/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb3Node.h"
#import "InputStream.h"

@interface Kdb3Parser : NSObject {
}

- (Kdb3Tree*)parse:(InputStream*)inputStream numGroups:(uint32_t)numGroups numEntris:(uint32_t)numEntries;

@end
