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
- (Kdb4Group*)parseGroup:(GDataXMLElement*)root;
- (Kdb4Entry*)parseEntry:(GDataXMLElement*)root;
@end

@implementation Kdb4Parser

@synthesize _randomStream;

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
    
    GDataXMLElement *rootElement = [document rootElement];
    
    GDataXMLElement *root = [rootElement elementForName:@"Root"];
    if (root == nil) {
        @throw [[NSException alloc] initWithName:@"ParseError" reason:@"Failed to parse database" userInfo:nil];
    }
    
    NSLog(@"XML\n%@", root);
    
    GDataXMLElement *element = [root elementForName:@"Group"];
    if (element == nil) {
        @throw [[NSException alloc] initWithName:@"ParseError" reason:@"Failed to parse database" userInfo:nil];
    }
    
    Kdb4Tree *tree = [[Kdb4Tree alloc] initWithElement:rootElement];
    tree._root = [self parseGroup:element];
    
    return [tree autorelease];
}

- (Kdb4Group*)parseGroup:(GDataXMLElement*)root {
    Kdb4Group *group = [[[Kdb4Group alloc] initWithElement:root] autorelease];
    
    for (GDataXMLElement *element in [root elementsForName:@"Group"]) {
        Kdb4Group *subGroup = [self parseGroup:element];
        subGroup._parent = group;
        
        [group addSubGroup:subGroup];
    }
    
    for (GDataXMLElement *element in [root elementsForName:@"Entry"]) {
        Kdb4Entry *entry = [self parseEntry:element];
        entry._parent = group;
        
        [group addEntry:entry];
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
        
        GDataXMLNode *protectedAttribute = [valueElement attributeForName:@"Protected"];
        if ([[protectedAttribute stringValue] isEqual:@"True"]) {
            NSMutableData *data = [[NSMutableData alloc] initWithCapacity:[value length]];
            [Base64 decode:value to:data];
            value = [_randomStream xor:data];
            [data release];
        }
        
        if ([key isEqualToString:@"Title"]) {
            entry._entryName = value;
        } else if ([key isEqualToString:@"UserName"]) {
            entry._username = value;
        } else if ([key isEqualToString:@"Password"]) {
            NSLog(@"PASSWORD:   %@", element);
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
