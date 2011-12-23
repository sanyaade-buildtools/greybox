// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Audio.h"
#import "Engine.h"
#import "Sound.h"

@implementation Audio

- (id)init
{
    ALuint sources[sizeof(m_sources) / sizeof(m_sources[0])];
    
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_device = alcOpenDevice(NULL);
    m_context = alcCreateContext(m_device, NULL);
    
    // make this context the current one
    [self makeCurrent];
    
    // setup the listener's position
    alListener3f(AL_POSITION, 0.0f, 0.0f, 0.0f);
    alListener3f(AL_VELOCITY, 0.0f, 0.0f, 0.0f);
    alListener3f(AL_ORIENTATION, 0.0f, 0.0f, -1.0f);
    
    // allocate a bunch of sources
    alGenSources(sizeof(sources) / sizeof(sources[0]), sources);
    
    // populate the sources buffer with rolling counters
    for(int i = 0; i < sizeof(sources) / sizeof(sources[0]);i++) {
        m_sources[i].handle = sources[i];
        m_sources[i].i = 0;
        m_sources[i].state = NO;
    }
    
    return self;
}

- (void)dealloc
{
    if (m_context != NULL) {
        alcDestroyContext(m_context);
    }
    
    if (m_device != NULL) {
        alcCloseDevice(m_device);
    }
    
    [super dealloc];
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"play", @selector(l_play:)),
            script_Method(@"is_playing", @selector(l_isPlaying:)),
            script_Method(@"pause", @selector(l_pause:)),
            script_Method(@"stop", @selector(l_stop:)),
            nil];
}
        
- (unsigned long)handleForSource:(int)index
{
    return ((index + 1) << 15) | (m_sources[index].i & 0x7FFF);
}

- (Source*)sourceForHandle:(unsigned long)handle
{
    int index = (handle >> 15) - 1;
    int i = (handle & 0x7FFF);
    
    // make sure we have a valid handle and the same rolling counter
    if (index < 0 || i != m_sources[index].i) {
        return NULL;
    }
    
    return &m_sources[index];
}

- (int)nextAvailableSource
{
    int i;
    
    // loop over all sources
    for(i = 0;i < sizeof(m_sources) / sizeof(m_sources[0]);i++) {
        if (m_sources[i].state == FALSE) {
            return i;
        }
    }
    
    return -1;
}

- (BOOL)makeCurrent
{
    alcMakeContextCurrent(m_context);
    
    // make sure it was successful
    if (alGetError() != AL_NO_ERROR) {
        return FALSE;
    }
    
    return TRUE;
}

- (unsigned long)woof:(NSString*)sample
{
    Sound* sound;
    int i;
    
    // load the sound
    if ((sound = [theProject assetWithName:sample type:[Sound class]]) == nil) {
        return 0;
    }
    
    // check no more available sources
    if ((i = [self nextAvailableSource]) < 0) {
        return 0;
    }
    
    // initialize the audio source
    alSourcef(m_sources[i].handle, AL_PITCH, 1.0f);
    alSourcef(m_sources[i].handle, AL_GAIN, 1.0f);
    alSource3f(m_sources[i].handle, AL_POSITION, 0.0f, 0.0f, 0.0f);
    alSource3f(m_sources[i].handle, AL_VELOCITY, 0.0f, 0.0f, 0.0f);
    alSourcei(m_sources[i].handle, AL_LOOPING, AL_FALSE);
    alSourcei(m_sources[i].handle, AL_BUFFER, [sound buffer]);
    
    // play the source
    alSourcePlay(m_sources[i].handle);
    
    // increment the rolling counter so previous handles are invalidated
    m_sources[i].i++;
    m_sources[i].state = YES;
    
    return [self handleForSource:i];
}

- (void)update
{
    int i;
    
    for(i = 0;i < sizeof(m_sources) / sizeof(m_sources[0]);i++) {
        ALint queued;
        ALint processed;
        
        // don't bother checking sounds not playing
        if (m_sources[i].state == FALSE) {
            continue;
        }
        
        // find out the current state of a sound
        alGetSourcei(m_sources[i].handle, AL_BUFFERS_QUEUED, &queued);
        alGetSourcei(m_sources[i].handle, AL_BUFFERS_PROCESSED, &processed);
        
        // find out if the sound is done playing
        m_sources[i].state = (queued > processed);
    }
}

/*
 * LUA INTERFACE
 */

- (int)l_play:(lua_State*)L
{
    NSString* name;
    unsigned long source;
    
    // get the name of the sound asset
    if ((name = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return lua_pushnumber(L, 0), 1;
    }
    
    // play the sounds and get a handle to it
    source = [self woof:name];
    
    return lua_pushnumber(L, source), 1;
}

- (int)l_isPlaying:(lua_State*)L
{
    Source* source;
    
    // make sure we get a valid source
    if ((source = [self sourceForHandle:lua_tonumber(L, 1)]) != NULL) {
        return lua_pushboolean(L, source->state), 1;
    }
    
    return lua_pushboolean(L, 0), 1;
}

- (int)l_pause:(lua_State*)L
{
    Source* source;
    
    // make sure we get a valid source
    if ((source = [self sourceForHandle:lua_tonumber(L, 1)]) != NULL) {
        alSourcePause(source->handle);
    }
    
    return 0;
}

- (int)l_stop:(lua_State*)L
{
    Source* source;
    
    // make sure we get a valid source
    if ((source = [self sourceForHandle:lua_tonumber(L, 1)]) != NULL) {
        alSourceStop(source->handle);
    }
    
    return 0;
}

@end
