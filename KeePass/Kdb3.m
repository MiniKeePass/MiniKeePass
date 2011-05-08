//
//   Kdb3.m
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

#import "Kdb3.h"

@interface Kdb3 (privateMethods)
-(uint32_t)readInt32LE:(NSInputStream *)inputStream;
-(void)transformKey:(uint8_t *)key toDest:(uint8_t *)dest;
-(BOOL)parse:(uint8_t *)body size:(uint32_t)size numberOfGroups:(uint32_t)numGroups numberOfEntries:(uint32_t)numEntries;
-(BOOL)readGroups:(uint8_t *)buffer bufferEnding:(uint8_t *)ending numofGroups:(uint32_t)numerGroups groupSize:(uint32_t *)groupSize levels:(NSMutableArray *)levels;
-(BOOL)readEntries:(uint8_t *)buffer bufferEnding:(uint8_t *)ending numofEntries:(uint32_t)numEntries  entrySize:(uint32_t*)entrySize;
-(NSDateComponents *)dateFromPacked:(uint8_t *)buffer;
-(void)dateToPacked:(NSDateComponents *) date buffer:(uint8_t *) buffer;
-(BOOL)createGroupTree:(NSArray *) levels;
-(BOOL)isMetaStream:(Entry *) entry;
-(uint32_t)serializeGroups:(uint8_t *) buffer;
-(void)sortGroup:(NSMutableArray *)sortedGroups group:(Group *)group;
-(uint32_t)serializeEntries:(NSArray *)entries buffer:(uint8_t *)buffer;
-(enum DatabaseError) loadFile:(NSString *) fileName password:(NSString *)password;
-(enum DatabaseError) saveFile:(NSString *) fileName;
-(enum DatabaseError) newFile:(NSString *) fileName password:(NSString *)password;
-(uint32_t) generateNewGroupId;
-(BOOL)emptyString:(NSString *)str;
-(void)deleteGroupHelper:(Group *)group;

-(void)releaseGroup:(Group *)group;
-(void)releaseEntry:(Entry *)entry;

@end

@implementation Kdb3

#pragma mark -
#pragma mark alloc/dealloc
-(id)init{
	self=[super init];
	if(self){
		_rootGroup = [[Group alloc] init];
		_rootGroup._title=@"$ROOT$";
		_rootGroup._parent=nil;
		_groups = [[NSMutableArray alloc]initWithCapacity:8];
		_entries = [[NSMutableArray alloc]initWithCapacity:32];
		_ignoredEntries = [[NSMutableArray alloc]initWithCapacity:2];
	}
	return self;
}

/********************************************************************************
 due to a bad design, there is cyclic references between groups and entries,
 we must break them to avoid memory leak
 ********************************************************************************/

-(void)releaseGroup:(Group *)group{
	group._parent = nil;
	for(Group * g in group._children){
		[self releaseGroup:g];
	}
	
	for(Entry * e in group._entries){
		[self releaseEntry:e];
	}
}

-(void)releaseEntry:(Entry *)entry{
	entry._group = nil;
}


-(void)dealloc{
	[self releaseGroup:_rootGroup];
	[_rootGroup release];
	[_groups release];
	[_entries release];
	[_ignoredEntries release];
	[super dealloc];
}

#pragma mark -
#pragma mark private methods

#define SWAP_INT16_LE_TO_HOST(X) (CFSwapInt16LittleToHost(*((uint16_t *)X))) 
#define SWAP_INT32_LE_TO_HOST(X) (CFSwapInt32LittleToHost(*((uint32_t *)X)))
#define SWAP_INT16_HOST_TO_LE(X) (CFSwapInt16HostToLittle(X))
#define SWAP_INT32_HOST_TO_LE(X) (CFSwapInt32HostToLittle(X))

/**
 * load the designated file
 */
#define LOADFILE_RETURN(X) { free(body); body=nil;return X; } 
-(enum DatabaseError)loadFile:(NSString *)fileName password:(NSString*)password{
	////
	uint32_t fileSize, cryptoSize;
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSDictionary * attributes = [fileManager attributesOfItemAtPath:fileName error:nil];
	fileSize = [[attributes objectForKey:NSFileSize] intValue];
	
	/////
	uint32_t signature1, signature2;
	uint32_t flags, version;
	uint32_t numGroups, numEntries;

	uint8_t finalRandomSeed[16];
	uint8_t contentsHash[32];
	uint8_t encryptionIV[16];
	
	uint32_t bodySize = fileSize - KDB3_HEADER_SIZE;	
	uint8_t * body = malloc(bodySize);
	
	NSInputStream * inputStream = [[NSInputStream alloc]initWithFileAtPath:fileName];
	[inputStream open];
	
	signature1 = [self readInt32LE:inputStream];
	signature2 = [self readInt32LE:inputStream];
	flags = [self readInt32LE:inputStream];
	version = [self readInt32LE:inputStream];	
	[inputStream read:finalRandomSeed maxLength:16];
	[inputStream read:encryptionIV maxLength:16];
	numGroups = [self readInt32LE:inputStream];
	numEntries = [self readInt32LE:inputStream];
	[inputStream read:contentsHash maxLength:32];
	[inputStream read:_transfRandomSeed maxLength:32];	
	_keyTransfRounds = [self readInt32LE:inputStream];
	[inputStream read:body maxLength:(fileSize - KDB3_HEADER_SIZE)];
	
	[inputStream close];
	[inputStream release];
	
	if(signature1!=KDB3_SIG1||signature2!=KDB3_SIG2){
		LOADFILE_RETURN(FORMAT_UNSUPPORTED);
	}
	
	if((version & 0xFFFFFF00)!=(KDB3_VER & 0xFFFFFF00)){
		LOADFILE_RETURN(FORMAT_UNSUPPORTED);
	}
	
	if(flags & FLAG_RIJNDAEL) 
		_algorithm = RIJNDAEL;
	else if(flags & FLAG_TWOFISH) 
		_algorithm = TWOFISH;
	else{
		LOADFILE_RETURN(FORMAT_UNSUPPORTED);
	}
	
	
	uint8_t key[32], finalKey[32];	

	const char * passCP1252 = [password cStringUsingEncoding:NSWindowsCP1252StringEncoding];
	
	CC_SHA256((uint8_t *)passCP1252, strlen(passCP1252), key);
	
	[self transformKey:key toDest:_masterKey];
	
	
	CC_SHA256_CTX ctx;
	
	CC_SHA256_Init(&ctx);
	CC_SHA256_Update(&ctx, finalRandomSeed, 16);
	CC_SHA256_Update(&ctx, _masterKey, 32);
	CC_SHA256_Final(finalKey, &ctx);
		
	/////	
	if(_algorithm == RIJNDAEL){		
		size_t movedBytes;
		
		CCCryptorRef cryptorRef = nil;
        CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, finalKey, kCCKeySizeAES256, encryptionIV, &cryptorRef);
		if(CCCryptorUpdate(cryptorRef, body, bodySize, body, bodySize, &movedBytes)){
			CCCryptorRelease(cryptorRef);		 
			LOADFILE_RETURN(WRONG_PASSWORD);
		}
		
		cryptoSize = movedBytes;
		
		if(CCCryptorFinal(cryptorRef, body+movedBytes, bodySize-movedBytes, &movedBytes)){
			CCCryptorRelease(cryptorRef);
			LOADFILE_RETURN(WRONG_PASSWORD);
		}
		
		cryptoSize += movedBytes;
		
		CCCryptorRelease(cryptorRef);		 
	}else{
		LOADFILE_RETURN(FORMAT_UNSUPPORTED);
	}
	
	CC_SHA256((uint8_t *)body, cryptoSize, finalKey);	
	
	if(memcmp(contentsHash, finalKey, 32)!=0){
		LOADFILE_RETURN(WRONG_PASSWORD);
	}	
	
	if(![self parse:body size:cryptoSize numberOfGroups:numGroups numberOfEntries:numEntries])
		LOADFILE_RETURN(DATA_CORRUPTION);
	
	LOADFILE_RETURN(NO_ERROR);
}

-(enum DatabaseError)saveFile:(NSString *)fileName{
	uint32_t bufferSize, encryptedSize;
		
	uint32_t flags, version;
	uint32_t numGroups, numEntries;
	
	uint8_t finalRandomSeed[16];
	uint8_t contentsHash[32];
	uint8_t encryptionIV[16];

	bufferSize = KDB3_HEADER_SIZE;
	
	// get the size of all groups
	for(Group * group in _groups){
		bufferSize += 94 +  [group._title lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;
	}
	
	// get the size of all entries 
	for(Entry * entry in _entries){
		bufferSize += 134 + [entry._title lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1
						 + [entry._username lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1
						 + [entry._url lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1
						 + [entry._password lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1
						 + [entry._comment lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1
						 + [entry._binaryDesc lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1
						 + entry._binarySize;
	}
	
	
	for(Entry * entry in _ignoredEntries){
		bufferSize += 165 + [entry._comment lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1
						 + entry._binarySize;		
	}
	
	bufferSize = (bufferSize + 16) - (bufferSize % 16);
	
	flags = FLAG_SHA2;
	
	if(_algorithm == RIJNDAEL) 
		flags |= FLAG_RIJNDAEL;
	else {
		flags |= FLAG_TWOFISH;
	}
	
	version = KDB3_VER;
	numGroups = [_groups count];
	numEntries = [_entries count] + [_ignoredEntries count];
	
	[(NSMutableArray *)_entries sortUsingSelector:@selector(compareIndex:)];
	
	*((uint32_t *)&finalRandomSeed[0]) = arc4random(); *((uint32_t *)&finalRandomSeed[4]) = arc4random();
	*((uint32_t *)&finalRandomSeed[8]) = arc4random(); *((uint32_t *)&finalRandomSeed[12]) = arc4random();

	*((uint32_t *)&encryptionIV[0]) = arc4random(); *((uint32_t *)&encryptionIV[4]) = arc4random();
	*((uint32_t *)&encryptionIV[8]) = arc4random(); *((uint32_t *)&encryptionIV[12]) = arc4random();	
			
	uint8_t * buffer = malloc(bufferSize+16);
	memset(buffer, 0, bufferSize+16);
	
	uint8_t * bufferPtr=buffer+KDB3_HEADER_SIZE;
	
	bufferPtr+=[self serializeGroups:bufferPtr];		
	bufferPtr+=[self serializeEntries:_entries buffer:bufferPtr];	
	bufferPtr+=[self serializeEntries:_ignoredEntries buffer:bufferPtr];
			
	CC_SHA256((uint8_t *)(buffer+KDB3_HEADER_SIZE), bufferPtr-buffer-KDB3_HEADER_SIZE, contentsHash);		
	
	*((uint32_t *)(buffer)) = SWAP_INT32_HOST_TO_LE(KDB3_SIG1);
	*((uint32_t *)(buffer+4)) = SWAP_INT32_HOST_TO_LE(KDB3_SIG2);
	*((uint32_t *)(buffer+8)) = SWAP_INT32_HOST_TO_LE(flags);
	*((uint32_t *)(buffer+12)) = SWAP_INT32_HOST_TO_LE(version);

	memcpy(buffer+16, finalRandomSeed, 16);
	memcpy(buffer+32, encryptionIV, 16);

	*((uint32_t *)(buffer+48)) = SWAP_INT32_HOST_TO_LE(numGroups);
	*((uint32_t *)(buffer+52)) = SWAP_INT32_HOST_TO_LE(numEntries);	

	memcpy(buffer+56, contentsHash, 32);
	memcpy(buffer+88, _transfRandomSeed, 32);

	*((uint32_t *)(buffer+120)) = SWAP_INT32_HOST_TO_LE(_keyTransfRounds);		
	
	uint8_t finalKey[32];
	
	CC_SHA256_CTX ctx;

	CC_SHA256_Init(&ctx);
	CC_SHA256_Update(&ctx, finalRandomSeed, 16);
	CC_SHA256_Update(&ctx, _masterKey, 32);
	CC_SHA256_Final(finalKey, &ctx);
	
	
	if(_algorithm == RIJNDAEL){
		/*
		Rijndael * aes = [[Rijndael alloc]init];
		
		[aes setMode:CBC Direction:Encrypt Key:finalKey KeyLength:Key32Bytes andInitVector:encryptionIV];
		encryptedSize = [aes padEncrypt:(buffer+KDB3_HEADER_SIZE) Length:(bufferPtr-buffer-KDB3_HEADER_SIZE) toDest:buffer+KDB3_HEADER_SIZE];		
		[aes release];
		 */
		
		size_t movedBytes, size=bufferPtr-buffer-KDB3_HEADER_SIZE;
		
		CCCryptorRef cryptorRef = nil;
        CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, finalKey, kCCKeySizeAES256, encryptionIV, &cryptorRef);
		if(CCCryptorUpdate(cryptorRef, (buffer+KDB3_HEADER_SIZE), size, (buffer+KDB3_HEADER_SIZE), bufferSize-KDB3_HEADER_SIZE, &movedBytes)){
			CCCryptorRelease(cryptorRef);
			return DATA_CORRUPTION;
		}
		
		encryptedSize = movedBytes;
		

		
		if(CCCryptorFinal(cryptorRef, buffer+KDB3_HEADER_SIZE+movedBytes, bufferSize-movedBytes-KDB3_HEADER_SIZE, &movedBytes)){
			CCCryptorRelease(cryptorRef);
			return DATA_CORRUPTION;
		}
		
		encryptedSize += movedBytes;
	
			NSLog(@">>> %d >>> %d", encryptedSize, bufferSize);	
		
		CCCryptorRelease(cryptorRef);		
	}else{
		return FORMAT_UNSUPPORTED;
	}
	
	NSOutputStream * outputStream = [[NSOutputStream alloc]initToFileAtPath:fileName append:NO];
	[outputStream open];
	[outputStream write:buffer maxLength:encryptedSize+KDB3_HEADER_SIZE];
	[outputStream close];
	[outputStream release];
	free(buffer);
	
	return NO_ERROR;
}

-(void)changePassword:(NSString *)password{
	uint8_t key[32];
	const char * passCP1252 = [password cStringUsingEncoding:NSWindowsCP1252StringEncoding];
		
	CC_SHA256((uint8_t *)passCP1252, strlen(passCP1252), key);		
	
	[self transformKey:key toDest:_masterKey];	
}

-(enum DatabaseError) newFile:(NSString *) fileName password:(NSString *)password{		
	_keyTransfRounds = 6000;
	_algorithm = RIJNDAEL;
	
	uint8_t key[32];
	
	const char * passCP1252 = [password cStringUsingEncoding:NSWindowsCP1252StringEncoding];
	
	CC_SHA256((uint8_t *)passCP1252, strlen(passCP1252), key);		
	 
	// Generate the transform random seed
	*((uint32_t *)&_transfRandomSeed[0]) = arc4random(); *((uint32_t *)&_transfRandomSeed[4]) = arc4random();
	*((uint32_t *)&_transfRandomSeed[8]) = arc4random(); *((uint32_t *)&_transfRandomSeed[12]) = arc4random();
	*((uint32_t *)&_transfRandomSeed[16]) = arc4random(); *((uint32_t *)&_transfRandomSeed[20]) = arc4random();
	*((uint32_t *)&_transfRandomSeed[24]) = arc4random(); *((uint32_t *)&_transfRandomSeed[28]) = arc4random();	
		
	[self transformKey:key toDest:_masterKey];
		
	// Add a sample group 
	[self addGroup:@"Internet" parent:nil];
	
	return [self saveFile:fileName];
}

-(uint32_t) readInt32LE:(NSInputStream *)inputStream {
	uint32_t value;
	[inputStream read:(uint8_t *)(&value) maxLength:4];
	return CFSwapInt32LittleToHost(value);
}


/**
 * key:  result of SHA256(password)
 * dest: 256 bits to hold the key transform result
 */
-(void) transformKey:(uint8_t *)key toDest:(uint8_t *)dest {
	memcpy(dest, key, 32);	
	size_t tmp;
	
	CCCryptorRef cryptorRef = nil;
	CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128,kCCOptionECBMode,_transfRandomSeed, kCCKeySizeAES256, nil,&cryptorRef);
	
	for(int i=0; i<_keyTransfRounds; i++){
		CCCryptorUpdate(cryptorRef, dest, 32, dest, 32, &tmp);
	}
	
	// no need to call CCCryptorFinal
	CCCryptorRelease(cryptorRef);
	
	CC_SHA256(dest, 32, dest);		
}

#define PARSE_RETURN(X) {[levels release]; return X; } 
-(BOOL)parse:(uint8_t *)body size:(uint32_t)size numberOfGroups:(uint32_t)numGroups numberOfEntries:(uint32_t)numEntries{
	NSMutableArray * levels = [[NSMutableArray alloc]initWithCapacity:8];
	uint32_t bodyOffset = 0;
	
	uint32_t tmpSize=0; //size of groups in bytes
	if(![self readGroups:body bufferEnding:(body+size) numofGroups:numGroups groupSize:&tmpSize levels:levels]){
			PARSE_RETURN(NO);
	}
	
	bodyOffset += tmpSize;
	
	if(![self readEntries:(body+bodyOffset) bufferEnding:(body+size) numofEntries:numEntries entrySize:&tmpSize]){
		PARSE_RETURN(NO);
	}
	
	/*
	  we ignore all meta streams in this version.
	*/
	for(Entry * entry in _entries){
		if([self isMetaStream:entry]){
			[(NSMutableArray *)_ignoredEntries addObject:entry];
		}
	}
	
	[(NSMutableArray *)_entries removeObjectsInArray:_ignoredEntries];
	
	if(![self createGroupTree:levels]){
		PARSE_RETURN(NO);
	}	
	
	PARSE_RETURN(YES);
}

#define READENTRIES_RETURN(X) {[entry release]; return X; }
-(BOOL)readEntries:(uint8_t *)buffer bufferEnding:(uint8_t *)ending numofEntries:(uint32_t)numEntries  entrySize:(uint32_t*)entrySize {
	uint16_t fieldType;
	uint32_t fieldSize;
			
	Entry * entry = [[Entry alloc]init];
	
	for(uint32_t curEntry=0; curEntry<numEntries;){
		fieldType = SWAP_INT16_LE_TO_HOST(buffer); buffer+=2; (*entrySize)+=2;
		if(buffer>=ending) READENTRIES_RETURN(NO);
		
		fieldSize = SWAP_INT32_LE_TO_HOST(buffer); buffer+=4; (*entrySize)+=4;
		if(buffer+fieldSize>ending){
			READENTRIES_RETURN(NO);
		}
		
		switch(fieldType){
			case 0x0000: break;
			case 0x0001: memcpy([entry getUUID], buffer, 16); break;
			case 0x0002: entry._groupId = SWAP_INT32_LE_TO_HOST(buffer); break;  
			case 0x0003: entry._image = SWAP_INT32_LE_TO_HOST(buffer); break;
			case 0x0004: {
				NSString * title = [[NSString alloc]initWithCString:(char *)buffer encoding:NSUTF8StringEncoding];
                entry._title = title;
				[title release];
				break;
			}
			case 0x0005: {
				NSString * url = [[NSString alloc]initWithCString:(char *)buffer encoding:NSUTF8StringEncoding];
                entry._url = url;
				[url release];
                break;
			}
			case 0x0006: {
				NSString * username = [[NSString alloc]initWithCString:(char *)buffer encoding:NSUTF8StringEncoding];
                entry._username = username;
				[username release];
                break;
			}
			case 0x0007:{
				NSString * password = [[NSString alloc]initWithCString:(char *)buffer encoding:NSUTF8StringEncoding]; 
				entry._password = password;
				[password release];
                break;
			}
			case 0x0008:{
				NSString * comment = [[NSString alloc]initWithCString:(char *)buffer encoding:NSUTF8StringEncoding]; 
				entry._comment = comment;
				[comment release];
                break;
			}
			case 0x0009:{
				entry._creation = [self dateFromPacked:buffer];
                break;
			}
			case 0x000A:{
				entry._lastMod = [self dateFromPacked:buffer];
                break;
			}
			case 0x000B:{
				entry._lastAccess = [self dateFromPacked:buffer];
                break;
			}
			case 0x000C:{
				entry._expire = [self dateFromPacked:buffer];
                break;
			}
			case 0x000D:{
				NSString * binaryDesc = [[NSString alloc]initWithCString:(char *)buffer encoding:NSUTF8StringEncoding]; 
				entry._binaryDesc = binaryDesc;
				[binaryDesc release];
                break;	
			}
			case 0x000E:
				if(fieldSize){
					entry._binarySize = fieldSize;
					[entry setBinary:buffer size:fieldSize];
				}
                break;
			case 0xFFFF:
                break;
			default:
                READENTRIES_RETURN(NO);
        }
			
		if(fieldType == 0xFFFF){
			curEntry ++;
			[(NSMutableArray *)_entries addObject:entry];
			[entry release]; entry = [[Entry alloc] init];
		}
		
		buffer += fieldSize; (*entrySize)+=fieldSize;
	}
	
	READENTRIES_RETURN(TRUE);
}


#define READGROUPS_RETURN(X) {[group release]; return X; }
-(BOOL)readGroups:(uint8_t *)buffer bufferEnding:(uint8_t *)ending numofGroups:(uint32_t)numGroups  groupSize:(uint32_t*)groupSize levels:(NSMutableArray *)levels{
	uint16_t fieldType;
	uint32_t fieldSize;
	
	Group * group = [[Group alloc] init];
	
	//read groups
	for(uint32_t curGroup=0; curGroup<numGroups;){
		fieldType = SWAP_INT16_LE_TO_HOST(buffer); buffer+=2; (*groupSize)+=2;
		if(buffer>=ending) READGROUPS_RETURN(NO);
		
		fieldSize = SWAP_INT32_LE_TO_HOST(buffer); buffer+=4; (*groupSize)+=4;
		if(buffer+fieldSize>ending) READGROUPS_RETURN(NO);
		
		switch(fieldType){
			case 0x0000: break;
			case 0x0001: group._id = SWAP_INT32_LE_TO_HOST(buffer); break;
			case 0x0002: {
				NSString * groupTitle = [[NSString alloc]initWithCString:(char *)buffer encoding:NSUTF8StringEncoding];
				group._title = groupTitle;
				[groupTitle release];
			}
			case 0x0003: break;
			case 0x0004: break;
			case 0x0005: break;
			case 0x0006: break;
			case 0x0007: group._image = SWAP_INT32_LE_TO_HOST(buffer); break;
			case 0x0008: {
				NSNumber * level = [NSNumber numberWithUnsignedInteger:SWAP_INT16_LE_TO_HOST(buffer)];
				[levels addObject:level];
				break;
			}
			case 0x0009: break;
			case 0xFFFF: break;
			default:
				READGROUPS_RETURN(NO);
		}
		
		if(fieldType == 0xFFFF){
			curGroup++;
			[(NSMutableArray *)_groups addObject:group];
			[group release]; group = [[Group alloc] init];
		}
		
		buffer +=fieldSize; (*groupSize)+=fieldSize;
	}
	
	READGROUPS_RETURN(YES);
}

-(NSDateComponents *)dateFromPacked:(uint8_t *)buffer{
	uint32_t dw1, dw2, dw3, dw4, dw5;
	dw1 = (uint32_t)buffer[0]; dw2 = (uint32_t)buffer[1]; dw3 = (uint32_t)buffer[2];
	dw4 = (uint32_t)buffer[3]; dw5 = (uint32_t)buffer[4];
	int y = (dw1 << 6) | (dw2 >> 2);
	int mon = ((dw2 & 0x00000003) << 2) | (dw3 >> 6);
	int d = (dw3 >> 1) & 0x0000001F;
	int h = ((dw3 & 0x00000001) << 4) | (dw4 >> 4);
	int min = ((dw4 & 0x0000000F) << 2) | (dw5 >> 6);
	int s = dw5 & 0x0000003F;
	
	NSDateComponents * components = [[NSDateComponents alloc]init];
	components.year = y; components.month = mon; components.day = d;
	components.hour = h; components.minute = min; components.second = s;
	return [components autorelease];		
}

-(void)dateToPacked:(NSDateComponents *) date buffer:(uint8_t *) buffer{
	int y = date.year, mon = date.month, d=date.day, h=date.hour, min=date.minute, s=date.second;
	buffer[0] = (uint8_t)(((uint32_t)y >> 6) & 0x0000003F);
	buffer[1] = (uint8_t)((((uint32_t)y & 0x0000003F) << 2) | (((uint32_t)mon >> 2) & 0x00000003));
	buffer[2] = (uint8_t)((((uint32_t)mon & 0x00000003) << 6) | (((uint32_t)d & 0x0000001F) << 1) | (((uint32_t)h >> 4) & 0x00000001));
	buffer[3] = (uint8_t)((((uint32_t)h & 0x0000000F) << 4) | (((uint32_t)min >> 2) & 0x0000000F));
	buffer[4] = (uint8_t)((((uint32_t)min & 0x00000003) << 6) | ((uint32_t)s & 0x0000003F));	
}

-(BOOL)createGroupTree:(NSArray *) levels{
	uint32_t level = [[levels objectAtIndex:0]unsignedIntValue];
	if(level!=0) return NO;
	
	//find the parent for every group
	for(int i=0;i<[_groups count];i++){
		Group * group = [_groups objectAtIndex:i];
		level = [[levels objectAtIndex:i]unsignedIntValue];		
		
		if(level==0){
			group._parent=_rootGroup;
			group._index=[_rootGroup._children count];
			[(NSMutableArray*)_rootGroup._children addObject:group];
			continue;
		}
		
		uint32_t level2;
		int j;
		//the first item with a lower level is the parent
		for(j=i-1;j>=0;j--){
			level2 = [[levels objectAtIndex:j]unsignedIntValue];
			if(level2<level){
				if(level-level2!=1) return NO;
				break;
			}
			if(j==0) return NO; //No parent found
		}
		
		Group * parent = [_groups objectAtIndex:j];
		group._parent = parent;
		group._index = [parent._children count];
		[(NSMutableArray *)parent._children addObject:group];
	}
	
	uint32_t * entryIndexCounter = malloc([_groups count]<<2);
	memset(entryIndexCounter, 0, [_groups count]<<2);

	for(Entry * entry in _entries){
		for(int g=0; g<[_groups count]; g++){
			Group * group = [_groups objectAtIndex:g];
			if(entry._groupId == group._id){
				[(NSMutableArray *)group._entries addObject:entry];
				entry._group = group;
				entry._index = entryIndexCounter[g];
				entryIndexCounter[g]++;
			}
		}
	}
	free(entryIndexCounter);
	return YES;	
}

-(BOOL)isMetaStream:(Entry *) entry{		
	if(![entry getBinary]) return NO;
	if(!entry._comment || ![entry._comment length]) return NO;
	if(!entry._binaryDesc || [entry._binaryDesc compare:@"bin-stream"]) return NO;
	if(!entry._title || [entry._title compare:@"Meta-Info"]) return NO;
	if(!entry._username || [entry._username compare:@"SYSTEM"]) return NO;
	if(!entry._url || [entry._url compare:@"$"]) return NO;
	if(entry._image) return NO;
	return YES;
}

-(void)sortGroup:(NSMutableArray *)sortedGroups group:(Group *)group {
	for(Group * child in group._children){
		[sortedGroups addObject:child];
		[self sortGroup:sortedGroups group:child];
	}
}

-(BOOL)emptyString:(NSString *)str{
	return (!str||[str isEqualToString:@""]);
}

-(uint32_t)serializeGroups:(uint8_t *)buffer{
	uint16_t fieldType;
	uint32_t fieldSize;
	//uint8_t  year2999[5] = {0x2E, 0xDF, 0x39, 0x7E, 0xFB};

	uint32_t size=0;
	
	NSMutableArray * sortedGroups = [[NSMutableArray alloc]initWithCapacity:[_groups count]];
	[self sortGroup:sortedGroups group:_rootGroup];
	
	for(Group * group in sortedGroups){
		//calculate the level
		uint16_t level = 0;
		Group * tmp = group;
		while(tmp._parent){
			level++;
			tmp = tmp._parent;
		}
		level--;
		
		//id
		fieldType = 0x0001; fieldSize = 4;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(group._id); buffer+=fieldSize; size+=fieldSize;
		
		
		//title
		if(![self emptyString:group._title]){
			const char * title = [group._title cStringUsingEncoding:NSUTF8StringEncoding];
			fieldType = 0x0002; fieldSize = strlen(title)+1;
			*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
			*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;
			memcpy(buffer, title, fieldSize); buffer+=fieldSize; size+=fieldSize;		
		}
			
		/*
		//creation date
		fieldType = 0x0003; fieldSize = 5;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;
		memcpy(buffer, year2999, fieldSize); buffer+=fieldSize; size+=fieldSize;
		
		//last mod
		fieldType = 0x0004; fieldSize = 5;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;
		memcpy(buffer, year2999, fieldSize); buffer+=fieldSize; size+=fieldSize;
		
		//last access
		fieldType = 0x0005; fieldSize = 5;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;
		memcpy(buffer, year2999, fieldSize); buffer+=fieldSize; size+=fieldSize;
		
		//expire
		fieldType = 0x0006; fieldSize = 5;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;
		memcpy(buffer, year2999, fieldSize); buffer+=fieldSize; size+=fieldSize;
		*/
		
		//image
		fieldType = 0x0007; fieldSize = 4;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(group._image); buffer+=fieldSize; size+=fieldSize;
		
		//level
		fieldType = 0x0008; fieldSize = 2;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;
		*(uint16_t *)buffer = SWAP_INT32_HOST_TO_LE(level); buffer+=fieldSize; size+=fieldSize;
		
		//flags (unused)
		fieldType = 0x0009; fieldSize = 4;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(0); buffer+=fieldSize; size+=fieldSize;

		fieldType = 0xFFFF; fieldSize = 0;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;
				
		//so the size of each group is: 2+4+4 + 2+4 + 4*(2+4+5) + 2+4+4 + 2+4+2 + 2+4+4 +2+4 + title size
		//=94+title size
	}

	[sortedGroups release];
	return size;
}

-(uint32_t)serializeEntries:(NSArray *)entries buffer:(uint8_t *)buffer{
	uint16_t fieldType;
	uint32_t fieldSize;
	uint8_t date[5];
	uint8_t never[5]={0x2E, 0xDF, 0x39, 0x7E, 0XFB};
	
	uint32_t size=0;
	
	for(Entry * entry in entries){
		//uuid
		fieldType = 0x0001; fieldSize = 16;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;
		memcpy(buffer, [entry getUUID], fieldSize); buffer+=fieldSize; size+=fieldSize;
		
		//groupId
		fieldType = 0x0002; fieldSize = 4;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(entry._groupId); buffer+=fieldSize; size+=fieldSize;
		
		//image
		fieldType = 0x0003; fieldSize = 4;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(entry._image); buffer+=fieldSize; size+=fieldSize;
		
		//title
		if(![self emptyString:entry._title]){
			const char * tmp = [entry._title cStringUsingEncoding:NSUTF8StringEncoding];
			fieldType = 0x0004; fieldSize = strlen(tmp)+1;
			*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
			*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
			memcpy(buffer, tmp, fieldSize);buffer+=fieldSize; size+=fieldSize;
		}
			
		//url
		if(![self emptyString:entry._url]){
			const char * tmp = [entry._url cStringUsingEncoding:NSUTF8StringEncoding];
			fieldType = 0x0005; fieldSize = strlen(tmp)+1;	
			*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
			*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
			memcpy(buffer, tmp, fieldSize);buffer+=fieldSize; size+=fieldSize;
		}
		
		//username
		if(![self emptyString:entry._username]){
			const char * tmp = [entry._username cStringUsingEncoding:NSUTF8StringEncoding];
			fieldType = 0x0006; fieldSize = strlen(tmp)+1;
			*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
			*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
			memcpy(buffer, tmp, fieldSize);buffer+=fieldSize; size+=fieldSize;
		}
			
		//password
		if(![self emptyString:entry._password]){
			const char * tmp = [entry._password cStringUsingEncoding:NSUTF8StringEncoding];
			fieldType = 0x0007; fieldSize = strlen(tmp)+1;
			*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
			*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
			memcpy(buffer, tmp, fieldSize);buffer+=fieldSize; size+=fieldSize;
		}
		
		//comment
		if(![self emptyString:entry._comment]){
			const char * tmp = [entry._comment cStringUsingEncoding:NSUTF8StringEncoding];
			fieldType = 0x0008; fieldSize = strlen(tmp)+1;
			*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
			*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
			memcpy(buffer, tmp, fieldSize);buffer+=fieldSize; size+=fieldSize;
		}
		
		//creation
		if(entry._creation){
			fieldType = 0x0009; fieldSize = 5;
			*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
			*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
			[self dateToPacked:entry._creation buffer:date]; 
			memcpy(buffer, date, 5); buffer+=fieldSize; size+=fieldSize;
		}
		
		//last mod
		if(entry._lastMod){
			fieldType = 0x000A; fieldSize = 5;
			*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
			*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
			[self dateToPacked:entry._lastMod buffer:date]; 
			memcpy(buffer, date, 5); buffer+=fieldSize; size+=fieldSize;
		}	
			
		//last access
		if(entry._lastAccess){
			fieldType = 0x000B; fieldSize = 5;
			*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
			*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
			[self dateToPacked:entry._lastAccess buffer:date]; 
			memcpy(buffer, date, 5); buffer+=fieldSize; size+=fieldSize;
		}
		
		//expire
		fieldType = 0x000C; fieldSize = 5;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
		if(entry._expire){
			[self dateToPacked:entry._expire buffer:date]; 
			memcpy(buffer, date, 5); buffer+=fieldSize; size+=fieldSize;
		}else{
			memcpy(buffer, never, 5); buffer+=fieldSize; size+=fieldSize;
		}
		
		//binary desc
		if(![self emptyString:entry._binaryDesc]){
			const char * tmp = [entry._binaryDesc cStringUsingEncoding:NSUTF8StringEncoding];
			fieldType = 0x000D; fieldSize = strlen(tmp)+1;
			*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
			*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
			memcpy(buffer, tmp, fieldSize); buffer+=fieldSize; size+=fieldSize;
		}
		
		//binary
		if([entry getBinary]){
			fieldType = 0x000E; fieldSize = entry._binarySize;
			*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
			*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;		
			memcpy(buffer, [entry getBinary], fieldSize); buffer+=fieldSize; size+=fieldSize;
		}
		
		fieldType = 0xFFFF; fieldSize = 0;
		*(uint16_t *)buffer = SWAP_INT16_HOST_TO_LE(fieldType); buffer+=2; size+=2;
		*(uint32_t *)buffer = SWAP_INT32_HOST_TO_LE(fieldSize); buffer+=4; size+=4;
		
		//so the total size for each entry is: (2+4)*15 + 16 + 4 + 4 + 5*4 + strings + binary = 134 + strings + binary 
	}
	
	return size;
}

-(uint32_t)generateNewGroupId{
	BOOL found = YES;
	uint32_t id=0;
	
	do{
		found=YES;
		id = arc4random();
		if(!id){
			found = NO;
			continue;
		}
		
		for(Group * group in _groups){
			if(group._id == id){
				found = NO;
				break;
			}
		}
	}while(!found);
	return id;
}

#pragma mark -
#pragma mark database delegate

-(Group *)rootGroup{
	return _rootGroup;
}

-(NSArray *)groups{
	return _groups;
}

-(NSArray *)entries{
	return _entries;
}

-(enum DatabaseError)openDatabase:(NSString *)path password:(NSString *)password{
	return [self loadFile:path password:password];
}

-(enum DatabaseError)saveDatabase:(NSString *)path{
	return [self saveFile:path];
}

-(enum DatabaseError)newDatabase:(NSString *)path password:(NSString *)password{
	return [self newFile:path password:password];
}

-(Group *)addGroup:(NSString *)title parent:(Group *)parent{
	Group * group = [[Group alloc]init];

	if(!parent) parent = _rootGroup;

	if(title)
		group._title = title;
	else 
		group._title = @"";
	
	group._id = [self generateNewGroupId];	
	group._parent = parent;

	group._index = [parent._children count];
	[(NSMutableArray *)parent._children addObject:group]; 

	[(NSMutableArray *)_groups addObject:group];
	return[group autorelease];
}

-(Entry *)addEntry:(NSString *)title group:(Group *)group{
	//creating entry in the root group is disallowed
	if(!group||group==_rootGroup) return nil;

	Entry * entry = [[Entry alloc]init];
	
	if(title)
		entry._title = title;
	else 
		entry._title = @"";

	entry._group = group;
	entry._groupId = group._id;

	entry._index = [group._entries count];
	[(NSMutableArray *)group._entries addObject:entry];
	
	
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	NSDateComponents *currentDateComponents = [gregorian components:
											   ( NSDayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:[NSDate date]];	
	[gregorian release];
    
	entry._creation = currentDateComponents;
	entry._lastMod = currentDateComponents;
	entry._lastAccess = currentDateComponents;
	
	//uuid
	uint8_t * uuid = [entry getUUID];
	CFUUIDRef uuidref = CFUUIDCreate(kCFAllocatorDefault);
	CFUUIDBytes bytes = CFUUIDGetUUIDBytes(uuidref);
	memcpy(uuid, &bytes, 16);
	CFRelease(uuidref);	
	[(NSMutableArray *)_entries addObject:entry];
	return [entry autorelease];
}

-(void)deleteEntry:(Entry *)entry group:(Group*)group{
	if(!entry) return;
	
	//adjusting the index of other entries
	for(Entry * e in _entries){
		if(e._group == group && e._index>entry._index){
			e._index = e._index - 1;
		}
	}
	
	entry._group = nil;
	[(NSMutableArray *)group._entries removeObject:entry];
	[(NSMutableArray *)_entries removeObject:entry];
}

-(void)deleteGroup:(Group *)group parent:(Group *)parent{
	//adjust the index of other groups at the same level
	for(Group * g in _groups){
		if(g._parent == parent && g._index > group._index){
			g._index = g._index-1;
		}
	}
	
	[self deleteGroupHelper:group];	
	[(NSMutableArray *)parent._children removeObject:group];	
}

-(void)deleteGroupHelper:(Group *)group{
	if(!group||group==_rootGroup) return; //don't delete rootgroup
	
	for(Group * g in group._children){ 
		[self deleteGroupHelper:g];
	}
	
	for(Entry * e in group._entries){
		[(NSMutableArray *)_entries removeObject:e];
		e._group = nil;
	}	

	group._entries = nil;
	group._parent = nil;		
	[(NSMutableArray *)_groups removeObject:group];
}

@end
