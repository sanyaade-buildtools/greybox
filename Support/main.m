// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Engine.h"

#define ASTEROIDS @"/Users/jeff/Projects/asteroids/DerivedData/asteroids/Build/Products/Debug/asteroids.bundle"

int main(int argc, char *argv[])
{
    NSString* bundle;
    
    //if (argc < 2) {
        bundle = ASTEROIDS;
    //} else {
    //    bundle = [[NSString alloc] initWithUTF8String:argv[1]];
    //}
    
    [Engine launchWithProject:bundle];
    [bundle release];
}
