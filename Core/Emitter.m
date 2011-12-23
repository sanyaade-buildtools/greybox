// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Engine.h"
#import "Emitter.h"
#import "Scanners.h"

@implementation Emitter

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // default particle color
    NSColor* white = [NSColor colorWithDeviceRed:1.0f 
                                           green:1.0f 
                                            blue:1.0f 
                                           alpha:1.0f];
    
    // initialize members
    m_atlas = nil;
    m_frame = -1UL;
    m_rate = 10.0f;
    m_lifetime = NAN;
    m_age = 0.0f;
    m_particleLifeMin = 2.0f;
    m_particleLifeMax = 2.0f;
    m_angle = 0.0f;
    m_spread = 360.0f;
    m_speedMin = 0.0f;
    m_speedMax = 0.0f;
    m_angularVelocityMin = 0.0f;
    m_angularVelocityMax = 0.0f;
    m_radialAccelMin = 0.0f;
    m_radialAccelMax = 0.0f;
    m_tangentialAccelMin = 0.0f;
    m_tangentialAccelMax = 0.0f;
    m_active = NO;
    m_total = 0;
    m_count = 0;
    m_pos = NSMakePoint(0.0f, 0.0f);
    m_gravity = NSMakePoint(0.0f, 0.0f);
    m_startColor = [white retain];
    m_endColor = [white retain];
    m_startScale = 1.0f;
    m_endScale = 1.0f;
    
    return self;
}

- (void)dealloc
{
    [m_startColor release];
    [m_endColor release];
    [super dealloc];
}

+ (NSArray*)properties
{
    return [[NSArray arrayWithObjects:
             prop_WIRE(@"atlas", @selector(setAtlas:)),
             prop_WIRE(@"frame", @selector(setFrame:)),
             prop_WIRE(@"active", @selector(setActive:)),
             prop_WIRE(@"rate", @selector(setRate:)),
             prop_WIRE(@"lifetime", @selector(setLifetime:)),
             prop_WIRE(@"minparticlelife", @selector(setMinLife:)),
             prop_WIRE(@"maxparticlelife", @selector(setMaxLife:)),
             prop_WIRE(@"x", @selector(setX:)),
             prop_WIRE(@"y", @selector(setY:)),
             prop_WIRE(@"angle", @selector(setAngle:)),
             prop_WIRE(@"spread", @selector(setSpread:)),
             prop_WIRE(@"minspeed", @selector(setMinSpeed:)),
             prop_WIRE(@"maxspeed", @selector(setMaxSpeed:)),
             prop_WIRE(@"minangularvelocity", @selector(setMinAngularVelocity:)),
             prop_WIRE(@"maxangularvelocity", @selector(setMaxAngularVelocity:)),
             prop_WIRE(@"minradialaccel", @selector(setMinRadialAccel:)),
             prop_WIRE(@"maxradialaccel", @selector(setMaxRadialAccel:)),
             prop_WIRE(@"mintangentialaccel", @selector(setMinTangentialAccel:)),
             prop_WIRE(@"maxtangentialaccel", @selector(setMaxTangentialAccel:)),
             prop_WIRE(@"gravityx", @selector(setGravityX:)),
             prop_WIRE(@"gravityy", @selector(setGravityY:)),
             prop_WIRE(@"startcolor", @selector(setStartColor:)),
             prop_WIRE(@"endcolor", @selector(setEndColor:)),
             prop_WIRE(@"startscale", @selector(setStartScale:)),
             prop_WIRE(@"endscale", @selector(setEndScale:)),
             nil]
            arrayByAddingObjectsFromArray:[super properties]];
}

- (NSArray*)scriptMethods
{
    return [[NSArray arrayWithObjects:
             script_Method(@"start", @selector(l_start:)),
             script_Method(@"stop", @selector(l_stop:)),
             script_Method(@"is_active", @selector(l_isActive:)),
             script_Method(@"particle_count", @selector(l_particleCount:)),
             script_Method(@"is_running", @selector(l_isRunning:)),
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

- (void)setActive:(NSString*)value
{
    m_active = [value boolValue];
}

- (void)setLifetime:(NSString*)value
{
    if ([value isCaseInsensitiveLike:@"infinite"]) {
        m_lifetime = NAN;
    } else if ([value isCaseInsensitiveLike:@"one shot"]) {
        m_lifetime = 0;
    } else {
        m_lifetime = [value floatValue];
    }
}

- (void)setRate:(NSString*)value
{
    m_rate = [value floatValue];
}

- (void)setMinLife:(NSString*)value
{
    m_particleLifeMin = [value floatValue];
}

- (void)setMaxLife:(NSString*)value
{
    m_particleLifeMax = [value floatValue];
}

- (void)setX:(NSString*)value
{
    m_pos.x = [value floatValue];
}

- (void)setY:(NSString*)value
{
    m_pos.y = [value floatValue];
}

- (void)setAngle:(NSString*)value
{
    m_angle = fmodf([value floatValue], 360.0f);
}

- (void)setSpread:(NSString*)value
{
    m_spread = [value floatValue];
}

- (void)setMinSpeed:(NSString*)value
{
    m_speedMin = [value floatValue];
}

- (void)setMaxSpeed:(NSString*)value
{
    m_speedMax = [value floatValue];
}

- (void)setMinAngularVelocity:(NSString*)value
{
    m_angularVelocityMin = [value floatValue];
}

- (void)setMaxAngularVelocity:(NSString*)value
{
    m_angularVelocityMax = [value floatValue];
}

- (void)setMinRadialAccel:(NSString*)value
{
    m_radialAccelMin = [value floatValue];
}

- (void)setMaxRadialAccel:(NSString*)value
{
    m_radialAccelMax = [value floatValue];
}

- (void)setMinTangentialAccel:(NSString*)value
{
    m_tangentialAccelMin = [value floatValue];
}

- (void)setMaxTangentialAccel:(NSString*)value
{
    m_tangentialAccelMax = [value floatValue];
}

- (void)setGravityX:(NSString*)value
{
    m_gravity.x = [value floatValue];
}

- (void)setGravityY:(NSString*)value
{
    m_gravity.y = [value floatValue];
}

- (void)setStartColor:(NSString*)value
{
    if (m_startColor != nil) {
        [m_startColor release];
    }
    
    // parse the color
    m_startColor = [[value colorValue] retain];
}

- (void)setEndColor:(NSString*)value
{
    if (m_endColor != nil) {
        [m_endColor release];
    }
    
    // parse the color
    m_endColor = [[value colorValue] retain];
}

- (void)setStartScale:(NSString*)value
{
    m_startScale = [value floatValue];
}

- (void)setEndScale:(NSString*)value
{
    m_endScale = [value floatValue];
}

- (BOOL)isActive
{
    return m_active;
}

- (unsigned int)particleCount
{
    return m_count;
}

- (BOOL)isRunning
{
    return m_active || m_count > 0;
}

- (void)emit:(int)n
{
    int i;
    
    // emit each particle
    for(i = 0;i < n && m_count < sizeof(m_particles) / sizeof(m_particles[0]);i++) {
        Particle* p = &m_particles[m_count++];
        
#       define randr(m,n) ((m) + (((n) - (m)) * [[theEngine random] uniform]))
        {
            float rot = randr(0.0f, 360.0f);
            float angle = [m_actor angle] + randr(-m_spread, m_spread);
            float tangentialAccel = randr(m_tangentialAccelMin, m_tangentialAccelMax);
            float radialAccel = randr(m_radialAccelMin, m_radialAccelMax);
            
            // use the position of the actor, offset
            NSPoint position = [m_actor transformPoint:m_pos];
            
            // initialize the particle
            p->age = 0.0f;
            p->lifetime = randr(m_particleLifeMin, m_particleLifeMax);
            p->x = position.x;
            p->y = position.y;
            p->speed = randr(m_speedMin, m_speedMax);
            p->dirx = cosf(angle * 3.141592f / 180.0f);
            p->diry = sinf(angle * 3.141592f / 180.0f);
            p->rotx = cosf(rot * 3.141592f / 180.0f);
            p->roty = sinf(rot * 3.141592f / 180.0f);
            p->angularVel = randr(m_angularVelocityMin, m_angularVelocityMax);
            p->tangentialAccelX = cosf(tangentialAccel * 3.141592f / 180.0f);
            p->tangentialAccelY = sinf(tangentialAccel * 3.141592f / 180.0f);
            p->radialAccelX = cosf(radialAccel * 3.141592f / 180.0f);
            p->radialAccelY = sinf(radialAccel * 3.141592f / 180.0f); 
            p->scale = m_startScale;
            p->r = [m_startColor redComponent];
            p->g = [m_startColor greenComponent];
            p->b = [m_startColor blueComponent];
            p->a = [m_startColor alphaComponent];
        }
#       undef randr
    }
    
    // count how many we've emitted total
    m_total += n;
}

- (void)startEmitter
{
    if (m_active == NO) {
        m_active = YES;
        m_age = 0.0f;
        m_total = 0;
    }
}

- (void)stopEmitter
{
    m_active = NO;
}

- (void)advance
{
    float dt = [theClock deltaTime];
    
    // iterate in reverse order for O(1) removal
    for(int i = m_count - 1;i >= 0;i--) {
        Particle* p = &m_particles[i];
        
        if ((p->age += dt) > p->lifetime) {
            *p = m_particles[--m_count];
        } else {
            float k = p->age / p->lifetime;
            
            // translate the particle
            p->x += p->speed * p->dirx * dt;
            p->y += p->speed * p->diry * dt;
            
            // calculate the angular change this frame
            float drotx = cosf(p->angularVel * dt * 3.141592f / 180.0f);
            float droty = sinf(p->angularVel * dt * 3.141592f / 180.0f);
            
            // multiple rotation matrices
            float rotx = (p->rotx * drotx) - (p->roty * droty);
            float roty = (p->rotx * droty) + (p->roty * drotx);
            
            // update the rotation matrix
            p->rotx = rotx;
            p->roty = roty;
            
#           define interp(m,n) ((m) + k * ((n) - (m)))
            {
                // interpolate the color of the particle
                p->r = interp([m_startColor redComponent], [m_endColor redComponent]);
                p->g = interp([m_startColor greenComponent], [m_endColor greenComponent]);
                p->b = interp([m_startColor blueComponent], [m_endColor blueComponent]);
                p->a = interp([m_startColor alphaComponent], [m_endColor alphaComponent]);
                
                // interpolate the scale of the particle
                p->scale = interp(m_startScale, m_endScale);
            }
#           undef interp
        }
	}
    
    // don't emit particles if not active
    if (m_active == YES) {
        int n;
        
        // determine if it will be active next frame
        m_active = (isnan(m_lifetime) || m_age < m_lifetime);
        
        // age the emitter
        m_age += dt;
        
        // one-shot systems emit all particles instantly
        if (isnan(m_lifetime) || m_lifetime > 0.0f) {
            n = (int)(m_age * m_rate) - m_total;
        } else {
            n = (int)(m_rate);
        }
        
        // emit more particles
        [self emit:n];
    }
}

- (void)render
{
    static float M[16] = {
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f, 
        0.0f, 0.0f, 1.0f, 0.0f, 
        0.0f, 0.0f, 0.0f, 1.0f, 
    };
    
    glPushMatrix();
    {
        glBlendFunc(GL_SRC_ALPHA, GL_ONE);
        {
            for(int i = 0;i < m_count;i++) {
                Particle* p = &m_particles[i];
                
                // use the shared matrix
                M[ 0] =  p->rotx * p->scale;
                M[ 1] =  p->roty * p->scale;
                M[ 4] = -p->roty * p->scale;
                M[ 5] =  p->rotx * p->scale;
                M[12] =  p->x;
                M[13] =  p->y;
                
                // quickly set the transform
                glLoadMatrixf(M);
                
                // set the blend color
                glColor4f(p->r, p->g, p->b, p->a);
                    
                // render the texture
                [m_atlas render:m_frame];
            }
        }
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }
    glPopMatrix();
}

/*
 * LUA INTERFACE
 */

- (int)l_start:(lua_State*)L
{
    return [self startEmitter], 0;
}

- (int)l_stop:(lua_State*)L
{
    return [self stopEmitter], 0;
}

- (int)l_isActive:(lua_State*)L
{
    return lua_pushboolean(L, [self isActive]), 1;
}

- (int)l_particleCount:(lua_State*)L
{
    return lua_pushnumber(L, [self particleCount]), 1;
}

- (int)l_isRunning:(lua_State*)L
{
    return lua_pushboolean(L, [self isRunning]), 1;
}

@end
