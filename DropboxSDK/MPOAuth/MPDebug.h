//
//  MPDebug.h
//  MPOAuthConnection
//
//  Created by Karl Adam on 09.02.06.
//  Copyright 2009 matrixPointer. All rights reserved.
//

#ifdef DEBUG
	#define MPLog(...) NSLog(__VA_ARGS__)
#else
	#define MPLog(...) do { } while (0)
#endif
