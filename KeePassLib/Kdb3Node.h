//
//  KDB3Node.h
//  KeePass2
//
//  Created by Qiang Yu on 2/12/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//


/**
 * KDB3 GROUP and Node Definition
 **/
#import <Foundation/Foundation.h>
#import "Kdb.h"
#import "UUID.h"
#import "ByteBuffer.h"
#import "BinaryContainer.h"

////
//// Kdb3Group
////
@interface Kdb3Group : KdbGroup {
    uint32_t _id;
    uint32_t _flags;
    NSMutableArray *_metaEntries;
}

@property(nonatomic, assign) uint32_t _id;
@property(nonatomic, assign) uint32_t _flags;
@property(nonatomic, readonly) NSArray *_metaEntries;

@end


////
//// Kdb3Entry
////
@interface Kdb3Entry : KdbEntry {
    UUID *_uuid;
    NSString *_binaryDesc;
    uint32_t _binarySize;
    id<BinaryContainer> _binary;
}

@property(nonatomic, retain) UUID *_uuid;
@property(nonatomic, retain) NSString *_binaryDesc;
@property(nonatomic, assign) uint32_t _binarySize;
@property(nonatomic, retain) id<BinaryContainer> _binary;

- (id)initWithNewUUID;
- (BOOL)isMeta;

@end


@interface Kdb3Tree : KdbTree {

}

- (id)initNewTree;

@end

