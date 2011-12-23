// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Asset.h"
#import "Texture.h"

typedef struct {
    unsigned long frame;
    int len;
    float fps;
    BOOL looping;
} AnimSeq;

@interface Atlas : Asset <AssetInterface>
{
    NSXMLDocument* m_doc;
    
    // the texture our atlas references
    Texture* m_texture;
    
    // the named set of frames and animations
    NSMutableDictionary* m_frames;
    NSMutableDictionary* m_anims;
}

// accessors
- (Texture*)texture;

// lookup a sprite frame
- (unsigned long)frameNamed:(NSString*)name;

// lookup an animation sequence
- (const AnimSeq*)animNamed:(NSString*)name;

// render a frame from the atlas
- (void)render:(unsigned long)frame;

@end
