//
//   ArcFour.h
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

#import "ArcFour.h"

@implementation ArcFour

-(void)dealloc{
	if(_rawKey){
		free(_rawKey);
		_rawKeyLength = 0;
	}
	[super dealloc];
}

-(void)setKey:(uint8_t *)key withLength:(uint32_t)length{
	if(_rawKey){
		free(_rawKey);
		_rawKeyLength = 0;
	}
	
	_rawKeyLength = length;
	_rawKey = malloc(_rawKeyLength);
	memcpy(_rawKey, key, length);
}

-(void)encrypt:(uint8_t *)src withLength:(uint32_t)length{
	uint8_t S[256], tmp;
	uint32_t i, j;	
	
	//KSA
	for(i=0; i<256; i++) S[i]=(uint8_t)i;
	
	for(i=j=0; i<256; i++){
		j = (j + _rawKey[i%_rawKeyLength] + S[i]) & 0xFF;
		tmp = S[i]; S[i] = S[j]; S[j] = tmp; 
	}
	
	//PRGA
	uint32_t index;

	uint8_t * backup = malloc(length);
	memcpy(backup, src, length);

	i=0; j=0;
	
	for(index=0; index<length; index++){
		i = (i + 1) & 0xFF;
		j = (j + S[i] ) & 0xFF;
		tmp = S[i]; S[i] = S[j]; S[j] = tmp;
		tmp = (S[i] + S[j])&0xFF;
		src[index] = backup[index] ^ S[tmp];
	}
	
	free(backup);
}

@end
