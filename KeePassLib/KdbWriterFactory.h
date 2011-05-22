//
//  KdbWriterFactory.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/21/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb.h"

@interface KdbWriterFactory : NSObject {
    
}

+ (void)persist:(KdbTree*)tree file:(NSString*)filename withPassword:(NSString*)password;

@end
