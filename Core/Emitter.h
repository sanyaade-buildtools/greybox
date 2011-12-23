// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Atlas.h"
#import "Component.h"

typedef struct {
    float x;
    float y;
    float dirx;
    float diry;
    float rotx;
    float roty;
    float age;
    float lifetime;
    float scale;
    float speed;
    float angularVel;
    float tangentialAccelX;
    float tangentialAccelY;
    float radialAccelX;
    float radialAccelY;
    float r;
    float g;
    float b;
    float a;
} Particle;

@interface Emitter : BaseComponent <ComponentInterface>
{
    // texture used to render particles
    Atlas* m_atlas;
    
    // frame for the particle
    unsigned long m_frame;
    
    // settings for the emitter
    float m_rate;
    float m_lifetime;
    float m_age;
    float m_particleLifeMin;
    float m_particleLifeMax;
    float m_angle;
    float m_spread;
    float m_speedMin;
    float m_speedMax;
    float m_angularVelocityMin;
    float m_angularVelocityMax;
    float m_radialAccelMin;
    float m_radialAccelMax;
    float m_tangentialAccelMin;
    float m_tangentialAccelMax;
    float m_startScale;
    float m_endScale;
    
    // initial and ending colors for particles
    NSColor* m_startColor;
    NSColor* m_endColor;
    
    // position offset from the actor
    NSPoint m_pos;
    
    // gravitational direction of particle float
    NSPoint m_gravity;
    
    // true while the emitter is active
    BOOL m_active;
    
    // total number of particles ever emitted and active
    unsigned int m_total;
    unsigned int m_count;
    
    // fixed-buffer of particles
    Particle m_particles[500];
}

// true if currently emitting particles
- (BOOL)isActive;

// current number of live particles
- (unsigned int)particleCount;

// false if not active and no particles
- (BOOL)isRunning;

// force emit particles
- (void)emit:(int)n;

// start and stop the emitter
- (void)startEmitter;
- (void)stopEmitter;

@end
