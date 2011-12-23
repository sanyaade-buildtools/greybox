// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Clock.h"

@implementation Clock

- (id)init
{
	if ((self = [super init]) == nil) {
		return nil;
	}
	
	// default members
    m_firstFrameTime = [[NSDate date] retain];
	m_lastFrameTime = nil;
    m_frame = 0;
	m_deltaTime = 0.0f;
	m_fps = 0.0f;
	m_lockFps = NO;
	
	return self;
}

- (void)dealloc
{
    [m_firstFrameTime release];
	[m_lastFrameTime release];
	
	// supersend
	[super dealloc];
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"time", @selector(l_time:)),
            script_Method(@"delta_time", @selector(l_deltaTime:)),
            script_Method(@"frame", @selector(l_frame:)),
            script_Method(@"fps", @selector(l_fps:)),
            nil];
}

- (void)lockFPS:(BOOL)flag
{
    m_lockFps = flag;
}

- (void)advance
{
	NSDate * now = [NSDate date];
	
	if (m_lastFrameTime == nil) {
		m_lastFrameTime = [[NSDate date] retain];
	}
	
	// calculate the timestep since the last simulation frame
	m_deltaTime = [now timeIntervalSinceDate:m_lastFrameTime];
	m_fps = 1.0f / m_deltaTime;
	
	// release the last time
	[m_lastFrameTime release];
	
	// keep this one and advance the frame counter
	m_lastFrameTime = [now retain];
    m_frame++;
}

- (float)time
{
    return [m_lastFrameTime timeIntervalSinceDate:m_firstFrameTime];
}

- (float)deltaTime
{
	return m_lockFps ? 1 / 60.0f : m_deltaTime;
}

- (float)fps
{
	return m_lockFps ? 60.0f : m_fps;
}

/*
 * LUA INTERFACE
 */

- (int)l_time:(lua_State*)L
{
    return lua_pushnumber(L, [self time]), 1;
}

- (int)l_deltaTime:(lua_State*)L
{
    return lua_pushnumber(L, m_deltaTime), 1;
}

- (int)l_frame:(lua_State*)L
{
    return lua_pushnumber(L, m_frame), 1;
}

- (int)l_fps:(lua_State*)L
{
    return lua_pushnumber(L, [self fps]), 1;
}

@end
