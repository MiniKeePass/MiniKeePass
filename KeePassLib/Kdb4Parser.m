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
    InputStream *inputStream = (InputStream*)context;
    return [inputStream read:buffer length:len];
}

int closeCallback(void *context) {
    return 0;
}

- (Kdb4Tree*)parse:(InputStream*)inputStream {
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithReadIO:readCallback closeIO:closeCallback context:inputStream options:0 error:nil];
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
    tree.root = [self parseGroup:element];
    
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
    
    GDataXMLElement *element = [root elementForName:@"IconID"];
    group.image = element.stringValue.intValue;
    
    element = [root elementForName:@"Name"];
    group.name =  element.stringValue;
    
    for (GDataXMLElement *element in [root elementsForName:@"Entry"]) {
        Kdb4Entry *entry = [self parseEntry:element];
        entry.parent = group;
        
        [group addEntry:entry];
    }
    
    for (GDataXMLElement *element in [root elementsForName:@"Group"]) {
        Kdb4Group *subGroup = [self parseGroup:element];
        subGroup.parent = group;
        
        [group addGroup:subGroup];
    }
    
    return group;
}

- (Kdb4Entry*)parseEntry:(GDataXMLElement*)root {
    Kdb4Entry *entry = [[[Kdb4Entry alloc] initWithElement:root] autorelease];
    
    entry.image = [[[root elementForName:@"IconID"] stringValue] intValue];
    
    for (GDataXMLElement *element in [root elementsForName:@"String"]) {
        NSString *key = [[element elementForName:@"Key"] stringValue];

        GDataXMLElement *valueElement = [element elementForName:@"Value"];
        NSString *value = [valueElement stringValue];
        
        if ([key isEqualToString:@"Title"]) {
            entry.title = value;
        } else if ([key isEqualToString:@"UserName"]) {
            entry.username = value;
        } else if ([key isEqualToString:@"Password"]) {
            entry.password = value;
        } else if ([key isEqualToString:@"URL"]) {
            entry.url = value;
        } else if ([key isEqualToString:@"Notes"]) {
            entry.notes = value;
        }
    }
    
    return entry;
}

@end
