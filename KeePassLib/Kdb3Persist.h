//
//  Kdb3Persist.h
//  KeePass2
//
//  Created by Qiang Yu on 2/22/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AESEncryptSource.h"
#import "Kdb3Node.h"

@interface Kdb3Persist : NSObject {
	id<KdbTree> _tree;
	AESEncryptSource * _enc;
	NSInteger _groupId;
}

@property(nonatomic, retain) id<KdbTree> _tree;
@property(nonatomic, retain) AESEncryptSource * _enc;

-(id)initWithTree:(id<KdbTree>)tree andDest:(AESEncryptSource *)dest; 
-(void)persist;
@end
