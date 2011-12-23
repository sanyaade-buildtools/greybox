// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Actor.h"

// property object used to set component values
@interface Property : NSObject
@property (readwrite,assign) NSString* value;
@property (readwrite,assign) SEL sel;
@end

@interface BaseComponent : NSObject
{
    Actor* m_actor;
    
    // optionally used to create script instance
    NSString* m_name;
    
    // true if the component is active
    BOOL m_enabled;
}

// returns the component subclass for a given string
+ (Class)componentInterfaceForName:(NSString*)name;

// create a wired property
+ (Property*)wireProperty:(NSString*)value to:(SEL)sel;

// initialization methods
- (id)initWithActor:(Actor*)actor properties:(NSArray*)props;

// accessors
- (NSString*)name;
- (Actor*)actor;

// wiring for prefab component properties
+ (NSArray*)properties;

// methods that all components share
- (NSArray*)scriptMethods;

// toggle enabled flag
- (void)enable;
- (void)disable;

// true if this behavior should run
- (BOOL)isEnabled;

// frame stages
- (void)start;
- (void)advance;
- (void)render;
- (void)update;
- (void)leave;
- (void)gui;

@end

// instantiatable components must adhere to this interface
@protocol ComponentInterface <ScriptInterface>
@end

// helper macro for component classes
#define component_CLASS(cls) [NSValue valueWithPointer:[cls class]]

// helper macro to create property wirings
#define prop_WIRE(value,sel) [BaseComponent wireProperty:value to:sel]