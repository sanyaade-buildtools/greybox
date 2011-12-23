// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Engine.h"
#import "Layer.h"

@implementation Layer

- (id)initWithName:(NSString*)name zOrdering:(float)z
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_actors = [[NSMutableArray alloc] init];
    m_newActors = [[NSMutableArray alloc] init];
    m_script = [[theScene script] newThread];
    m_name = [name retain];
    m_backdrop = nil;
    m_z = z;
    
    // add functionality to the layer script - NOT IN A NAMESPACE!
    [m_script registerObject:self withNamespace:nil];
    
    return self;
}

- (void)dealloc
{
    [m_name release];
    [m_actors release];
    [m_newActors release];
    [m_script release];
    [super dealloc];
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"set_backdrop", @selector(l_setBackdrop:)),
            script_Method(@"spawn", @selector(l_spawn:)),
            script_Method(@"actors", @selector(l_actors:)),
            script_Method(@"find_actors", @selector(l_findActors:)),
            nil];
}

- (NSString*)name
{
    return [[m_name retain] autorelease];
}

- (NSArray*)actors
{
    return [[m_actors retain] autorelease];
}

- (Script*)script
{
    return [[m_script retain] autorelease];
}

 -(Texture*)backdrop
{
    return [[m_backdrop retain] autorelease];
}

- (float)z
{
    return m_z;
}

- (void)setBackdrop:(Texture*)texture
{
    m_backdrop = texture;
}

- (Actor*)spawnActorWithPrefab:(Prefab*)prefab
{
    Actor* actor;
    
    // create the actor
    if ((actor = [[[Actor alloc] initWithPrefab:prefab] autorelease]) == nil) {
        return nil;
    }
    
    // add it to the list of actors to come in at the end of the scene
    [m_newActors addObject:actor];
    
    return [[actor retain] autorelease];
}

- (NSComparisonResult)orderWith:(Layer*)layer
{
    if (m_z < [layer z]) {
        return NSOrderedAscending;
    } else if (m_z > [layer z]) {
        return NSOrderedDescending;
    }
    
    return NSOrderedSame;
}

- (void)advance
{
    [m_actors makeObjectsPerformSelector:@selector(advance)];
}

- (void)render
{
    // render the backdrop if there is one
    if (m_backdrop != nil) {
        [m_backdrop render];
    }
    
    // render all the actors
    [m_actors makeObjectsPerformSelector:@selector(render)];
}

- (void)update
{
    NSArray* newFrameActors = [NSArray arrayWithArray:m_newActors];
    
    // get rid of all the new actors (so we can spawn new ones)
    [m_newActors removeAllObjects];
    
	// remove all components tied to dead actors from the scene
	for(int i = (int)[m_actors count] - 1;i >= 0;i--) {
        Actor* actor = [m_actors objectAtIndex:i];
        
		if ([actor isDead] == NO) {
			continue;
		}
        
        // tell it to remove itself from the scene
        [actor leave];
		
		// swap with the last actor for O(1) removal
        if (i < [m_actors count] - 1) {
            [m_actors replaceObjectAtIndex:i++ withObject:[m_actors lastObject]];
        }
        
        // delete it from the list
		[m_actors removeLastObject];
	}
    
	// update the actors still alive
	[m_actors makeObjectsPerformSelector:@selector(update)];
	
	// add all new actors to the scene
	[m_actors addObjectsFromArray:newFrameActors];
	
	// start all new actors and flush the buffer
	[newFrameActors makeObjectsPerformSelector:@selector(start)];
}

- (void)gui
{
    [m_actors makeObjectsPerformSelector:@selector(gui)];
}

/*
 * LUA INTERFACE
 */

- (int)l_setBackdrop:(lua_State*)L
{
    NSString* name;
    
    // get the name of the texture
    if ((name = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return 0;
    }
    
    // get the texture from the project
    [self setBackdrop:[theProject assetWithName:name type:[Texture class]]];
    
    return 0;
}

- (int)l_spawn:(lua_State*)L
{
    NSString* name;
    Actor* actor;
    Prefab* prefab;
    
    // pull the filename from the script
    if ((name = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return lua_pushnil(L), 1;
    }
    
    // lookup the prefab asset in the project
    if ((prefab = [theProject assetWithName:name type:[Prefab class]]) == nil) {
        NSLog(@"Prefab %@ not loaded or doesn't exist\n", name);
        return lua_pushnil(L), 1;
    }
    
    // instantiate the actor
    if ((actor = [self spawnActorWithPrefab:prefab]) == nil) {
        NSLog(@"Error spawning actor prefab %@\n", name);
        return lua_pushnil(L), 1;
    }
    
    // set the name of the actor to that of the prefab
    [actor setName:name];
    
    // register this layer (special) and save the environment on the stack
    [[actor script] registerObject:self withNamespace:@"layer"];
    [[actor script] pushEnvTo:L];
    
    return 1;
}

- (int)l_actors:(lua_State*)L
{
    lua_newtable(L);
    
    // loop over each actor and push it onto the table
    for(unsigned long i = 0;i < [m_actors count];i++) {
        Actor* actor = [m_actors objectAtIndex:i];
        
        // add it to the table
        lua_pushnumber(L, i + 1);
        {
            [[actor script] pushEnvTo:L];
        }
        lua_rawset(L, -3);
    }
    
    return 1;
}

- (int)l_findActors:(lua_State*)L
{
    NSString* tag;
    int i = 0;
    
    // get the name of the layer
    if ((tag = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return lua_pushnil(L), 1;
    }
    
    lua_newtable(L);
    
    // loop over every actor
    for(Actor* actor in [self actors]) {
        if ([actor hasTag:tag] == NO) {
            continue;
        }
        
        // add this actor's environment to the array
        lua_pushnumber(L, ++i);
        {
            [[actor script] pushEnvTo:L];
        }
        lua_settable(L, -3);
    }
    
    return 1;
}

@end
