// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Asset.h"

@interface Sound : Asset <AssetInterface>
{
    // loaded file format data
    AudioStreamBasicDescription m_format;
    
    // the openal generated buffer
    ALuint m_buffer;
}

// accessors
- (ALuint)buffer;

// get the format of the sound
- (ALenum)audioFormat;

@end
