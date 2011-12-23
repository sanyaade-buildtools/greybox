// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Camera.h"
#import "Engine.h"

typedef struct {
    // viewport size in pixels
    float width;
    float height;
    
    // the orthographic projection world bounds
    float top;
    float left;
    float bottom;
    float right;
    
    // position, rotation, and zoom
    float x;
    float y;
    float angle;
    float z; 
} Projection;

@implementation Camera

+ (Camera*)camera
{
    return [[[Camera alloc] init] autorelease];
}

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_stack = [[NSMutableArray alloc] initWithCapacity:4];
    
    return self;
}

- (void)dealloc
{
    [m_stack release];
    [super dealloc];
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"push", @selector(l_push:)),
            script_Method(@"pop", @selector(l_pop:)),
            script_Method(@"set_bounds", @selector(l_setBounds:)),
            script_Method(@"bounds", @selector(l_bounds:)),
            script_Method(@"position", @selector(l_position:)),
            script_Method(@"set_position", @selector(l_setPosition:)),
            script_Method(@"scroll", @selector(l_scroll:)),
            script_Method(@"zoom", @selector(l_zoom:)),
            nil];
}

- (Projection*)projection
{
    return (Projection*)[[m_stack lastObject] bytes];
}

- (void)push
{
    Projection* proj = [self projection];
    
    // duplicate the current projection on the stack
    [m_stack addObject:[NSData dataWithBytes:proj length:sizeof(Projection)]];
}

- (void)pop
{
    if ([m_stack count] > 1) {
        [m_stack removeLastObject];
    }
}

- (float)left
{
    return [self projection]->left;
}

- (float)bottom
{
    return [self projection]->bottom;
}

- (float)right
{
    return [self projection]->right;
}

- (float)top
{
    return [self projection]->top;
}

- (float)x
{
    return [self projection]->x;
}

- (float)y
{
    return [self projection]->y;
}

- (float)angle
{
    return [self projection]->angle;
}

- (float)z
{
    return [self projection]->z;
}

- (void)loadProjectionMatrix
{
    Projection* proj;
    GLint mode;
    
    // fetch the current mode
    glGetIntegerv(GL_MATRIX_MODE, &mode);
    
    // switch to projection mode
    glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
    
    // get the top-most projection
    proj = [self projection];
    
    // setup the orthographic projection using the world space bounds
    glOrtho(proj->left, proj->right, proj->bottom, proj->top, 0.0f, 1.0f);
    glTranslatef(-proj->x, -proj->y, 0.0f);
    glRotatef(proj->angle, 0.0f, 0.0f, 1.0f);
    glScalef(proj->z, proj->z, 1.0f);
    
    // switch back to the previous mode
	glMatrixMode(mode);
}

- (void)applyScaleMatrix
{
    Projection* proj = [self projection];
    
    // calculate the scale for quads
    float sx = (proj->right - proj->left) / proj->width;
    float sy = (proj->top - proj->bottom) / proj->height;
    
    // ensure that textures render pixel-perfect
    glScalef(sx, sy, 1.0f);
}

- (void)pushDefaultProjection:(NSSize)size
{
    Projection proj;
    
    // save the size and set the default bounds
    proj.width = size.width;
    proj.height = size.height;
    proj.left = 0.0f;
    proj.bottom = 0.0f;
    proj.right = size.width - 1.0f;
    proj.top = size.height - 1.0f;
    
    // identity transform
    proj.x = 0.0f;
    proj.y = 0.0f;
    proj.angle = 0.0f;
    proj.z = 1.0f;
    
    // push the projection onto the stack
    [m_stack addObject:[NSData dataWithBytes:&proj length:sizeof(proj)]];
}

- (void)setOrigin:(NSPoint)origin width:(float)width
{
    Projection* proj = [self projection];
    
    // calculate what the height should be to maintain the aspect ratio
    float height = width / (proj->width / proj->height);
    
    // setup the orthographic projection coordinates
    proj->left = origin.x - (width / 2);
    proj->right = origin.x + (width / 2);
    proj->bottom = origin.y - (height / 2);
    proj->top = origin.y + (height / 2);
}

- (void)zoom:(float)z
{
    [self projection]->z = z;
}

- (void)setPosition:(NSPoint)point
{
    Projection* proj = [self projection];
    
    proj->x = point.x;
    proj->y = point.y;
}

- (void)setAngle:(float)degrees
{
    [self projection]->angle = degrees;
}

- (void)translateBy:(NSPoint)delta global:(BOOL)global
{
    float dx = delta.x;
    float dy = delta.y;
    
    if (global == NO) {
        // TODO:
    }
    
    // get the current projection
    Projection* proj = [self projection];
    
    // translate
    proj->x += dx;
    proj->y += dy;
}

- (void)rotateBy:(float)degrees
{
    Projection* proj = [self projection];
    
    // wrap around so angles don't grow too large
    proj->angle = fmod(proj->angle + degrees, 360.0f);
}

/*
 * LUA INTERFACE
 */

- (int)l_push:(lua_State*)L
{
    return [self push], 0;
}

- (int)l_pop:(lua_State*)L
{
    return [self pop], 0;
}

- (int)l_setBounds:(lua_State*)L
{
    float x = lua_tonumber(L, 1);
    float y = lua_tonumber(L, 2);
    float w = lua_tonumber(L, 3);
    
    return [self setOrigin:NSMakePoint(x, y) width:w], 0;
}

- (int)l_bounds:(lua_State*)L
{
    Projection* proj = [self projection];
    
    lua_newtable(L);
    lua_pushnumber(L, proj->left);
    lua_setfield(L, -2, "left");
    lua_pushnumber(L, proj->bottom);
    lua_setfield(L, -2, "bottom");
    lua_pushnumber(L, proj->right);
    lua_setfield(L, -2, "right");
    lua_pushnumber(L, proj->top);
    lua_setfield(L, -2, "top");
    lua_pushnumber(L, proj->right - proj->left);
    lua_setfield(L, -2, "width");
    lua_pushnumber(L, proj->top - proj->bottom);
    lua_setfield(L, -2, "height");
    
    return 1;
}

- (int)l_position:(lua_State*)L
{
    lua_pushnumber(L, [self x]);
    lua_pushnumber(L, [self y]);
    
    return 2;
}

- (int)l_setPosition:(lua_State*)L
{
    float x = lua_tonumber(L, 1);
    float y = lua_tonumber(L, 2);
    
    return [self setPosition:NSMakePoint(x, y)], 0;
}

- (int)l_scroll:(lua_State*)L
{
    float dx = lua_tonumber(L, 1);
    float dy = lua_tonumber(L, 2);
    
    return [self translateBy:NSMakePoint(dx, dy) global:YES], 0;
}

- (int)l_zoom:(lua_State*)L
{
    return [self zoom:lua_tonumber(L, 1)], 0;
}

@end
