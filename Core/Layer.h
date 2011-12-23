// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Actor.h"
#import "Script.h"
#import "Texture.h"

@interface Layer : NSObject <ScriptInterface>
{
    NSString* m_name;
    
    // namespace for actors
    Script* m_script;
    
    // backdrop texture
    Texture* m_backdrop;
    
    // current and pending actors
    NSMutableArray* m_actors;
    NSMutableArray* m_newActors;
    
    // layer ordering
    float m_z;
}

// initialization methods
- (id)initWithName:(NSString*)name zOrdering:(float)z;

// accessors
- (NSString*)name;
- (NSArray*)actors;
- (Script*)script;
- (Texture*)backdrop;
- (float)z;

// set the backdrop for this layer
- (void)setBackdrop:(Texture*)texture;

// spawn a new actor
- (Actor*)spawnActorWithPrefab:(Prefab*)prefab;

// determine sort ordering
- (NSComparisonResult)orderWith:(Layer*)layer;

// frame stages
- (void)advance;
- (void)render;
- (void)update;
- (void)gui;

@end
