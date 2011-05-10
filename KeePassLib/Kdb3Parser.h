//
//  Kdb3Parser.h
//  KeePass2
//
//  Created by Qiang Yu on 2/13/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataSource.h"
#import "Kdb.h"

@interface Kdb3Parser : NSObject {
}
-(id<KdbTree>)parse:(id<InputDataSource>)input numGroups:(uint32_t)numGroups numEntris:(uint32_t)numEntries;
@end
