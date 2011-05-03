//
//   Database.m
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

#import "Database.h"

@implementation Group
//
@synthesize _id;
@synthesize _image;
@synthesize _index;
@synthesize _title;
@synthesize _isExpanded;
@synthesize _parent;
@synthesize _children;
@synthesize _entries;
//
-(id)init{
	self=[super init];
	if(self){
		_parent = nil;
		_children = [[NSMutableArray alloc]initWithCapacity:2];
		_entries = [[NSMutableArray alloc]initWithCapacity:8];
	}
	return self;
}

-(void)dealloc{
	//NSLog(@"deallocate group %@", _title);
	[_title release];
	[_parent release];	
	[_children release];
	[_entries release];
	[super dealloc];
}

@end


@implementation Entry
//
@synthesize _groupId;
@synthesize _image;
@synthesize _index;
@synthesize _title;
@synthesize _url;
@synthesize _username;
@synthesize _password;
@synthesize _comment;
@synthesize _binaryDesc;
@synthesize _creation;
@synthesize _lastMod;
@synthesize _lastAccess;
@synthesize _expire;
@synthesize _group;
@synthesize _binarySize;
//
-(id)init{
	self=[super init];
	if(self){
		_binary = nil;
	}
	return self;
}

-(void)dealloc{
	//NSLog(@"deallocate entry %@", _title);	
	[_title release];
	[_url release];
	[_username release];
	[_password release];
	[_comment release];
	[_binaryDesc release];
	[_creation release];
	[_lastMod release];
	[_lastAccess release];
	[_expire release];
	[_group release];
	free(_binary);
	[super dealloc];
}

-(NSComparisonResult) compareIndex:(Entry *)another {
	if(_index == another._index){
		return NSOrderedSame;
	}else if(_index < another._index){
		return NSOrderedAscending;
	}
	return NSOrderedDescending;
}

-(void)setBinary:(uint8_t *) buffer size:(uint32_t)size{
	if(_binary) free(_binary);
	_binary = malloc(size);
	memcpy(_binary, buffer, size);
}

-(uint8_t *) getBinary{
	return _binary;
}

-(uint8_t *) getUUID{
	return _uuid;
}

@end



