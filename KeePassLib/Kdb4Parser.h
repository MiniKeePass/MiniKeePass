//
//  Kdb4Parser.h
//  KeePass2
//
//  Created by Qiang Yu on 2/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>
#import "Stack.h"
#import "Tree.h"
#import "DataSource.h"
#import "RandomStream.h"

@interface Kdb4Parser : NSObject{
	Stack * _stack;
	Tree * _tree;	
	id<RandomStream> _randomStream; //to decode protected value
}

@property(nonatomic, retain) id<RandomStream> _randomStream;
@property(nonatomic, readonly) Stack * _stack;
@property(nonatomic, retain) Tree * _tree;
-(Tree *)parse:(id<InputDataSource>)input;
@end
