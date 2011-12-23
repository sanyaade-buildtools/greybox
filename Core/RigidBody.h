// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Component.h"
#import "Script.h"

@interface RigidBody : BaseComponent <ComponentInterface>
{
    /* NOTE: The RigidBody component only exists to add the rigid body
     *       already present in the Actor to the World space. It also
     *       adds script functions to the actor.
     */
}
@end
