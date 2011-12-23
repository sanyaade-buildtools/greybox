// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Collider.h"
#import "Engine.h"

@implementation Collider

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
	m_shape = NULL;
    
	return self;
}

- (void)dealloc
{
    if (m_shape) {
        cpShapeDestroy(m_shape);
        //cpShapeFree(m_shape);
    }
    
    [super dealloc];
}

- (cpShape*)shape
{
    return m_shape;
}

- (cpShape*)createShape
{
    return NULL;
}

- (void)start
{
    if ((m_shape = [self createShape]) != NULL) {
        [theWorld addCollider:self];
    }
}

- (void)leave
{
    if (m_shape != NULL) {
        [theWorld removeCollider:self];
    }
}

@end
