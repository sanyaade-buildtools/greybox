// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Atlas.h"
#import "Engine.h"

@implementation Atlas

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_doc = nil;
    m_texture = nil;
    m_frames = [[NSMutableDictionary alloc] init];
    m_anims = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)dealloc
{
    [m_frames release];
    [m_anims release];
    [super dealloc];
}

- (Texture*)texture
{
    return [[m_texture retain] autorelease];
}

- (unsigned long)frameNamed:(NSString*)name
{
    NSNumber* i;
    
    // use the entire texture if the frame wasn't found
    if ((i = [m_frames objectForKey:name]) == nil) {
        return -1UL;
    }
    
    return [i unsignedLongValue];
}

- (const AnimSeq*)animNamed:(NSString*)name
{
    NSData* data;
    
    // use the entire texture if the frame wasn't found
    if ((data = [m_anims objectForKey:name]) == nil) {
        return NULL;
    }
    
    return (const AnimSeq*)[data bytes];
}

- (void)render:(unsigned long)frame
{
    if (frame != -1UL) {
        [m_texture render:frame];
    }
}

- (void)addFrame:(NSRect)rect named:(NSString*)name
{
    unsigned long i = [m_texture addSpriteFrame:rect];
    
    // add the frame to the set
    [m_frames setObject:[NSNumber numberWithUnsignedLong:i] forKey:name];
}

- (BOOL)loadFromDisk
{
    NSXMLElement* root;
    NSString* textureFileName;
    NSData* textureData;
    NSImage* textureImage;
    Texture* texture;
    
    // try and parse the prefab document
    if ((m_doc = [theProject xmlDocumentWithContentsOfPath:[self path]]) == nil) {
        return FALSE;
    }
    
    // get the root element
    if ((root = [m_doc rootElement]) == nil) {
        return FALSE;
    }
    
    // find the texture name
    if ((textureFileName = [[root attributeForName:@"texture"] stringValue]) == nil) {
        NSLog(@"No texture attribute for atlas %@\n", [self name]);
        return FALSE;
    }
    
    // attempt to load the image file
    if ((textureData = [theProject dataWithContentsOfFile:textureFileName]) == nil) {
        NSLog(@"Failed to load texture file %@ in atlas %@\n", textureFileName, [self name]);
        return FALSE;
    }
    
    // attempt to open the image file
    if ((textureImage = [[NSImage alloc] initWithData:textureData]) == nil) {
        NSLog(@"Invalid texture %@ for atlas %@\n", textureFileName, [self name]);
        return FALSE;
    }
    
    // create the texture
    if ((texture = [Texture textureFromImage:[textureImage autorelease]]) == nil) {
        NSLog(@"Invalid texture %@ for atlas %@\n", textureFileName, [self name]);
        return FALSE;
    }
    
    // we now have a valid texture for the atlas
    m_texture = [texture retain];
    
    // parse and load all the texture frames
    for(NSXMLElement* frames in [root elementsForName:@"frames"]) {
        for(NSXMLElement* frame in [frames elementsForName:@"frame"]) {
            NSString* name;
            NSString* x;
            NSString* y;
            NSString* w;
            NSString* h;
            
            // get the name of this frame
            if ((name = [[frame attributeForName:@"name"] stringValue]) == nil) {
                NSLog(@"Missing name attribute in frame for atlas %@\n", [self name]);
                continue;
            }
            
            // get the left-origin of the frame
            if ((x = [[frame attributeForName:@"x"] stringValue]) == nil) {
                NSLog(@"Missing x attribute for frame %@ in atlas %@\n", name, [self name]);
                continue;
            }
            
            // get the top-origin of the frame
            if ((y = [[frame attributeForName:@"y"] stringValue]) == nil) {
                NSLog(@"Missing y attribute for frame %@ in atlas %@\n", name, [self name]);
                continue;
            }
            
            // get the width of the frame
            if ((w = [[frame attributeForName:@"w"] stringValue]) == nil) {
                NSLog(@"Missing w attribute for frame %@ in atlas %@\n", name, [self name]);
                continue;
            }
            
            // get the height of the frame
            if ((h = [[frame attributeForName:@"h"] stringValue]) == nil) {
                NSLog(@"Missing h attribute for frame %@ in atlas %@\n", name, [self name]);
                continue;
            }
            
            // create the new frame
            [self addFrame:NSMakeRect([x intValue],
                                      [y intValue],
                                      [w intValue],
                                      [h intValue])
                     named:name];
        }
    }
    
    // parse and load all the animation sequences
    for(NSXMLElement* anims in [root elementsForName:@"anims"]) {
        for(NSXMLElement* anim in [anims elementsForName:@"anim"]) {
            NSString* name;
            NSString* value;
            NSPoint origin;
            NSSize size;
            int pad;
            int rows;
            int cols;
            AnimSeq seq;
            
            // get the name of this frame
            if ((name = [[anim attributeForName:@"name"] stringValue]) == nil) {
                NSLog(@"Missing name attribute in anim for atlas %@\n", [self name]);
                continue;
            }
            
            // get the left-origin of the frame
            if ((value = [[anim attributeForName:@"x"] stringValue]) == nil) {
                NSLog(@"Missing x attribute for anim %@ in atlas %@\n", name, [self name]);
                continue;
            }
            
            origin.x = [value intValue];
            
            // get the top-origin of the frame
            if ((value = [[anim attributeForName:@"y"] stringValue]) == nil) {
                NSLog(@"Missing y attribute for anim %@ in atlas %@\n", name, [self name]);
                continue;
            }
            
            origin.y = [value intValue];
            
            // get the width of each frame
            if ((value = [[anim attributeForName:@"w"] stringValue]) == nil) {
                NSLog(@"Missing w attribute for anim %@ in atlas %@\n", name, [self name]);
                continue;
            }
            
            size.width = [value intValue];
            
            // get the height of each frame
            if ((value = [[anim attributeForName:@"h"] stringValue]) == nil) {
                NSLog(@"Missing h attribute for anim %@ in atlas %@\n", name, [self name]);
                continue;
            }
            
            size.height = [value intValue];
            
            // get the framerate
            if ((value = [[anim attributeForName:@"fps"] stringValue]) == nil) {
                seq.fps = 15.0f;
            } else {
                seq.fps = [value floatValue];
            }
            
            // get the optional frame padding
            if ((value = [[anim attributeForName:@"pad"] stringValue]) == nil) {
                pad = 0;
            } else {
                pad = [value intValue];
            }
            
            // get the optional play mode
            if ((value = [[anim attributeForName:@"looping"] stringValue]) == nil) {
                seq.looping = YES;
            } else {
                seq.looping = [value boolValue];
            }
            
            // get the number of frames vertically
            if ((value = [[anim attributeForName:@"rows"] stringValue]) == nil) {
                rows = 1;
            } else {
                rows = [value intValue];
            }
            
            // get the number of frames horizontally
            if ((value = [[anim attributeForName:@"cols"] stringValue]) == nil) {
                cols = 1;
            } else {
                cols = [value intValue];
            }
            
            // finish creating the animation sequence
            seq.len = rows * cols;
            seq.frame = [m_texture addSpriteFrames:origin
                                              rows:rows
                                              cols:cols
                                              size:size
                                               pad:pad];
            
            // add it
            [m_anims setValue:[NSData dataWithBytes:&seq length:sizeof(seq)]
                       forKey:name];
        }
    }
    
    return TRUE;
}

- (BOOL)unloadFromMemory
{
    [m_doc release];
    [m_frames removeAllObjects];
    [m_anims removeAllObjects];
    [m_texture release];
    
    return TRUE;
}

@end
