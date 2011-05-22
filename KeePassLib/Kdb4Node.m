//
//  Kdb4Node.m
//  KeePass2
//
//  Created by Qiang Yu on 2/23/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb4Node.h"
#import "Utils.h"

@implementation Kdb4Group

@synthesize element;

- (id)initWithElement:(GDataXMLElement*)e {
    self = [super init];
    if(self) {
        self.element = e;
    }
    return self;
}

- (void)dealloc {
    [element release];
    [super dealloc];
}

@end


@implementation Kdb4Entry

@synthesize element;

- (id)initWithElement:(GDataXMLElement*)e {
    self = [super init];
    if(self) {
        self.element = e;
    }
    return self;
}

- (void)dealloc {
    [element release];
    [super dealloc];
}

@end


@implementation Kdb4Tree

@synthesize document;

- (id)initWithDocument:(GDataXMLDocument*)doc {
    self = [super init];
    if(self) {
        self.document = doc;
    }
    return self;
}

- (void)dealloc {
    [document release];
    [super dealloc];
}

@end
