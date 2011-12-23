// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Actor.h"
#import "Engine.h"
#import "Scene.h"

@implementation Scene

- (id)initWithScript:(Script*)script
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_layers = [[NSMutableArray alloc] init];
    m_script = [script retain];
    
    // initialize the script methods for the scene
    [m_script registerObject:self withNamespace:nil];
    
    return self;
}

- (void)dealloc
{
    [m_layers release];
    [m_script release];
    [super dealloc];
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"add_layer", @selector(l_addLayer:)),
            script_Method(@"find_layer", @selector(l_findLayer:)),
            nil];
}

- (Script*)script
{
    return [[m_script retain] autorelease];
}

- (void)start
{
    // called for the initial state
    [m_script call:"start"];
}

- (void)advance
{
    // advance the current state
    [m_script call:"advance"];
    
    // advance all the actors in the scene
    [m_layers makeObjectsPerformSelector:@selector(advance)];
}

- (void)render
{
    // render layers, which will render all actors
    [m_layers makeObjectsPerformSelector:@selector(render)];
}

- (void)update
{
    // update layers, which will remove actors
    [m_layers makeObjectsPerformSelector:@selector(update)];
    
    // end of frame processing of stuff
    [m_script call:"update"];
}

- (void)leave
{
    // make all the layers leave and remove them
    [m_layers makeObjectsPerformSelector:@selector(leave)];
    [m_layers removeAllObjects];
    
    // finally post-scene processing
    [m_script call:"leave"];
}

- (void)gui
{
    // render gui elements for the state
    [m_script call:"ui"];
    
    // render the gui for each layer in order
    [m_layers makeObjectsPerformSelector:@selector(gui)];
}

/*
 * LUA INTERFACE
 */

- (int)l_addLayer:(lua_State*)L
{
    float z;
    NSString* name;
    Layer* layer;
    
    // get the name of the layer
    if ((name = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return lua_pushnil(L), 1;
    }
    
    // get the z-ordering for the layer (default=# of layers)
    if (lua_gettop(L) >= 2) {
        z = lua_tonumber(L, 2);
    } else {
        z = [m_layers count];
    }
    
    // create the layer
    if ((layer = [[Layer alloc] initWithName:name zOrdering:z]) == nil) {
        return lua_pushnil(L), 1;
    }
    
    // add the layer and resort all the layers
    [m_layers addObject:[layer autorelease]];
    [m_layers sortUsingSelector:@selector(orderWith:)];
    
    // fetch the child thread from our registry, get its environment
    lua_rawgeti(L, LUA_REGISTRYINDEX, [[layer script] ref]);
    lua_getfenv(L, -1);
    
    return 1;
}

- (int)l_findLayer:(lua_State*)L
{
    NSString* name;
    
    // get the name of the layer
    if ((name = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return lua_pushnil(L), 1;
    }
    
    // search for a layer with that name
    for(Layer* layer in m_layers) {
        if ([[layer name] isEqualToString:name]) {
            return [[layer script] pushEnvTo:L], 1;
        }
    }
    
    // not found
    return lua_pushnil(L), 1;
}

@end
