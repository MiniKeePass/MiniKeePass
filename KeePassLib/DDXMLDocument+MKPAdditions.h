//
//  DDXMLDocument+MKPAdditions.h
//  MiniKeePass
//
//  Created by Jason Rush on 9/15/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "DDXMLDocument.h"

@interface DDXMLDocument (MKPAdditions)

- (id)initWithReadIO:(xmlInputReadCallback)ioread closeIO:(xmlInputCloseCallback)ioclose context:(void*)ioctx options:(NSUInteger)mask error:(NSError **)error;

@end
