// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Layer.h"
#import "Script.h"
#import "World.h"

@interface Scene : NSObject <ScriptInterface>
{
    // sorted list of all the action layers
    NSMutableArray* m_layers;
    
    // root scene script
    Script* m_script;
}

// initialization methods
- (id)initWithScript:(Script*)script;

// accessors
- (Script*)script;

// frame stages
- (void)start;
- (void)advance;
- (void)render;
- (void)update;
- (void)leave;
- (void)gui;

@end
