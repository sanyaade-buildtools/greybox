#import "World.h"

static void worldPostStepFunc(cpSpace* space, void* obj, void* data)
{
    [(id)obj removeShapesAndBodies];
}

static int worldBeginCollisionFunc(cpArbiter* arbiter, cpSpace* space, void* data)
{
    return [(World*)data beginCollision:arbiter];
}

static void worldSeparateFunc(cpArbiter* arbiter, cpSpace* space, void* data)
{
    [(World*)data endCollision:arbiter];
}

@implementation World

- (id)init
{
	static BOOL chipmunkInitialized = NO;
	
	if ((self = [super init]) == nil) {
		return nil;
	}
	
	// initialize the physics system
	if (chipmunkInitialized == NO) {
		cpInitChipmunk();
		
		// don't ever re-initialize
		chipmunkInitialized = YES;
	}
	
	// create a simulation world
	m_space = cpSpaceNew();
    
    // initialize members
    m_shapeRemovalQueue = [[NSMutableArray alloc] init];
    m_bodyRemovalQueue = [[NSMutableArray alloc] init];
    
    // add a post-step callback for safe removals when done
    cpSpaceAddPostStepCallback(m_space, 
                               worldPostStepFunc, 
                               self, 
                               NULL);
        
    // setup the default collision handlers
    cpSpaceSetDefaultCollisionHandler(m_space, 
                                      worldBeginCollisionFunc,
                                      NULL,
                                      NULL,
                                      worldSeparateFunc,
                                      self);
	
	return self;
}

- (void)dealloc
{
	cpSpaceFree(m_space);
	
	// supersend
	[super dealloc];
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"set_gravity", @selector(l_setGravity:)),
            nil];
}

- (void)removeShapesAndBodies
{
    // first remove all collider shapes
    for(Collider* collider in m_shapeRemovalQueue) {
        cpSpaceAddShape(m_space, [collider shape]);
    }
    
    // now remove rigid bodies
    for(Actor* actor in m_bodyRemovalQueue) {
        cpSpaceRemoveBody(m_space, [actor body]);
    }
    
    // flush the lists
    [m_shapeRemovalQueue removeAllObjects];
    [m_bodyRemovalQueue removeAllObjects];
}

- (void)addRigidBody:(Actor*)actor
{
	cpSpaceAddBody(m_space, [actor body]);
}

- (void)removeRigidBody:(Actor*)actor
{
    [m_bodyRemovalQueue addObject:actor];
}

- (void)addCollider:(Collider*)collider
{
    cpSpaceAddShape(m_space, [collider shape]);
}

- (void)removeCollider:(Collider*)collider
{
    [m_shapeRemovalQueue addObject:collider];
}

- (BOOL)beginCollision:(struct cpArbiter*)arbiter
{
    cpBody* a;
    cpBody* b;
    
    // lookup the bodies colliding
    cpArbiterGetBodies(arbiter, &a, &b);
    
    // fetch the actors
    Actor* aA = (Actor*)a->data;
    Actor* aB = (Actor*)b->data;
    
    // if either actor is dead, ignore it
    if ([aA isDead] || [aB isDead]) {
        return FALSE;
    }
    
    // tell each actor that a collision is happening
    BOOL aOk = [aA beginCollision:aB];
    BOOL bOk = [aB beginCollision:aA];
    
    // both actors must be alive and okay with the collision
    return ([aA isDead] == NO && aOk) && ([aB isDead] == NO && bOk);
}

- (void)endCollision:(struct cpArbiter*)arbiter
{
    cpBody* a;
    cpBody* b;
    
    // lookup the bodies colliding
    cpArbiterGetBodies(arbiter, &a, &b);
    
    // tell each actor that a collision is ending
    [(Actor*)a->data endCollision:(Actor*)b->data];
    [(Actor*)b->data endCollision:(Actor*)a->data];
}

- (void)step:(float)dt
{
	cpSpaceStep(m_space, dt);
}

/*
 * LUA INTERFACE
 */

- (int)l_setGravity:(lua_State*)L
{
    float x = lua_tonumber(L, 1);
    float y = lua_tonumber(L, 2);
    
    // change the gravity constant
    cpSpaceSetGravity(m_space, cpv(x, y));
    
    return 0;
}

@end
