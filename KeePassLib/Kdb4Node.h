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

@interface Kdb4Group : NSObject<KdbGroup> {
    GDataXMLElement *_element;
    Kdb4Group * _parent;
    NSMutableArray * _subGroups;
    NSMutableArray * _entries;
}

@property(nonatomic, retain, getter=getElement) GDataXMLElement *_element;
@property(nonatomic, retain, getter=getParent, setter=setParent:) Kdb4Group * _parent;
@property(nonatomic, retain, getter=getSubGroups) NSMutableArray * _subGroups;
@property(nonatomic, retain, getter=getEntries) NSMutableArray * _entries;

- (id)initWithElement:(GDataXMLElement*)element;
- (void)breakCyclcReference;

@end


@interface Kdb4Entry : NSObject<KdbEntry> {
    GDataXMLElement *_element;
    Kdb4Group *_parent;
    
    NSInteger _image;
    NSString *_entryName;
    NSString *_username;
    NSString *_password;
    NSString *_url;
    NSString *_comment;
}

@property(nonatomic, retain, getter=getElement) GDataXMLElement *_element;
@property(nonatomic, retain, getter=getParent, setter=setParent:) Kdb4Group *_parent;

@property(nonatomic, assign, getter=getImage, setter=setImage:) NSInteger _image;
@property(nonatomic, copy, getter=getEntryName, setter=setEntryName:) NSString *_entryName;
@property(nonatomic, copy, getter=getUserName, setter=setUserName:) NSString *_username;
@property(nonatomic, copy, getter=getPassword, setter=setPassword:) NSString *_password;
@property(nonatomic, copy, getter=getURL, setter=setURL:) NSString *_url;
@property(nonatomic, copy, getter=getComments, setter=setComments:) NSString *_comment;

- (id)initWithElement:(GDataXMLElement*)element;
- (void)breakCyclcReference;

@end


@interface Kdb4Tree : NSObject<KdbTree> {
    GDataXMLElement *_element;
    Kdb4Group *_root;
    NSMutableDictionary *_meta;
}

@property(nonatomic, retain, getter=getElement) GDataXMLElement *_element;
@property(nonatomic, retain, getter=getRoot) Kdb4Group *_root;
@property(nonatomic, retain) NSMutableDictionary *_meta;

- (id)initWithElement:(GDataXMLElement*)element;

@end