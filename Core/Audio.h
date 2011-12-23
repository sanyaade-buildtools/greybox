// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Script.h"

typedef struct {
    ALuint handle;
    int i;
    BOOL state;
} Source;

@interface Audio : NSObject <ScriptInterface>
{
    ALCdevice* m_device;
    ALCcontext* m_context;
    
    // audio emitter source list
    Source m_sources[20];
}

// make this audio context current
- (BOOL)makeCurrent;

// play an audio clip
- (unsigned long)woof:(NSString*)sample;

// check for completed sound sources and reclaim
- (void)update;

@end
