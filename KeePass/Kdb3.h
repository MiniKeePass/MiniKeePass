//
//   Kdb3.h
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
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

#import "Database.h"

#define KDB3_SIG1 (0x9AA2D903)
#define KDB3_SIG2 (0xB54BFB65)

#define FLAG_SHA2	1
#define FLAG_RIJNDAEL 2
#define FLAG_ARCFOUR  4
#define FLAG_TWOFISH  8

#define KDB3_VER  (0x00030002)
#define KDB3_HEADER_SIZE (124)

@interface Kdb3:NSObject<Database>{
	enum CryptAlgorithm _algorithm;
	uint8_t _transfRandomSeed[32];
	uint8_t _masterKey[32];
	uint32_t _keyTransfRounds;
	Group * _rootGroup;
	NSArray * _groups;
	NSArray * _entries;
	NSArray * _ignoredEntries;
}

@end



