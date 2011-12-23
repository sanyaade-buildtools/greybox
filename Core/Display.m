// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Display.h"

@implementation Display

- (id)initWithFrame:(NSRect)frame
{
    // create the window
    self = [super initWithContentRect:frame
                            styleMask:NSTitledWindowMask | NSClosableWindowMask
                              backing:NSBackingStoreBuffered
                                defer:YES];
    
    // initiaze the viewport
    if (self != nil) {
        NSOpenGLView* view = [[NSOpenGLView alloc] initWithFrame:frame];
        
        // setup the window
        [self setContentView:view];
        [self setAcceptsMouseMovedEvents:YES];
        [self center];
        
        // initialize members
        m_inputDelegate = nil;
        m_size = frame.size;
        m_r = 0.0f;
        m_g = 0.0f;
        m_b = 0.0f;
    }
    
    return self;
}

- (void)dealloc
{
    [m_inputDelegate release];
    [super dealloc];
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"set_background_color", @selector(l_setBackgroundColor:)),
            nil];
}

- (NSArray*)scriptConstants
{
    return [NSArray arrayWithObjects:
            script_Constant(@"WIDTH", [NSNumber numberWithFloat:m_size.width]),
            script_Constant(@"HEIGHT", [NSNumber numberWithFloat:m_size.height]),
            nil];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)setInputDelegate:(Input*)input
{
    m_inputDelegate = [input retain];
}

- (Input*)inputDelegate
{
    return [[m_inputDelegate retain] autorelease];
}

- (void)prepare
{
    NSOpenGLView* view = [self contentView];
    
    // make the opengl context the active one
    [[view openGLContext] makeCurrentContext];
	
	// setup the viewport that we're render to
	glViewport(0, 0, m_size.width, m_size.height);
	
	// set default render state
    glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
    
    // set the default blending mode
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // use vertex and texture coordinate buffers
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    // erase the display
    glClearColor(m_r, m_g, m_b, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // ready to begin rendering to the display
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    // reset the render state
    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
}

- (void)present
{
    NSOpenGLView* view = [self contentView];
    
    // finish pending commands
    glFlush();
    
    // present the backbuffer
    [[view openGLContext] flushBuffer];
}

- (void)keyDown:(NSEvent*)event
{
    if ([event isARepeat] == NO) {
        [m_inputDelegate pressKey:[event keyCode]];
    }
}

- (void)keyUp:(NSEvent*)event
{
    [m_inputDelegate releaseKey:[event keyCode]];
}

- (void)flagsChanged:(NSEvent*)event
{
    [event modifierFlags];
}

- (void)mouseMoved:(NSEvent*)event
{
    [m_inputDelegate setMousePosition:[event locationInWindow]];
}

- (void)mouseDown:(NSEvent*)event
{
    [m_inputDelegate pressButton:Button_Left];
}

- (void)mouseUp:(NSEvent*)event
{
    [m_inputDelegate releaseButton:Button_Left];
}

- (void)rightMouseDown:(NSEvent*)event
{
    [m_inputDelegate pressButton:Button_Right];
}

- (void)rightMouseUp:(NSEvent*)event
{
    [m_inputDelegate releaseButton:Button_Right];
}

/*
 * LUA INTERFACE
 */


- (int)l_setBackgroundColor:(lua_State*)L
{
    m_r = lua_tonumber(L, 1);
    m_g = lua_tonumber(L, 2);
    m_b = lua_tonumber(L, 3);
    
    return 0;
}

@end