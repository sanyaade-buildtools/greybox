// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Behavior.h"
#import "Engine.h"

@implementation Behavior

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_script = nil;
    
    return self;
}

- (void)dealloc
{
    [m_script release];
    [super dealloc];
}

+ (NSArray*)properties
{
    return [[NSArray arrayWithObjects:
             prop_WIRE(@"name", @selector(setName:)),
             prop_WIRE(@"script", @selector(setScript:)),
             prop_WIRE(@"enabled", @selector(setEnabled:)),
             nil]
            arrayByAddingObjectsFromArray:[super properties]];
}

- (void)setScript:(NSString*)value
{
    Script* script;
    
    // free the current script if it exists
    if (m_script != nil) {
        [m_script release];
    }
    
    // create the script
    if ((script = [[[m_actor script] newThread] autorelease]) == nil) {
        return;
    }
    
    // try and load the script
    if ([script loadScript:value] == FALSE) {
        return;
    }
    
    // save it
    m_script = [script retain];
}

- (Script*)script
{
    return [[m_script retain] autorelease];
}

- (void)start
{
    [m_script call:"start"];
}

- (void)advance
{
    [m_script call:"advance"];
}

- (void)update
{
    [m_script call:"update"];
}

- (void)leave
{
    [m_script call:"leave"];
}

- (void)gui
{
    [m_script call:"ui"];
}

/*
 * LUA INTERFACE
 */

@end
