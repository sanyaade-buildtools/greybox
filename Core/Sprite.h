// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Atlas.h"
#import "Component.h"
#import "Script.h"

@interface Sprite : BaseComponent <ComponentInterface>
{
    // the texture atlas used
    Atlas* m_atlas;
    
    // the frame number to render
    unsigned long m_frame;
    
    // the currently playing animation (or NULL)
    const AnimSeq* m_anim;
    
    // how long the current animation's been playing
    float m_duration;
    
    // render state
    float m_rgba[4];
    float m_scale;
    
    // the center of the sprite - around which it will rotate
    NSPoint m_center;
}

// set the frame to render
- (void)setFrame:(NSString*)name;
- (void)playAnim:(NSString*)name;

// animation predicates
- (BOOL)isAnimPlaying;

// returns true if the sprite is culled off screen (or hidden)
- (BOOL)isCulled;

@end
