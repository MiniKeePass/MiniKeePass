//
//  Kdb4Parser.m
//  KeePass2
//
//  Created by Qiang Yu on 2/4/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb4Parser.h"
#import "Kdb4Node.h"
#import "Base64.h"

@interface Kdb4Parser (PrivateMethods)
- (void)decodeProtected:(GDataXMLElement*)root;
- (Kdb4Group*)parseGroup:(GDataXMLElement*)root;
- (Kdb4Entry*)parseEntry:(GDataXMLElement*)root;
@end

@implementation Kdb4Parser

@synthesize _randomStream;

- (void)dealloc {
    [_randomStream release];
    [super dealloc];
}

int	readCallback(void *context, char *buffer, int len) {
    id<InputDataSource> input = (id<InputDataSource>)context;
    return [input readBytes:buffer length:len];
}

int closeCallback(void *context) {
    return 0;
}

- (id<KdbTree>)parse:(id<InputDataSource>)input {
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithReadIO:readCallback closeIO:closeCallback context:input options:0 error:nil];
    if (document == nil) {
        @throw [[NSException alloc] initWithName:@"ParseError" reason:@"Failed to parse database" userInfo:nil];
    }
    
    // Get the root document element
    GDataXMLElement *rootElement = [document rootElement];
    
    // Decode all the protected entries
    [self decodeProtected:rootElement];
    
    GDataXMLElement *root = [rootElement elementForName:@"Root"];
    if (root == nil) {
        @throw [[NSException alloc] initWithName:@"ParseError" reason:@"Failed to parse database" userInfo:nil];
    }
    
    GDataXMLElement *element = [root elementForName:@"Group"];
    if (element == nil) {
        @throw [[NSException alloc] initWithName:@"ParseError" reason:@"Failed to parse database" userInfo:nil];
    }
    
    Kdb4Tree *tree = [[Kdb4Tree alloc] initWithDocument:document];
    tree._root = [self parseGroup:element];
    
    [document release];
    
    return [tree autorelease];
}

- (void)decodeProtected:(GDataXMLElement*)root {
    GDataXMLNode *protectedAttribute = [root attributeForName:@"Protected"];
    if ([[protectedAttribute stringValue] isEqual:@"True"]) {
        NSString *str = [root stringValue];
        NSMutableData *data = [[NSMutableData alloc] initWithCapacity:[str length]];
        [Base64 decode:str to:data];
        [root setStringValue:[_randomStream xor:data]];
        [data release];
    }
    
    for (GDataXMLNode *node in [root children]) {
        if ([node kind] == GDataXMLElementKind) {
            [self decodeProtected:(GDataXMLElement*)node];
        }
    }
}

- (Kdb4Group*)parseGroup:(GDataXMLElement*)root {
    Kdb4Group *group = [[[Kdb4Group alloc] initWithElement:root] autorelease];
    
    for (GDataXMLElement *element in [root elementsForName:@"Entry"]) {
        Kdb4Entry *entry = [self parseEntry:element];
        entry._parent = group;
        
        [group addEntry:entry];
    }
    
    for (GDataXMLElement *element in [root elementsForName:@"Group"]) {
        Kdb4Group *subGroup = [self parseGroup:element];
        subGroup._parent = group;
        
        [group addSubGroup:subGroup];
    }
    
    return group;
}

- (Kdb4Entry*)parseEntry:(GDataXMLElement*)root {
    Kdb4Entry *entry = [[[Kdb4Entry alloc] initWithElement:root] autorelease];
    
    entry._image = [[[root elementForName:@"IconID"] stringValue] intValue];
    
    for (GDataXMLElement *element in [root elementsForName:@"String"]) {
        NSString *key = [[element elementForName:@"Key"] stringValue];

        GDataXMLElement *valueElement = [element elementForName:@"Value"];
        NSString *value = [valueElement stringValue];
        
        if ([key isEqualToString:@"Title"]) {
            entry._entryName = value;
        } else if ([key isEqualToString:@"UserName"]) {
            entry._username = value;
        } else if ([key isEqualToString:@"Password"]) {
            entry._password = value;
        } else if ([key isEqualToString:@"URL"]) {
            entry._url = value;
        } else if ([key isEqualToString:@"Notes"]) {
            entry._comment = value;
        }
    }
    
    return entry;
}

@end
