/*
 * Copyright 2011 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "Kdb4Parser.h"
#import "Kdb4Node.h"
#import "DDXMLDocument+MKPAdditions.h"
#import "DDXMLElement+MKPAdditions.h"
#import "Base64.h"

#define FIELD_TITLE     @"Title"
#define FIELD_USER_NAME @"UserName"
#define FIELD_PASSWORD  @"Password"
#define FIELD_URL       @"URL"
#define FIELD_NOTES     @"Notes"

@interface Kdb4Parser (PrivateMethods)
- (void)decodeProtected:(DDXMLElement *)root;
- (void)parseMeta:(DDXMLElement *)root;
- (Kdb4Group *)parseGroup:(DDXMLElement *)root;
- (Kdb4Entry *)parseEntry:(DDXMLElement *)root;
@end

@implementation Kdb4Parser

- (id)initWithRandomStream:(RandomStream *)cryptoRandomStream {
    self = [super init];
    if (self) {
        randomStream = [cryptoRandomStream retain];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    }
    return self;
}

- (void)dealloc {
    [randomStream release];
    [dateFormatter release];
    [super dealloc];
}

int	readCallback(void *context, char *buffer, int len) {
    InputStream *inputStream = (InputStream*)context;
    return [inputStream read:buffer length:len];
}

int closeCallback(void *context) {
    return 0;
}

- (Kdb4Tree *)parse:(InputStream *)inputStream {
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithReadIO:readCallback closeIO:closeCallback context:inputStream options:0 error:nil];
    if (document == nil) {
        @throw [NSException exceptionWithName:@"ParseError" reason:@"Failed to parse database" userInfo:nil];
    }
    
    // Get the root document element
    DDXMLElement *rootElement = [document rootElement];
    
    // Decode all the protected entries
    [self decodeProtected:rootElement];

    DDXMLElement *meta = [rootElement elementForName:@"Meta"];
    if (meta != nil) {
        [self parseMeta:meta];
    }

    DDXMLElement *root = [rootElement elementForName:@"Root"];
    if (root == nil) {
        [document release];
        @throw [NSException exceptionWithName:@"ParseError" reason:@"Failed to parse database" userInfo:nil];
    }

    DDXMLElement *element = [root elementForName:@"Group"];
    if (element == nil) {
        [document release];
        @throw [NSException exceptionWithName:@"ParseError" reason:@"Failed to parse database" userInfo:nil];
    }
    
    Kdb4Tree *tree = [[Kdb4Tree alloc] initWithDocument:document];
    tree.root = [self parseGroup:element];
    
    [document release];
    
    return [tree autorelease];
}

- (void)parseMeta:(DDXMLElement *)root {
    DDXMLElement *element = [root elementForName:@"HeaderHash"];
    if (element != nil) {
        [root removeChild:element];
    }
}

- (void)decodeProtected:(DDXMLElement *)root {
    DDXMLNode *protectedAttribute = [root attributeForName:@"Protected"];
    if ([[protectedAttribute stringValue] isEqual:@"True"]) {
        NSString *str = [root stringValue];
        
        // Base64 decode the string
        NSMutableData *data = [Base64 decode:[str dataUsingEncoding:NSASCIIStringEncoding]];
        
        // Unprotect the password
        [randomStream xor:data];
        
        NSString *unprotected = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
        [root setStringValue:unprotected];
        [unprotected release];
    }
    
    for (DDXMLNode *node in [root children]) {
        if ([node kind] == DDXMLElementKind) {
            [self decodeProtected:(DDXMLElement*)node];
        }
    }
}

- (void)parseTimesElement:(DDXMLElement *)timesElement intoGroup:(Kdb4Group *)group
{
    NSString *str = [[timesElement elementForName:@"CreationTime"] stringValue];
    group.creationTime = [dateFormatter dateFromString:str];
    
    str = [[timesElement elementForName:@"LastModificationTime"] stringValue];
#ifdef DEBUG
    NSDate *modifcationTime = [dateFormatter dateFromString:str];
#endif
    group.lastModificationTime = [dateFormatter dateFromString:str];
    
    str = [[timesElement elementForName:@"LastAccessTime"] stringValue];
    group.lastAccessTime = [dateFormatter dateFromString:str];
    
    str = [[timesElement elementForName:@"ExpiryTime"] stringValue];
    group.expiryTime = [dateFormatter dateFromString:str];
    
}
// reads from DOM into datastructure
- (Kdb4Group *)parseGroup:(DDXMLElement *)root {
    Kdb4Group *group = [[[Kdb4Group alloc] initWithElement:root] autorelease];
    
    DDXMLElement *element = [root elementForName:@"IconID"];
    group.image = element.stringValue.intValue;

    // HBXX
    element = [root elementForName:@"UUID"];
    NSString * lUUID = element.stringValue;
    const char *lUUIDstr = [lUUID UTF8String];
    
    
    element = [root elementForName:@"Name"];
    group.name =  element.stringValue;
    
    DDXMLElement *timesElement = [root elementForName:@"Times"];
    [self parseTimesElement:timesElement intoGroup:group];
    
    for (DDXMLElement *element in [root elementsForName:@"Entry"]) {
        Kdb4Entry *entry = [self parseEntry:element];
        entry.parent = group;
        
        [group addEntry:entry];
    }
    
    for (DDXMLElement *element in [root elementsForName:@"Group"]) {
        Kdb4Group *subGroup = [self parseGroup:element];
        subGroup.parent = group;
        
        [group addGroup:subGroup];
    }
    
    return group;
}

- (void)parseTimesElement:(DDXMLElement *)timesElement intoEntry:(Kdb4Entry *)entry
{
    NSString *str = [[timesElement elementForName:@"CreationTime"] stringValue];
    entry.creationTime = [dateFormatter dateFromString:str];
    
    str = [[timesElement elementForName:@"LastModificationTime"] stringValue];
#ifdef DEBUG
    NSDate *modifcationTime = [dateFormatter dateFromString:str];
#endif
    entry.lastModificationTime = [dateFormatter dateFromString:str];
    
    str = [[timesElement elementForName:@"LastAccessTime"] stringValue];
    entry.lastAccessTime = [dateFormatter dateFromString:str];
    
    str = [[timesElement elementForName:@"ExpiryTime"] stringValue];
    entry.expiryTime = [dateFormatter dateFromString:str];
    
}

- (Kdb4Entry *)parseEntry:(DDXMLElement *)root {
    Kdb4Entry *entry = [[[Kdb4Entry alloc] initWithElement:root] autorelease];
    
    entry.image = [[[root elementForName:@"IconID"] stringValue] intValue];
    
    DDXMLElement *timesElement = [root elementForName:@"Times"];
    [self parseTimesElement:timesElement intoEntry:entry];
        
    for (DDXMLElement *element in [root elementsForName:@"String"]) {
        NSString *key = [[element elementForName:@"Key"] stringValue];

        DDXMLElement *valueElement = [element elementForName:@"Value"];
        NSString *value = [valueElement stringValue];
        
        if ([key isEqualToString:FIELD_TITLE]) {
            entry.title = value;
        } else if ([key isEqualToString:FIELD_USER_NAME]) {
            entry.username = value;
        } else if ([key isEqualToString:FIELD_PASSWORD]) {
            entry.password = value;
        } else if ([key isEqualToString:FIELD_URL]) {
            entry.url = value;
        } else if ([key isEqualToString:FIELD_NOTES]) {
            entry.notes = value;
        } else {
            StringField *stringField = [[StringField alloc] initWithElement:element];
            stringField.name = key;
            stringField.value = value;
            [entry addStringField:stringField];
        }
    }
    
    return entry;
}

@end
