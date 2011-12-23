// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/gl.h>
#import "Asset.h"

@interface Texture : Asset <AssetInterface>
{
	GLubyte* m_image;
	
	// compiled frame quads
	NSMutableArray* m_frames;
	
	// original size of the texture
	int m_orgWidth;
	int m_orgHeight;
	
	// power of 2 aligned texture size
	int m_width;
	int m_height;
	int m_pitch;
	
	// opengl data
	GLuint m_tex;
}

// allocator methods
+ (Texture*)textureFromImage:(NSImage*)image;

// so other systems can create their own textures
- (BOOL)loadFromImage:(NSImage*)image;

// returns YES if this texture is valid and able to be used
- (BOOL)isValid;

// create a new framed quad for the texture
- (unsigned long)addFrame:(NSRect)rect;
- (unsigned long)addFrame:(NSRect)rect center:(NSPoint)center;

// sprite frames are always centered at the middle of the rect
- (unsigned long)addSpriteFrame:(NSRect)rect;
- (unsigned long)addSpriteFrames:(NSPoint)origin 
                            rows:(int)rows 
                            cols:(int)cols 
                            size:(NSSize)size 
                             pad:(int)pad; 

// rendering functions
- (void)render;
- (void)render:(unsigned long)frame;

// retrieve the size of a frame or the entire texture
- (NSSize)sizeOfFrame:(unsigned long)frame;
- (NSSize)size;

@end
