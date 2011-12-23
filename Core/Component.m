// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Behavior.h"
#import "CircleCollider.h"
#import "Component.h"
#import "Emitter.h"
#import "RigidBody.h"
#import "SegmentCollider.h"
#import "Sprite.h"

@implementation Property
@synthesize value;
@synthesize sel;

- (void)dealloc
{
    [value release];
    [super dealloc];
}
@end

@implementation BaseComponent

+ (Class)componentInterfaceForName:(NSString*)name
{
    NSDictionary* classes = [NSDictionary dictionaryWithObjectsAndKeys:
                             component_CLASS(CircleCollider), @"circlecollider",
                             component_CLASS(Emitter), @"emitter",
                             component_CLASS(RigidBody), @"rigidbody",
                             component_CLASS(SegmentCollider), @"segmentcollider",
                             component_CLASS(Sprite), @"sprite",
                             component_CLASS(Behavior), @"behavior",
                             nil];
    
    // find the class name in the dictionary and return it
    return [[classes objectForKey:[name lowercaseString]] pointerValue];
}

- (id)initWithActor:(Actor*)actor properties:(NSArray*)props
{
    if ((self = [self init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_actor = actor;
    m_enabled = YES;
    
    // wire in all the property values
    for(Property* prop in props) {
        [self performSelector:prop.sel
                   withObject:prop.value];
    }
    
    return self;
}

- (void)dealloc
{
    [m_name release];
    [super dealloc];
}

+ (Property*)wireProperty:(NSString*)value to:(SEL)sel
{
    Property* prop = [[Property alloc] init];
    
    // initialize the property
    prop.value = [value retain];
    prop.sel = sel;
    
    return [prop autorelease];
}

- (NSString*)name
{
    return [[m_name retain] autorelease];
}

- (Actor*)actor
{
    return [[m_actor retain] autorelease];
}

+ (NSArray*)properties
{
    return [NSArray arrayWithObjects:
            prop_WIRE(@"name", @selector(setName:)),
            prop_WIRE(@"enabled", @selector(setEnabled:)),
            nil];
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"set_enabled", @selector(l_setEnabled:)),
            script_Method(@"is_enabled", @selector(l_isEnabled:)),
            script_Method(@"enable", @selector(l_enable:)),
            script_Method(@"disable", @selector(l_disable:)),
            nil];
}

- (void)setName:(NSString*)value
{
    m_name = [value retain];
}

- (void)setEnabled:(NSString*)value
{
    m_enabled = [value boolValue];
}

- (void)enable
{
    m_enabled = YES;
}

- (void)disable
{
    m_enabled = NO;
}

- (BOOL)isEnabled
{
    return m_enabled;
}

- (void)start
{
    // subclass responsibility
}

- (void)advance
{
    // subclass responsibility
}

- (void)render
{
    // subclass responsibility
}

- (void)update
{
    // subclass responsibility
}

- (void)leave
{
    // subclass responsibility
}

- (void)gui
{
    // subclass responsibility
}

/*
 * LUA INTERFACE
 */

- (int)l_setEnabled:(lua_State*)L
{
    if (lua_toboolean(L, 1) == FALSE) {
        [self disable];
    } else {
        [self enable];
    }
    
    return 0;
}

- (int)l_isEnabled:(lua_State*)L
{
    return lua_pushboolean(L, [self isEnabled]), 1;
}

- (int)l_enable:(lua_State*)L
{
    return [self enable], 0;
}

- (int)l_disable:(lua_State*)L
{
    return [self disable], 0;
}

@end
