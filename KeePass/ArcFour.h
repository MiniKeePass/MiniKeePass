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

#import <Foundation/Foundation.h>


@interface ArcFour : NSObject {
	uint8_t * _rawKey;
	uint32_t _rawKeyLength;
}

-(void) setKey:(uint8_t *)key withLength:(uint32_t)length;
-(void) encrypt:(uint8_t *)src withLength:(uint32_t)length;

@end
