// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Component.h"
#import "Script.h"

@interface Behavior : BaseComponent <ComponentInterface>
{
    Script* m_script;
}

// accessors
- (Script*)script;

// frame phases
- (void)start;
- (void)advance;
- (void)update;
- (void)leave;
- (void)gui;

@end
