// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Script.h"

@interface Clock : NSObject <ScriptInterface>
{
    NSDate* m_firstFrameTime;
	NSDate* m_lastFrameTime;
    
    // current frame counter
    unsigned int m_frame;
	
	// seconds since the last advance and average fps
	float m_deltaTime;
	float m_fps;
	
	// true if locking the framerate (useful in debugging)
	BOOL m_lockFps;
}

// initialization methods
- (id)init;

// set to true in order to hard lock the framerate to 60 FPS
- (void)lockFPS:(BOOL)flag;

// called once per frame to advance the framecount and delta time
- (void)advance;

// member accessors
- (float)time;
- (float)deltaTime;
- (float)fps;

@end
