// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Network.h"

@implementation Network

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    
    return self;
}

- (NSDictionary*)scriptMethods
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            nil];
}

/*
 * LUA INTERFACE
 */

@end
