// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Input.h"
#import "Script.h"

@interface Display : NSWindow <ScriptInterface>
{
    // input event handler
    Input* m_inputDelegate;
    
    // cached values
    NSSize m_size;
    
    // clear color for background
    float m_r;
    float m_g;
    float m_b;
}

// initialization methods
- (id)initWithFrame:(NSRect)frame;

// assign an input delegate object
- (void)setInputDelegate:(Input*)input;

// input delegate
- (Input*)inputDelegate;

// ready the viewport and cleanup
- (void)prepare;
- (void)present;

@end