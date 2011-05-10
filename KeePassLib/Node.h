//
//  Node.h
//  KeePass2
//
//  Created by Qiang Yu on 2/10/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UUID.h"
#import "RandomStream.h"

/*
 * KDB4 Tags (may not be complete)
 */
#define T_ASSOCIATION "Association"
#define T_AUTOENABLEVISUALHIDING "AutoEnableVisualHiding"
#define T_AUTOTYPE "AutoType"
#define T_CREATIONTIME "CreationTime"
#define T_DATATRANSFEROBFUSCATION "DataTransferObfuscation"
#define T_DATABASEDESCRIPTIONCHANGED "DatabaseDescriptionChanged"
#define T_DATABASENAMECHANGED "DatabaseNameChanged"
#define T_DEFAULTUSERNAMECHANGED "DefaultUserNameChanged"
#define T_ENABLEAUTOTYPE "EnableAutoType"
#define T_ENABLESEARCHING "EnableSearching"
#define T_ENABLED "Enabled"
#define T_ENTRY "Entry"
#define T_ENTRYTEMPLATESGROUP "EntryTemplatesGroup"
#define T_ENTRYTEMPLATESGROUPCHANGED "EntryTemplatesGroupChanged"
#define T_EXPIRES "Expires"
#define T_EXPIRYTIME "ExpiryTime"
#define T_GENERATOR "Generator"
#define T_GROUP "Group"
#define T_HISTORY "History"
#define T_ICONID "IconID"
#define T_ISEXPANDED "IsExpanded"
#define T_KEEPASSFILE "KeePassFile"
#define T_KEY "Key"
#define T_KEYSTROKESEQUENCE "KeystrokeSequence"
#define T_LASTACCESSTIME "LastAccessTime"
#define T_LASTMODIFICATIONTIME "LastModificationTime"
#define T_LASTSELECTEDGROUP "LastSelectedGroup"
#define T_LASTTOPVISIBLEENTRY "LastTopVisibleEntry"
#define T_LASTTOPVISIBLEGROUP "LastTopVisibleGroup"
#define T_LOCATIONCHANGED "LocationChanged"
#define T_MAINTENANCEHISTORYDAYS "MaintenanceHistoryDays"
#define T_MEMORYPROTECTION "MemoryProtection"
#define T_META "Meta"
#define T_NAME "Name"
#define T_NOTES "Notes"
#define T_PROTECTNOTES "ProtectNotes"
#define T_PROTECTPASSWORD "ProtectPassword"
#define T_PROTECTTITLE "ProtectTitle"
#define T_PROTECTURL "ProtectURL"
#define T_PROTECTUSERNAME "ProtectUserName"
#define T_RECYCLEBINCHANGED "RecycleBinChanged"
#define T_RECYCLEBINENABLED "RecycleBinEnabled"
#define T_RECYCLEBINUUID "RecycleBinUUID"
#define T_ROOT "Root"
#define T_STRING "String"
#define T_TIMES "Times"
#define T_UUID "UUID"
#define T_URL "URL"
#define T_USAGECOUNT "UsageCount"
#define T_VALUE "Value"
#define T_WINDOW "Window"

@interface Node : NSObject {
	Node * _parent;
	NSMutableArray * _children;
	//xml properties
	NSMutableDictionary * _attributes;
	NSMutableString * _text;
	NSString * _name;
}

@property(nonatomic, retain) Node * _parent;
@property(nonatomic, retain) NSMutableString * _text;
@property(nonatomic, retain) NSString * _name;
@property(nonatomic, readonly, getter=_children) NSArray * _children;
@property(nonatomic, readonly, getter=_attributes) NSDictionary * _attributes;

-(id)initWithUTF8Name:(uint8_t *)name;
-(id)initWithStringName:(NSString *)name;
-(void)addChild:(Node *) child;
-(void)removeChild:(Node *) child;
-(void)addAttribute:(NSString *)key value:(NSString *)value;
-(void)breakCyclcReference;
-(void)postProcess:(id<RandomStream>)rs; //
@end
