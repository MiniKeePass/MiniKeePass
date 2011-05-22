//
//  Kdb4Node.h
//  KeePass2
//
//  Created by Qiang Yu on 2/23/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb.h"
#import "GDataXMLNode.h"

@interface Kdb4Group : KdbGroup {
    GDataXMLElement *element;
}

@property(nonatomic, retain) GDataXMLElement *element;

- (id)initWithElement:(GDataXMLElement*)e;

@end


@interface Kdb4Entry : KdbEntry {
    GDataXMLElement *element;
}

@property(nonatomic, retain) GDataXMLElement *element;

- (id)initWithElement:(GDataXMLElement*)e;

@end


@interface Kdb4Tree : KdbTree {
    GDataXMLDocument *document;
}

@property(nonatomic, retain) GDataXMLDocument *document;

- (id)initWithDocument:(GDataXMLDocument*)doc;

@end
