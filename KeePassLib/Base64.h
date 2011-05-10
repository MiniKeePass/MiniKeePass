//
//  Base64.h
//  KeePass2
//
//  Created by Qiang Yu on 2/27/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataSource.h"

@interface Base64 : NSObject  {

}

+(void)decode:(NSString *)enc to:(NSMutableData *)data;

@end
