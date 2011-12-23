// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Collider.h"

@interface SegmentCollider : Collider <ComponentInterface>
{
    float m_radius;
    
    // from, to points
    cpVect m_a;
    cpVect m_b;
}

// accessors
- (float)radius;
- (float)x1;
- (float)y1;
- (float)x2;
- (float)y2;

@end
