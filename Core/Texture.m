// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Display.h"
#import "Engine.h"
#import "Texture.h"

// simple macro to find the next power of two for textures
#define NEXT_POW_2(n)   \
    do {                \
        n--;            \
        n |= n >> 1;    \
        n |= n >> 2;    \
        n |= n >> 4;    \
        n |= n >> 8;    \
        n |= n >> 16;   \
        n++;            \
    } while(0)

typedef struct {
	GLfloat x, y;
	GLfloat u, v;
} Vert;

typedef struct {
	Vert v[4];
} Quad;

@implementation Texture

+ (Texture*)textureFromImage:(NSImage*)image
{
    Texture* texture = [[[Texture alloc] init] autorelease];
    
    // attempt to create the texture
    if ([texture loadFromImage:image] == FALSE) {
        return nil;
    }
    
    return texture;
}

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_frames = [[NSMutableArray alloc] initWithCapacity:1];
    m_tex = 0;
    m_image = NULL;
    
    return self;
}

- (BOOL)loadFromImage:(NSImage*)image
{
	CGContextRef context;
    CGImageSourceRef source;
	CGImageAlphaInfo alphaSetting;
	CGColorSpaceRef colorSpace;
    CGImageRef ref;
    
    // get the original texture coordinates
    m_width = m_orgWidth = [image size].width;
    m_height = m_orgHeight = [image size].height;
    
    // resize the texture to the next power of two
    NEXT_POW_2(m_width);
    NEXT_POW_2(m_height);
	
	// calculate the number of bytes per row
	m_pitch = 4 * m_width;
	
	// allocate enough memory to hold the destination image
	m_image = (GLubyte*)calloc(1, m_height * m_pitch);
	
	// get the current alpha settings for the image
	colorSpace = CGColorSpaceCreateDeviceRGB();
	alphaSetting = kCGImageAlphaPremultipliedLast;
    
    // get the image souce, we need to blit it into a bigger image
    source = CGImageSourceCreateWithData((CFDataRef)[image TIFFRepresentation], NULL);
    ref = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	
	// create a context for the core graphics
	context = CGBitmapContextCreate(m_image,       // raw bytes
									m_width,       // width
									m_height,      // height
									8,             // bits per pixel
									m_pitch,       // bytes per row
									colorSpace,    // RGBA
									alphaSetting); // alpha
	
	// get the bounds of the image
	CGRect rect = CGRectMake(0, 0, m_orgWidth, m_orgHeight);
	
	// render the image into the context
	CGContextDrawImage(context, rect, ref);
	
	// free memory now that we no longer need it
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);
    
    // add a single frame (0) that is the entire texture
    [self addFrame:NSMakeRect(0.0f, 0.0f, m_orgWidth, m_orgHeight)];
    
    // NOTE: At this point we still don't have an OpenGL texture handle, because
    //       we may be in the middle of rendering and can't create it. Instead
    //       we'll lazily-initialize the OpenGL texture the first time we go to
    //       actually render it. 
    
    return TRUE;
}

- (BOOL)loadFromDisk
{
    NSData* data;
    NSImage* image;
    
    if ((data = [theProject dataWithContentsOfFile:[self path]]) == nil) {
        return FALSE;
    }
    
    if ((image = [[NSImage alloc] initWithData:data]) == nil) {
        return FALSE;
    }
    
    return [self loadFromImage:[image autorelease]];
}

- (BOOL)unloadFromMemory
{
    [m_frames removeAllObjects];
    
	if (m_image) {
		free(m_image);
	}
	
	if (m_tex > 0) {
		glDeleteTextures(1, &m_tex);
	}
    
    return TRUE;
}

- (BOOL)isValid
{
	return m_tex > 0;
}

- (unsigned long)addFrame:(NSRect)rect
{
    return [self addFrame:rect center:NSMakePoint(0.0f, 0.0f)];
}

- (unsigned long)addFrame:(NSRect)rect center:(NSPoint)center
{
	Quad quad;
	
	// in cocoa, coordinates are from the lower-left corner, we want top-left
	float y0 = m_orgHeight - rect.origin.y;
	float y1 = m_orgHeight - rect.origin.y - rect.size.height;
	
	// calculate the uv coordinates from the extended context
	float u0 = (0.5f + rect.origin.x) / m_width;
	float v0 = (0.5f + y0) / m_height;
	float u1 = (0.5f + rect.origin.x + rect.size.width) / m_width;
	float v1 = (0.5f + y1) / m_height;
	
	// texture coordinates
	quad.v[0].u = u0, quad.v[0].v = -v0;
	quad.v[1].u = u1, quad.v[1].v = -v0;
	quad.v[2].u = u1, quad.v[2].v = -v1;
	quad.v[3].u = u0, quad.v[3].v = -v1;
	
	float sx1 = center.x;//rect.size.width / 2.0f;
	float sy1 = center.y;//rect.size.height / 2.0f;
    float sx2 = rect.size.width - center.x;
    float sy2 = rect.size.height - center.y;
	
	// scale so the quad is pixel-perfect in the viewport
	quad.v[0].x = -sx1, quad.v[0].y =  sy2;
	quad.v[1].x =  sx2, quad.v[1].y =  sy2;
	quad.v[2].x =  sx2, quad.v[2].y = -sy1;
	quad.v[3].x = -sx1, quad.v[3].y = -sy1;
	
	// add the frame to the list for the sheet
	[m_frames addObject:[NSData dataWithBytes:&quad length:sizeof(Quad)]];
	
	// return the frame index
	return [m_frames count] - 1;
}

- (unsigned long)addSpriteFrame:(NSRect)rect
{
    return [self addFrame:rect center:NSMakePoint(rect.size.width / 2,
                                                  rect.size.height / 2)];
}

- (unsigned long)addSpriteFrames:(NSPoint)origin 
                            rows:(int)rows 
                            cols:(int)cols 
                            size:(NSSize)size 
                             pad:(int)pad
{
    unsigned long base = [m_frames count];
    
    // loop over all the frames and create each
    for(int fy = 0;fy < rows;fy++) {
        for(int fx = 0;fx < cols;fx++) {
            int x = fx * (size.width + pad) + pad + origin.x;
            int y = fy * (size.height + pad) + pad + origin.y;
            
            // create the new frame
            [self addSpriteFrame:NSMakeRect(x, y, size.width, size.height)];
        }
    }
    
    return base;
}

- (void)render
{
    [self render:0];
}

- (void)render:(unsigned long)frame
{
    const Quad* quad;
    
	if (frame >= [m_frames count]) {
		return;
	}
    
    if (m_tex == 0) {
        glGenTextures(1, &m_tex);
        glBindTexture(GL_TEXTURE_2D, m_tex);
        
        // pixel format options
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        
        // texture parameters
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        // copy the pixel data into the texture
        glTexImage2D(GL_TEXTURE_2D,       // texture
                     0,                   // mip level
                     GL_RGBA,             // internal format
                     m_width,             // width
                     m_height,            // height
                     0,                   // border
                     GL_RGBA,             // external format
                     GL_UNSIGNED_BYTE,    // type
                     m_image);            // image data
    }
	
    // fetch the vertex and texcoord buffer
	quad = (const Quad*)[[m_frames objectAtIndex:frame] bytes];
	
	if (quad) {
		// make this the current texture
		glBindTexture(GL_TEXTURE_2D, m_tex);
		
		// set the vertex and texcoord pointers
		glVertexPointer(2, GL_FLOAT, sizeof(GLfloat) * 4, &quad->v[0].x);
		glTexCoordPointer(2, GL_FLOAT, sizeof(GLfloat) * 4, &quad->v[0].u);
		
		// draw a simple triangle fan
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	}
}

- (NSSize)sizeOfFrame:(unsigned long)frame
{
    const Quad* quad;
    
	if (frame >= [m_frames count]) {
		return NSMakeSize(0.0f, 0.0f);
	}
	
    // fetch the vertex and texcoord buffer
	quad = (const Quad*)[[m_frames objectAtIndex:frame] bytes];
    
    return NSMakeSize(fabs(quad->v[1].x - quad->v[0].x),
                      fabs(quad->v[2].y - quad->v[0].y));
}

- (NSSize)size
{
    return NSMakeSize(m_orgWidth, m_orgHeight);
}

@end
