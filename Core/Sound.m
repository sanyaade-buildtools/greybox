// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Engine.h"
#import "Sound.h"

@implementation Sound

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_buffer = 0;
    
    return self;
}

- (ALuint)buffer
{
    return m_buffer;
}

- (ALenum)audioFormat
{
    if (m_format.mChannelsPerFrame > 1) {
        if (m_format.mBitsPerChannel == 16) {
            return AL_FORMAT_STEREO16;
        } else {
            return AL_FORMAT_STEREO8;
        }
    } else {
        if (m_format.mBitsPerChannel == 16) {
            return AL_FORMAT_MONO16;
        } else {
            return AL_FORMAT_MONO8;
        }
    }
}

- (BOOL)readAudioFile:(AudioFileID)afid
{
    uint32 formatSize = sizeof(AudioStreamBasicDescription);
    uint32 dataSize = sizeof(uint64);
    uint64 length;
    
    // get the file format of the source
    if (AudioFileGetProperty(afid, 
                             kAudioFilePropertyDataFormat, 
                             &formatSize, 
                             &m_format) != 0) {
        return FALSE;
    }
    
    // attempt to fetch the size of the data
    if (AudioFileGetProperty(afid, 
                             kAudioFilePropertyAudioDataByteCount, 
                             &dataSize, 
                             &length) != 0) {
        return FALSE;
    }
    
    // allocate enough memory for the sound
    NSMutableData* data = [NSMutableData dataWithLength:length];
    
    // cap the size of the file, read this many bytes
    dataSize = length & 0xFFFFFFFF;
    
    // read the audio data
    if (AudioFileReadBytes(afid, FALSE, 0, &dataSize, [data mutableBytes]) != 0) {
        return FALSE;
    }
    
    // if the data is 8- or 16-bit then we can just use the data as-is
    if (m_format.mBitsPerChannel == 8 || m_format.mBitsPerChannel == 16) {
        // do nothing
    }
    
    // otherwise, let's convert it from 32-bit to 16-bit
    if (m_format.mBitsPerChannel == 32) {
        uint16* u16 = (uint16*)[data mutableBytes];
        uint32* u32 = (uint32*)[data mutableBytes];
        
        // convert from float or integer
        if (m_format.mFormatFlags & kLinearPCMFormatFlagIsFloat) {
            uint32 i;
            
            for(i = 0;i < (dataSize >> 2);i++) {
                float f32 = *((float*)(u32++));
                
                // convert from a float to a 16-bit value
                *u16++ = (uint16)(f32 * 32768.0f);
            }
            
            // adjust flags appropriately
            m_format.mFormatFlags &= ~kLinearPCMFormatFlagIsFloat;
            m_format.mFormatFlags |= kLinearPCMFormatFlagIsSignedInteger;
        } else {
            uint32 i;
            
            for(i = 0;i < (dataSize >> 2);i++) {
                if (m_format.mFormatFlags & kLinearPCMFormatFlagIsSignedInteger) {
                    uint32 sign = *u32 & 0x80000000;
                    
                    // preserve the sign bit
                    *u16++ = (*u32++ >> 16) | (sign >> 16);
                } else {
                    *u16++ = (*u32++ >> 16);
                }
            }
        }
        
        // modify the format to show it's now 16-bit, non-floating point data
        m_format.mBitsPerChannel = 16;
        
        // from 32-bit to 16-bit
        dataSize >>= 1;
    }
    
    // allocate a source buffer
    alGenBuffers(1, &m_buffer);
    
    // make sure it was successful
    if (alGetError() != AL_NO_ERROR) {
        return FALSE;
    }
    
    // load the sample data into the buffer
    alBufferData(m_buffer, [self audioFormat], [data bytes], dataSize, m_format.mSampleRate);
    
    // make sure it was successful
    if (alGetError() != AL_NO_ERROR) {
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)loadFromDisk
{
    CFURLRef fileURL;
    OSStatus err;
    AudioFileID afid;
    
    // get a url reference to the file
    if ((fileURL = (CFURLRef)[theProject URLForFile:[self path]]) == nil) {
        return FALSE;
    }
    
    // attempt to open the audio source file
    if ((err = AudioFileOpenURL(fileURL, 
                                kAudioFileReadPermission, 
                                0, 
                                &afid)) != 0) {
        return FALSE;
    }
    
    // attempt to read the data from the file
    [self readAudioFile:afid];
    
    // close the source file
    AudioFileClose(afid);
    
    // successfully loaded
    return m_buffer != 0;
}

- (BOOL)unloadFromMemory
{
    if (m_buffer != 0) {
        alDeleteBuffers(1, &m_buffer);
    }
 
    return TRUE;
}

@end
