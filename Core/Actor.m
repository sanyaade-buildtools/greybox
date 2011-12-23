// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Actor.h"
#import "Behavior.h"
#import "Component.h"
#import "Engine.h"

// it's used a lot ;-)
static const float PI = 3.141592f;

// conversion to and from degrees
#define degToRad(x) ((x) * PI / 180.0f)
#define radToDeg(x) ((x) * 180.0f / PI)

// ensure an angle doesn't get insane
#define clampAngle(x) fmod(x, PI * 2.0f)

// shared 4x4 matrix
static float M[16] = {
    1.0f, 0.0f, 0.0f, 0.0f,
    0.0f, 1.0f, 0.0f, 0.0f, 
    0.0f, 0.0f, 1.0f, 0.0f, 
    0.0f, 0.0f, 0.0f, 1.0f, 
};

@implementation Actor

+ (Actor*)actorFromPrefab:(NSString*)name
{
    Prefab* prefab;
    
    // lookup the prefab asset in the project
    if ((prefab = [theProject assetWithName:name type:[Prefab class]]) == nil) {
        return nil;
    }
    
    return [[[Actor alloc] initWithPrefab:prefab] autorelease];
}

- (id)initWithPrefab:(Prefab*)prefab
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_name = nil;
    m_script = [[theEngine script] newThread];
    m_components = [[NSMutableArray alloc] init];
	m_body = cpBodyNew(1.0f, 1.0f);
    m_dead = NO;
    m_visible = YES;
    m_kinematic = YES;
    
    // set this actor to the user-defined data for the rigid body
    m_body->data = self;
    
    // register global actor functions
    [m_script registerObject:self withNamespace:nil];
    
    // register the transform methods with the script
    [m_script registerMethods:[NSArray arrayWithObjects:
                               script_Method(@"set_position", @selector(l_setPosition:)),
                               script_Method(@"set_angle", @selector(l_setAngle:)),
                               script_Method(@"position", @selector(l_position:)),
                               script_Method(@"angle", @selector(l_angle:)),
                               script_Method(@"translate", @selector(l_translateBy:)),
                               script_Method(@"rotate", @selector(l_rotateBy:)),
                               script_Method(@"rotate_point", @selector(l_rotatePoint:)),
                               script_Method(@"velocity", @selector(l_velocity:)),
                               script_Method(@"clamp_velocity", @selector(l_clampVelocity:)),
                               nil]
                    constants:nil
                    forObject:self
                withNamespace:@"transform"];
    
    // set all the tags
    m_tags = [[prefab tags] mutableCopy];
    
    // initialize all the components
    for(NSString* className in [prefab components]) {
        Class cls = NSClassFromString(className);
        NSArray* components = [[prefab components] objectForKey:className];
        
        for(NSArray* props in components) {
            id component = [[cls alloc] initWithActor:self properties:props];
            
            // instantiate an instance of the component
            [m_components addObject:[component autorelease]];
            
            // add the component's script interface to the actor
            if ([component name] != nil) {
                [m_script registerObject:component 
                           withNamespace:[component name] 
                                  locked:YES];
            }
        }
    }
    
    return self;
}

- (void)dealloc
{
    if (m_body) {
        cpBodyDestroy(m_body);
    }

    [m_name release];
    [m_script release];
    [m_components release];
    [m_tags release];
    [super dealloc];
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"destroy", @selector(l_destroy:)),
            script_Method(@"is_dead", @selector(l_isDead:)),
            script_Method(@"set_visible", @selector(l_setVisible:)),
            script_Method(@"is_visible", @selector(l_isVisible:)),
            script_Method(@"has_tag", @selector(l_hasTag:)),
            script_Method(@"add_tag", @selector(l_addTag:)),
            script_Method(@"remove_tag", @selector(l_removeTag:)),
            nil];
}

- (void)setName:(NSString*)name
{
    m_name = [name retain];
}

- (NSString*)name
{
    return [[m_name retain] autorelease];
}

- (BOOL)isDead
{
    return m_dead;
}

- (void)kill
{
    // signals the layer to remove the actor
    m_dead = YES;
    
    // TODO: put all shapes in layer 0 so they don't collide
}

- (BOOL)hasTag:(NSString*)tag
{
    return [m_tags member:[tag lowercaseString]] != nil;
}

- (Script*)script
{
    return [[m_script retain] autorelease];
}

- (cpBody*)body
{
    return m_body;
}

- (void)addTag:(NSString*)tag
{
    [m_tags addObject:[tag lowercaseString]];
}

- (void)removeTag:(NSString*)tag
{
    [m_tags removeObject:[tag lowercaseString]];
}

- (void)setIsTrigger:(BOOL)flag
{
    m_trigger = flag;
}

- (void)setIsKinematic:(BOOL)flag
{
    m_kinematic = flag;
}

- (BOOL)isTrigger
{
    return m_trigger;
}

- (BOOL)isKinematic
{
    return m_kinematic;
}

- (float)angle
{
    return radToDeg(cpBodyGetAngle(m_body));
}

- (float)x
{
    return cpBodyGetPos(m_body).x;
}

- (float)y
{
    return cpBodyGetPos(m_body).y;
}

- (void)applyTransform
{
    cpVect pos = m_body->p;
    cpVect rot = m_body->rot;
    
    // set the transformation
    M[ 0] =  rot.x;
    M[ 1] =  rot.y;
    M[ 4] = -rot.y;
    M[ 5] =  rot.x;
    M[12] =  pos.x;
    M[13] =  pos.y;
    
    // apply it
    glMultMatrixf(M);
}

- (void)loadTransform
{
    cpVect pos = m_body->p;
    cpVect rot = m_body->rot;
    
    // set the transformation
    M[ 0] =  rot.x;
    M[ 1] =  rot.y;
    M[ 4] = -rot.y;
    M[ 5] =  rot.x;
    M[12] =  pos.x;
    M[13] =  pos.y;
    
    // load it
    glLoadMatrixf(M);
}

- (NSPoint)transformPoint:(NSPoint)point
{
    NSPoint p = [self rotatePoint:point];
    
    // translate the position
    return NSMakePoint(p.x + [self x], p.y + [self y]);
}

- (NSPoint)rotatePoint:(NSPoint)point
{
    cpVect p = cpvrotate(cpv(point.x, point.y), cpBodyGetRot(m_body));
    
    // convert back to a cocoa point
    return NSMakePoint(p.x, p.y);
}

- (void)setPosition:(NSPoint)point
{
    cpBodySetPos(m_body, cpv(point.x, point.y));
}

- (void)setAngle:(float)degrees
{
    cpBodySetAngle(m_body, clampAngle(degToRad(degrees)));
}

- (void)translateBy:(NSPoint)delta global:(BOOL)global
{
    cpVect d = cpv(delta.x, delta.y);
    
    // rotate if using local coordinates
    if (global == NO) {
        d = cpvrotate(d, m_body->rot);
    }
    
    // translate
    m_body->p.x += d.x;
    m_body->p.y += d.y;
}

- (void)rotateBy:(float)degrees
{
    cpBodySetAngle(m_body, clampAngle(cpBodyGetAngle(m_body) + degToRad(degrees)));
}

- (void)setVisible:(BOOL)flag
{
    m_visible = flag;
}

- (BOOL)isVisible
{
    return m_visible;
}

- (void)start
{
    for(BaseComponent* component in m_components) {
        if ([component isEnabled]) {
            [component start];
        }
    }
}

- (void)advance
{
    for(BaseComponent* component in m_components) {
        if ([component isEnabled]) {
            [component advance];
        }
    }
}

- (void)render
{
    if (m_visible == NO) {
        return;
    }
    
    // save the current transform state
    glPushMatrix();
    {
        [self applyTransform];
        
        // perform this actor's rendering components
        for(BaseComponent* component in m_components) {
            if ([component isEnabled]) {
                [component render];
            }
        }
    }
    glPopMatrix();
}

- (void)update
{
    for(BaseComponent* component in m_components) {
        if ([component isEnabled]) {
            [component update];
        }
    }
}

- (void)leave
{
    for(BaseComponent* component in m_components) {
        if ([component isEnabled]) {
            [component leave];
        }
    }
}

- (void)gui
{
    for(BaseComponent* component in m_components) {
        if ([component isEnabled]) {
            [component gui];
        }
    }
}

- (BOOL)beginCollision:(Actor*)actor
{
    for(id component in m_components) {
        if ([component isEnabled] && [component isKindOfClass:[Behavior class]]) {
            Script* script = [component script];
            
            // the actor we collided with, pass it as an argument
            [script push:[actor script]];
            
            // call the collide callback
            [script call:"collide" withArgs:1];
        }
    }
    
    // ignore the collision if etherial
    return m_trigger == FALSE;
}

- (void)endCollision:(Actor*)actor
{
    // TODO:
}

/*
 * LUA INTERFACE
 */

- (int)l_destroy:(lua_State*)L
{
    return [self kill], 0;
}

- (int)l_isDead:(lua_State*)L
{
    return lua_pushboolean(L, [self isDead]), 1;
}

- (int)l_setVisible:(lua_State*)L
{
    return [self setVisible:lua_toboolean(L, 1)], 0;
}

- (int)l_isVisible:(lua_State*)L
{
    return lua_pushboolean(L, [self isVisible]), 1;
}

- (int)l_hasTag:(lua_State*)L
{
    NSString* tag;
    
    // get the tag name
    if ((tag = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return lua_pushboolean(L, 0), 1;
    }
    
    return lua_pushboolean(L, [self hasTag:tag]), 1;
}

- (int)l_addTag:(lua_State*)L
{
    NSString* tag;
    
    // get the tag name
    if ((tag = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return 0;
    }
    
    return [self addTag:tag], 0;
}

- (int)l_removeTag:(lua_State*)L
{
    NSString* tag;
    
    // get the tag name
    if ((tag = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return 0;
    }
    
    return [self removeTag:tag], 0;
}

- (int)l_setPosition:(lua_State*)L
{
    float x = lua_tonumber(L, 1);
    float y = lua_tonumber(L, 2);
    
    // absolute location
    return [self setPosition:NSMakePoint(x, y)], 0;
}

- (int)l_position:(lua_State*)L
{
    lua_pushnumber(L, [self x]);
    lua_pushnumber(L, [self y]);
    
    return 2;
}

- (int)l_setAngle:(lua_State*)L
{
    return [self setAngle:lua_tonumber(L, 1)], 0;
}

- (int)l_angle:(lua_State*)L
{
    return lua_pushnumber(L, [self angle]), 1;
}

- (int)l_translateBy:(lua_State*)L
{
    float dx = lua_tonumber(L, 1);
    float dy = lua_tonumber(L, 2);
    
    // true if should be rotated based on orientation
    BOOL local = lua_toboolean(L, 3);
    
    // default to global translation
    return [self translateBy:NSMakePoint(dx, dy) global:!local], 0;
}

- (int)l_rotateBy:(lua_State*)L
{
    return [self rotateBy:lua_tonumber(L, 1)], 0;
}

- (int)l_rotatePoint:(lua_State*)L
{
    cpVect pt = cpv(lua_tonumber(L, 1), 
                    lua_tonumber(L, 2));
    
    // rotate the point passed in
    pt = cpvrotate(pt, cpBodyGetRot(m_body));
    
    // push the point
    lua_pushnumber(L, pt.x);
    lua_pushnumber(L, pt.y);
    
    return 2;
}

@end