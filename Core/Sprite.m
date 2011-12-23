// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Atlas.h"
#import "Engine.h"
#import "Sprite.h"
#import "RigidBody.h"
#import "Scanners.h"

@implementation Sprite

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_atlas = nil;
    m_frame = -1UL;
    m_center = NSMakePoint(0.0f, 0.0f);
    m_rgba[0] = 1.0f;
    m_rgba[1] = 1.0f;
    m_rgba[2] = 1.0f;
    m_rgba[3] = 1.0f;
    m_scale = 1.0f;
    m_anim = NULL;
    
    return self;
}

+ (NSArray*)properties
{
    return [[NSArray arrayWithObjects:
             prop_WIRE(@"atlas", @selector(setAtlas:)),
             prop_WIRE(@"frame", @selector(setFrame:)),
             prop_WIRE(@"anim", @selector(playAnim:)),
             prop_WIRE(@"color", @selector(setColor:)),
             prop_WIRE(@"scale", @selector(setScale:)),
             nil]
            arrayByAddingObjectsFromArray:[super properties]];
}

- (NSArray*)scriptMethods
{
    return [[NSArray arrayWithObjects:
             script_Method(@"set_frame", @selector(l_setFrame:)),
             script_Method(@"play_anim", @selector(l_playAnim:)),
             script_Method(@"color", @selector(l_color:)),
             script_Method(@"set_color", @selector(l_setColorTint:)),
             script_Method(@"is_anim_playing", @selector(l_isAnimPlaying:)),
             nil]
            arrayByAddingObjectsFromArray:[super scriptMethods]];
}

- (void)setAtlas:(NSString*)value
{
    m_atlas = [theProject assetWithName:value type:[Atlas class]];
}

- (void)setFrame:(NSString*)value
{
    m_frame = [m_atlas frameNamed:value];
}

- (void)playAnim:(NSString*)value
{
    m_anim = [m_atlas animNamed:value];
    m_duration = 0.0f;
}

- (BOOL)isAnimPlaying
{
    return m_anim != NULL;
}

- (void)setColor:(NSString*)value
{
    NSColor* color = [value colorValue];
    
    // assign the color values
    m_rgba[0] = [color redComponent];
    m_rgba[1] = [color greenComponent];
    m_rgba[2] = [color blueComponent];
    m_rgba[3] = [color alphaComponent];
}

- (void)setScale:(NSString*)value
{
    m_scale = [value floatValue];
}

- (BOOL)isCulled
{
    return FALSE;
}

- (void)advance
{
    if (m_anim != NULL) {
        int frames = m_duration * m_anim->fps;
        
        // calculate what frame we should be on now
        m_frame = m_anim->frame + (frames % m_anim->len);
        
        // stop the animation now if it's not looping
        if (frames >= m_anim->len && m_anim->looping == NO) {
            // stop on the last frame
            m_frame = m_anim->frame + m_anim->len - 1;
            
            // stop animating
            m_anim = NULL;
        }
        
        // advance how long this animation's been playing for
        m_duration += [theClock deltaTime];
    }
}

- (void)render
{
    glColor4fv(m_rgba);
    
    // temporarily store state
    glPushMatrix();
    {
        glScalef(m_scale, m_scale, 1.0f);
    
        // render the curren frame
        [m_atlas render:m_frame];
    }
    glPopMatrix();
}

/*
 * LUA INTERFACE
 */

- (int)l_setFrame:(lua_State*)L
{
    NSString* name;
    
    // attempt to get the name of the texture asset
    if ((name = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return 0;
    }
    
    return [self setFrame:name], 0;
}

- (int)l_playAnim:(lua_State*)L
{
    NSString* name;
    
    // attempt to get the name of the texture asset
    if ((name = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return 0;
    }
    
    return [self playAnim:name], 0;
}

- (int)l_color:(lua_State*)L
{
    NSDictionary* color = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithFloat:m_rgba[0]], @"r",
                           [NSNumber numberWithFloat:m_rgba[1]], @"g",
                           [NSNumber numberWithFloat:m_rgba[2]], @"b",
                           [NSNumber numberWithFloat:m_rgba[3]], @"a",
                           nil];
     
    if ([Script push:color to:L] == FALSE) {
        lua_pushnil(L);
    }
    
    return 1;
}

- (int)l_setColorTint:(lua_State*)L
{
    if (lua_istable(L, 1)) {
        // fetch all the optional field values
        lua_getfield(L, 1, "r");
        lua_getfield(L, 1, "g");
        lua_getfield(L, 1, "b");
        lua_getfield(L, 1, "a");
        
        // update the color value if present
        m_rgba[0] = lua_isnumber(L, 2) ? lua_tonumber(L, 2) : m_rgba[0];
        m_rgba[1] = lua_isnumber(L, 3) ? lua_tonumber(L, 3) : m_rgba[1];
        m_rgba[2] = lua_isnumber(L, 4) ? lua_tonumber(L, 4) : m_rgba[2];
        m_rgba[3] = lua_isnumber(L, 5) ? lua_tonumber(L, 5) : m_rgba[3];
    }
    
    return 0;
}

- (int)l_isAnimPlaying:(lua_State*)L
{
    return lua_pushboolean(L, [self isAnimPlaying]), 1;
}

@end
