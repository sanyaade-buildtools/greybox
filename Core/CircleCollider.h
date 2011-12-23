// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Collider.h"

@interface CircleCollider : Collider <ComponentInterface>
{
    cpVect m_offset;
    float m_radius;
}

// accessors
- (float)radius;
- (float)x;
- (float)y;

@end
