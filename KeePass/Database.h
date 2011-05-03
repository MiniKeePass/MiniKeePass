//
//   Database.h
//   KeePass
//
//   Created by Qiang Yu (MYKEEPASS AT GMAIL DOT COM) on 11/22/09.
//   Copyright 2009 Qiang Yu. All rights reserved.
//
//   Source code is distributed in the hope that it will be useful,       
//   but WITHOUT ANY WARRANTY; without even the implied warranty of        
//   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         
//   GNU General Public License for more details.  
//
//	 You can redistribute it and/or modify the source code under the terms 
//   of the GNU General Public License as published by the Free Software Foundation; 
//   version 3 of the License.         
//                                                                         
//   You should have received a copy of the GNU General Public License     
//   along with this program; if not, write to the                         
//   Free Software Foundation, Inc.,                                       
//   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.       
//

#import <Foundation/Foundation.h>

enum CryptAlgorithm{
	RIJNDAEL=0,
	TWOFISH=1
};

enum DatabaseError{
	NO_ERROR=0,
	WRONG_PASSWORD=1,
	DATA_CORRUPTION=2,
	FORMAT_UNSUPPORTED=4
};

@interface Group:NSObject{
//
	uint32_t _id;
	uint32_t _image;
	uint16_t _index;
	NSString * _title;
	BOOL _isExpanded;
	Group * _parent;
	NSArray * _children;
	NSArray * _entries;
}
@property (nonatomic, assign) uint32_t _id;
@property (nonatomic, assign) uint32_t _image;
@property (nonatomic, assign) uint16_t _index;
@property (nonatomic, retain) NSString * _title;
@property (nonatomic, assign) BOOL _isExpanded;
@property (nonatomic, retain) Group * _parent;
@property (nonatomic, retain) NSArray * _children;
@property (nonatomic, retain) NSArray * _entries;
//
@end

@interface Entry:NSObject{
//
	uint8_t _uuid[16];
	uint32_t _groupId;
	uint32_t _image;
	uint16_t _index;
	NSString * _title;
	NSString * _url;
	NSString * _username;
	NSString * _password;
	NSString * _comment;
	NSString * _binaryDesc;
	NSDateComponents * _creation;
	NSDateComponents * _lastMod;
	NSDateComponents * _lastAccess;
	NSDateComponents * _expire;
	uint8_t * _binary;
	uint32_t _binarySize;
	Group * _group;
}
@property (nonatomic, assign) uint32_t _groupId;
@property (nonatomic, assign) uint32_t _image;
@property (nonatomic, assign) uint16_t _index;
@property (nonatomic, retain) NSString * _title;
@property (nonatomic, retain) NSString * _url;
@property (nonatomic, retain) NSString * _username;
@property (nonatomic, retain) NSString * _password;
@property (nonatomic, retain) NSString * _comment;
@property (nonatomic, retain) NSString * _binaryDesc;
@property (nonatomic, retain) NSDateComponents * _creation;
@property (nonatomic, retain) NSDateComponents * _lastMod;
@property (nonatomic, retain) NSDateComponents * _lastAccess;
@property (nonatomic, retain) NSDateComponents * _expire;
@property (nonatomic, retain) Group * _group;
@property (nonatomic, assign) uint32_t _binarySize;
-(void)setBinary:(uint8_t *)buffer size:(uint32_t)size;
-(uint8_t *)getBinary;
-(uint8_t *)getUUID;
-(NSComparisonResult)compareIndex:(Entry *)another;
//
@end

@protocol Database
-(enum DatabaseError)openDatabase:(NSString *)path password:(NSString *)password;
-(enum DatabaseError)saveDatabase:(NSString *)path;
-(enum DatabaseError)newDatabase:(NSString *)path password:(NSString *)password;
-(Group *)addGroup:(NSString*)title parent:(Group*)parent;
-(Entry *)addEntry:(NSString*)title group:(Group *)group;
-(void)deleteEntry:(Entry *)entry group:(Group *)group;
-(void)deleteGroup:(Group *)group parent:(Group *)parent;
-(Group *)rootGroup;
-(NSArray *)groups;
-(NSArray *)entries;
-(void)changePassword:(NSString *)password;
@end
