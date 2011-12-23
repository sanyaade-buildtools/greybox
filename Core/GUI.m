// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Engine.h"
#import "GUI.h"

@implementation GUI

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_color = [[NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:1] retain];
    m_skin = nil;
    m_rendering = NO;
    
    return self;
}

- (void)dealloc
{
    [m_color release];
    [super dealloc];
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"set_skin", @selector(l_setSkin:)),
            script_Method(@"set_color", @selector(l_setColor:)),
            script_Method(@"draw_line", @selector(l_drawLine:)),
            script_Method(@"draw_rect", @selector(l_drawRect:)),
            script_Method(@"draw_string", @selector(l_drawString:)),
            script_Method(@"window", @selector(l_window:)),
            script_Method(@"checkbox", @selector(l_checkbox:)),
            script_Method(@"button", @selector(l_button:)),
            nil];
}

- (void)startRendering:(NSSize)size
{
    if (m_rendering == YES) {
        return;
    }
    
    // setup the projection matrix, force normal display coordinates
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0f, size.width - 1.0f, 0.0f, size.height - 1.0f, 0.0f, 1.0f);
    
    // reset the matrix
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    // now rendering
    m_rendering = YES;
    
    // save the size of the display
    m_size = size;
}

- (void)stopRendering
{
    m_rendering = NO;
}

- (NSPoint)uiPos:(NSPoint)pt
{
    return NSMakePoint(pt.x < 0 ? pt.x + m_size.width : pt.x, 
                       pt.y < 0 ? pt.y + m_size.height : pt.y);
}

- (void)setSkin:(NSString*)name
{
    m_skin = [theProject assetWithName:name type:[Skin class]];
}

- (void)setColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a
{
    if (m_color != nil) {
        [m_color release];
    }
    
    // create the new color
    m_color = [[NSColor colorWithDeviceRed:r green:g blue:b alpha:a] retain];
}

- (void)drawLine:(NSPoint)from to:(NSPoint)to
{
    if (m_rendering) {
        float vb[4] = { from.x, from.y, to.x, to.y };
        
        // turn off textures
        glDisable(GL_TEXTURE_2D);
        
        // set the current color
        glColor4f([m_color redComponent],
                  [m_color greenComponent],
                  [m_color blueComponent],
                  [m_color alphaComponent]);
        
        // from the origin
        glLoadIdentity();
        
        // set the vertex and texcoord pointers
        glVertexPointer(2, GL_FLOAT, sizeof(GLfloat) * 2, &vb[0]);
        glTexCoordPointer(2, GL_FLOAT, sizeof(GLfloat) * 2, NULL);
        
        // draw a simple triangle fan
        glDrawArrays(GL_LINES, 0, 2);
    }
}

- (void)drawRect:(NSRect)rect filled:(BOOL)filled
{
    if (m_rendering) {
        float vb[10] = { 
            rect.origin.x, 
            rect.origin.y, 
            rect.origin.x + rect.size.width,
            rect.origin.y,
            rect.origin.x + rect.size.width,
            rect.origin.y + rect.size.height,
            rect.origin.x,
            rect.origin.y + rect.size.height,
            rect.origin.x, 
            rect.origin.y, 
            };
        
        // turn off textures
        glDisable(GL_TEXTURE_2D);
        
        // set the current color
        glColor4f([m_color redComponent],
                  [m_color greenComponent],
                  [m_color blueComponent],
                  [m_color alphaComponent]);
        
        // from the origin
        glLoadIdentity();
        
        // set the vertex and texcoord pointers
        glVertexPointer(2, GL_FLOAT, sizeof(GLfloat) * 2, &vb[0]);
        glTexCoordPointer(2, GL_FLOAT, sizeof(GLfloat) * 2, NULL);
        
        // draw a simple triangle fan
        if (filled) {
            glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        } else {
            glDrawArrays(GL_LINE_STRIP, 0, 5);
        }
    }
}

- (void)drawString:(NSString*)string at:(NSPoint)point withFont:(Font*)font
{
    if (font == nil) {
       // TODO: use the default font 
    }
    
    // 
    if (m_rendering && string != nil && font != nil) {
        glEnable(GL_TEXTURE_2D);
        
        // set the current color
        glColor4f([m_color redComponent],
                  [m_color greenComponent],
                  [m_color blueComponent],
                  [m_color alphaComponent]);
        
        // translate to the given point
        glLoadIdentity();
        glTranslatef(point.x, point.y, 0.0f);
        
        // draw it
        [font render:string];
    }
}

- (UIElement*)blitUIElement:(UIElementIndex)frame from:(NSPoint)from to:(NSPoint)to
{
    return [self blitUIElement:frame to:NSMakeRect(from.x, from.y, to.x - from.x, from.y - to.y)];
}

- (UIElement*)blitUIElement:(UIElementIndex)frame to:(NSRect)rect
{
    UIElement* elt;
    
    // make sure the element exists
    if ((elt = [m_skin uiElement:frame]) == NULL) {
        return NULL;
    }
    
    // calculate the scale factor
    float scaleX = rect.size.width / elt->size.width;
    float scaleY = rect.size.height / elt->size.height;
    
    glPushMatrix();
    {
        static float M[16] = {
            1.0f, 0.0f, 0.0f, 0.0f,
            0.0f, 1.0f, 0.0f, 0.0f, 
            0.0f, 0.0f, 1.0f, 0.0f, 
            0.0f, 0.0f, 0.0f, 1.0f, 
        };
        
        // use skin colors (no blending)
        glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        // use the shared matrix
        M[ 0] = scaleX;
        M[ 5] = scaleY;
        M[12] = rect.origin.x + (elt->size.width * scaleX * 0.5f);
        M[13] = rect.origin.y + (elt->size.height * scaleY * 0.5f);
        
        // load the matrix
        glLoadMatrixf(M);
        
        // render the texture
        [m_skin render:elt->frame];
    }
    glPopMatrix();
    
    return elt;
}

- (UIElement*)blitUIElement:(UIElementIndex)frame at:(NSPoint)point
{
    UIElement* elt;
    
    // make sure the element exists
    if ((elt = [m_skin uiElement:frame]) == NULL) {
        return NULL;
    }
    
    // use the exact size of the element to render it
    NSRect rect = { point, elt->size };
    
    // blit to a perfect rect
    return [self blitUIElement:frame to:rect];
}

- (void)renderWindow:(NSRect)rect
{
    UIElement* ll = [m_skin uiElement:Window_LL];
    UIElement* lm = [m_skin uiElement:Window_LM];
    UIElement* lr = [m_skin uiElement:Window_LR];
    UIElement* ml = [m_skin uiElement:Window_ML];
    UIElement* mr = [m_skin uiElement:Window_MR];
    UIElement* ul = [m_skin uiElement:Window_UL];
    UIElement* um = [m_skin uiElement:Window_UM];
    UIElement* ur = [m_skin uiElement:Window_UR];
    
    // calculate the corner points
    float x1 = rect.origin.x;
    float x2 = rect.origin.x + rect.size.width;
    float y1 = rect.origin.y;
    float y2 = rect.origin.y + rect.size.height;
    
    // calculate the corner positions
    NSPoint llp = NSMakePoint(x1, y1);
    NSPoint lrp = NSMakePoint(x2 - lr->size.width, y1);
    NSPoint urp = NSMakePoint(x2 - ur->size.width, y2 - ur->size.height);
    NSPoint ulp = NSMakePoint(x1, y2 - ul->size.height);
    
    // calculate the top/bottom widths and left/right heights
    float tw = urp.x - (ulp.x + ul->size.width);
    float bw = lrp.x - (llp.x + ll->size.width);
    float lh = ulp.y - (llp.y + ll->size.height);
    float rh = urp.y - (lrp.y + lr->size.height);
    
    // calculate edge rects
    NSRect lmr = NSMakeRect(llp.x + ll->size.width, llp.y, bw, lm->size.height);
    NSRect umr = NSMakeRect(ulp.x + ul->size.width, ulp.y, tw, um->size.height);
    NSRect mlr = NSMakeRect(llp.x, llp.y + ll->size.height, ml->size.width, lh);
    NSRect mrr = NSMakeRect(lrp.x, lrp.y + lr->size.height, mr->size.width, rh);
    
    // calculate the middle rect
    NSRect mmr = NSMakeRect(llp.x + ll->size.width, llp.y + ll->size.height, tw, lh);
    
    // render each element of the window placard
    [self blitUIElement:Window_LL at:llp];
    [self blitUIElement:Window_LR at:lrp];
    [self blitUIElement:Window_UL at:ulp];
    [self blitUIElement:Window_UR at:urp];
    [self blitUIElement:Window_ML to:mlr];
    [self blitUIElement:Window_MR to:mrr];
    [self blitUIElement:Window_LM to:lmr];
    [self blitUIElement:Window_UM to:umr];
    [self blitUIElement:Window_MM to:mmr];
}

- (BOOL)renderCheckboxWithState:(BOOL)state at:(NSPoint)point
{
    UIElement* elt;
    
    if (state == FALSE) {
        elt = [self blitUIElement:Checkbox_Off at:point];
    } else {
        elt = [self blitUIElement:Checkbox_On at:point];
    }
    
    // get the mouse position and check for inside the checkbox
    if ([theInput buttonPressed:Button_Left] == YES) {
        NSRect r = { point, elt->size };
        
        if (NSPointInRect([theInput mousePosition], r) == YES) {
            return !state;
        }
    }
    
    return state;
}

- (BOOL)renderButtonWithValue:(NSString*)value at:(NSPoint)point
{
    UIElement* elt;
    BOOL state;
    
    // make sure the element exists
    if ((elt = [m_skin uiElement:Button_Unpressed]) == NULL) {
        return FALSE;
    }
    
    // TODO: calculate the size of the text and render appropriately
    
    // unpressed button
    state = FALSE;
    
    // get the mouse position and check for inside the checkbox
    if ([theInput buttonDown:Button_Left] == YES) {
        NSRect r = { point, elt->size };
        
        if (NSPointInRect([theInput mousePosition], r) == YES) {
            state = TRUE;
        }
    }
    
    // render the button either clicked or not
    if (state == FALSE) {
        elt = [self blitUIElement:Button_Unpressed at:point];
    } else {
        elt = [self blitUIElement:Button_Pressed at:point];
    }
    
    return state;
}

/*
 * LUA INTERFACE
 */

- (int)l_setSkin:(lua_State*)L
{
    NSString* name;
    
    // get the skin name
    if ((name = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return 0;
    }
    
    return [self setSkin:name], 0;
}

- (int)l_setColor:(lua_State*)L
{
    float r = lua_tonumber(L, 1);
    float g = lua_tonumber(L, 2);
    float b = lua_tonumber(L, 3);
    float a = lua_tonumber(L, 4);
    
    // we want the alpha to default to 1.0, not 0.0
    if (lua_gettop(L) < 4) {
        a = 1.0;
    }
    
    // assign the color
    [self setColorRed:r green:g blue:b alpha:a];
    
    return 0;
}

- (int)l_drawLine:(lua_State*)L
{
    float x1 = lua_tonumber(L, 1);
    float y1 = lua_tonumber(L, 2);
    float x2 = lua_tonumber(L, 3);
    float y2 = lua_tonumber(L, 4);
    
    // draw the line
    [self drawLine:[self uiPos:NSMakePoint(x1, y1)]
                to:[self uiPos:NSMakePoint(x2, y2)]];
    
    return 0;
}

- (int)l_drawRect:(lua_State*)L
{
    float x = lua_tonumber(L, 1);
    float y = lua_tonumber(L, 2);
    float w = lua_tonumber(L, 3);
    float h = lua_tonumber(L, 4);
    
    NSRect rect;
    
    // determine the frame of the rect
    rect.origin = [self uiPos:NSMakePoint(x, y)];
    rect.size = NSMakeSize(w, h);
    
    // draw the rectangle
    [self drawRect:rect filled:lua_toboolean(L, 5)];
    
    return 0;
}

- (int)l_drawString:(lua_State*)L
{
    float x = lua_tonumber(L, 2);
    float y = lua_tonumber(L, 3);
    
    NSString* string = [NSString stringWithUTF8String:lua_tostring(L, 1)];
    NSString* fontName = [NSString stringWithUTF8String:lua_tostring(L, 4)];
    
    [self drawString:string
                  at:[self uiPos:NSMakePoint(x, y)]
            withFont:[theProject assetWithName:fontName type:[Font class]]];
    
    return 0;
}

- (int)l_window:(lua_State*)L
{
    float x = lua_tonumber(L, 1);
    float y = lua_tonumber(L, 2);
    float w = lua_tonumber(L, 3);
    float h = lua_tonumber(L, 4);
    
    // render the window placard
    [self renderWindow:NSMakeRect(x, y, w, h)];
    
    return 0;
}

- (int)l_button:(lua_State*)L
{
    NSString* value;
    
    // get the location
    float x = lua_tonumber(L, 1);
    float y = lua_tonumber(L, 2);
    
    // where to render the element
    NSPoint pt = [self uiPos:NSMakePoint(x, y)];
    
    // get the text
    if ((value = [NSString stringWithUTF8String:lua_tostring(L, 3)]) == nil) {
        value = @"";
    }
    
    // render the button, get the clicked state
    BOOL state = [self renderButtonWithValue:value at:pt];
    
    return lua_pushboolean(L, state), 1;
}

- (int)l_checkbox:(lua_State*)L
{
    float x = lua_tonumber(L, 1);
    float y = lua_tonumber(L, 2);
    
    // where to render the element
    NSPoint pt = [self uiPos:NSMakePoint(x, y)];
    
    // get the previous state
    BOOL state = lua_toboolean(L, 3);

    // render the checkbox, get the new state
    state = [self renderCheckboxWithState:state at:pt];
    
    return lua_pushboolean(L, state), 1;
}

@end
