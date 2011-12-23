// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Actor.h"
#import "Collider.h"

@interface World : NSObject <ScriptInterface>
{
	cpSpace* m_space;
    
    // post-step frame callback for shape/body removal
    NSMutableArray* m_shapeRemovalQueue;
    NSMutableArray* m_bodyRemovalQueue;
}

// called by the world simulation after stepping - DO NOT CALL DIRECTLY!
- (void)removeShapesAndBodies;

// add and remove rigid bodies from the world
- (void)addRigidBody:(Actor*)actor;
- (void)removeRigidBody:(Actor*)actor;

// add and remove collider shapes from the world
- (void)addCollider:(Collider*)collider;
- (void)removeCollider:(Collider*)collider;

// collision handlers - DO NOT CALL DIRECTLY!
- (BOOL)beginCollision:(struct cpArbiter*)arbiter;
- (void)endCollision:(struct cpArbiter*)arbiter;

// events from the scene
- (void)step:(float)deltaTime;

@end
