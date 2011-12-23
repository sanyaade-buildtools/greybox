// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Engine.h"
#import "RigidBody.h"

@implementation RigidBody

+ (NSArray*)properties
{
    return [[NSArray arrayWithObjects:
             prop_WIRE(@"mass", @selector(setMass:)),
             prop_WIRE(@"interia", @selector(setInteria:)),
             prop_WIRE(@"trigger", @selector(setTrigger:)),
             prop_WIRE(@"kinematic", @selector(setKinematic:)),
             nil]
            arrayByAddingObjectsFromArray:[super properties]];
}

- (NSArray*)scriptMethods
{
    return [[NSArray arrayWithObjects:
             script_Method(@"apply_force", @selector(l_applyForce:)),
             script_Method(@"apply_impulse", @selector(l_applyImpulse:)),
             script_Method(@"velocity", @selector(l_velocity:)),
             script_Method(@"clamp_velocity", @selector(l_clampVelocity:)),
             script_Method(@"set_mass", @selector(l_setMass:)),
             script_Method(@"set_inertia", @selector(l_setInertia:)),
             script_Method(@"mass", @selector(l_mass:)),
             script_Method(@"inertia", @selector(l_inertia:)),
             nil]
            arrayByAddingObjectsFromArray:[super scriptMethods]];
}

- (void)setTrigger:(NSString*)value
{
    [m_actor setIsTrigger:[value boolValue]];
}

- (void)setKinematic:(NSString*)value
{
    [m_actor setIsKinematic:[value boolValue]];
}

- (void)setMass:(NSString*)value
{
    cpBodySetMass([m_actor body], [value floatValue]);
}

- (void)setInertia:(NSString*)value
{
    cpBodySetMoment([m_actor body], [value floatValue]);
}

- (void)enable
{
    // make sure the actor is part of the world
    [theWorld addRigidBody:m_actor];
    
    // really enable the component
    [super enable];
}

- (void)disable
{
    // make sure the actor is not part of the world
    [theWorld removeRigidBody:m_actor];
    
    // really disable the component
    [super disable];
}

- (void)start
{
    [theWorld addRigidBody:m_actor];
}

- (void)leave 
{
    [theWorld removeRigidBody:m_actor];
}

/*
 * LUA INTERFACE
 */

- (int)l_applyForce:(lua_State*)L
{
    float fx = lua_tonumber(L, 1);
    float fy = lua_tonumber(L, 2);
    float rx = lua_tonumber(L, 3);
    float ry = lua_tonumber(L, 4);
    
    // apply the force
    cpBodyApplyForce([m_actor body], cpv(fx, fy), cpv(rx, ry));
    
    return 0;
}

- (int)l_applyImpulse:(lua_State*)L
{
    float jx = lua_tonumber(L, 1);
    float jy = lua_tonumber(L, 2);
    float rx = lua_tonumber(L, 3);
    float ry = lua_tonumber(L, 4);
    
    // apply the force
    cpBodyApplyImpulse([m_actor body], cpv(jx, jy), cpv(rx, ry));
    
    return 0;
}

- (int)l_velocity:(lua_State*)L
{
    lua_pushnumber(L, [m_actor body]->v.x);
    lua_pushnumber(L, [m_actor body]->v.y);
    
    return 2;
}

- (int)l_clampVelocity:(lua_State*)L
{
    cpVect vel = cpBodyGetVel([m_actor body]);
    float s = lua_tonumber(L, 1);
    
    // check to see if we need to clamp the velocity
    if (vel.x * vel.x + vel.y * vel.y > s * s) {
        float u = cpvlength(vel);
        
        // set the new velocity
        vel.x = vel.x * s / u;
        vel.y = vel.y * s / u;
        
        // cap the velocity
        cpBodySetVel([m_actor body], vel);
    }
    
    return 0;
}

- (int)l_setMass:(lua_State*)L
{
	return cpBodySetMass([m_actor body], lua_tonumber(L, 1)), 0;
}

- (int)l_setInertia:(lua_State*)L
{
	return cpBodySetMoment([m_actor body], lua_tonumber(L, 1)), 0;
}

- (int)l_mass:(lua_State*)L
{
    return lua_pushnumber(L, [m_actor body]->i), 1;
}

- (int)l_inertia:(lua_State*)L
{
    return lua_pushnumber(L, [m_actor body]->i), 1;
}

@end
