// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "chipmunk.h"
#import "Component.h"
#import "Script.h"

@interface Collider : BaseComponent
{
	cpShape* m_shape;
}

// accessors
- (cpShape*)shape;

@end
