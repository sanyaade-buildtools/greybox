// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "chipmunk.h"
#import "Prefab.h"
#import "Script.h"

@interface Actor : NSObject <ScriptInterface>
{
    NSString* m_name;
    
    // root lua state object
    Script* m_script;
    
    // true when the actor should be removed
    BOOL m_dead;
    
    // every actor is a rigid body (for the transform)
	cpBody* m_body;
    
    // physics properties
    BOOL m_trigger;
    BOOL m_kinematic;
    
    // attached list of components and tags
    NSMutableArray* m_components;
    NSMutableSet* m_tags;
    
    // true if the actor should render itself
    BOOL m_visible;
}

// create a new actor from a prefab
+ (Actor*)actorFromPrefab:(NSString*)name;

// initialization methods
- (id)initWithPrefab:(Prefab*)prefab;

// set the name of the actor (optional)
- (void)setName:(NSString*)name;

// get the optional name of the actor
- (NSString*)name;

// true if should be removed from the scene
- (BOOL)isDead;

// call when the actor should be removed from the scene
- (void)kill;

// true if a given tag name is present on the actor
- (BOOL)hasTag:(NSString*)tag;

// accessors
- (Script*)script;
- (cpBody*)body;

// tagging
- (void)addTag:(NSString*)tag;
- (void)removeTag:(NSString*)tag;

// physics property writers, setup by the RigidBody component
- (void)setIsTrigger:(BOOL)flag;
- (void)setIsKinematic:(BOOL)flag;

// physics properties
- (BOOL)isTrigger;
- (BOOL)isKinematic;

// position and rotation
- (float)angle;
- (float)x;
- (float)y;

// transform application
- (void)applyTransform;
- (void)loadTransform;

// transform and/or rotate a point
- (NSPoint)transformPoint:(NSPoint)point;
- (NSPoint)rotatePoint:(NSPoint)point;

// transform methods
- (void)setPosition:(NSPoint)point;
- (void)setAngle:(float)degrees;

// translate and rotate
- (void)translateBy:(NSPoint)delta global:(BOOL)global;
- (void)rotateBy:(float)degrees;

// set to false to disable rendering and component rendering
- (void)setVisible:(BOOL)flag;

// true if the actor should render itself
- (BOOL)isVisible;

// frame stages
- (void)start;
- (void)advance;
- (void)render;
- (void)update;
- (void)leave;
- (void)gui;

// collision handlers
- (BOOL)beginCollision:(Actor*)actor;
- (void)endCollision:(Actor*)actor;

@end
