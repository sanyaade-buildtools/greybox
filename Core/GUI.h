// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Font.h"
#import "Script.h"
#import "Skin.h"

@interface GUI : NSObject <ScriptInterface>
{
    // true while primitive rendering is allowed
    BOOL m_rendering;
    
    // various color settings
    NSColor* m_color;
    
    // display boundaries
    NSSize m_size;
    
    // the current GUI skin
    Skin* m_skin;
}

// control the state of GUI rendering operations
- (void)startRendering:(NSSize)size;
- (void)stopRendering;

// render state
- (void)setSkin:(NSString*)name;
- (void)setColorRed:(float)r green:(float)g blue:(float)b alpha:(float)a;

// primitive rendering
- (void)drawLine:(NSPoint)from to:(NSPoint)to;
- (void)drawString:(NSString*)string at:(NSPoint)point withFont:(Font*)font;

// blit textures to arbitrary areas
- (UIElement*)blitUIElement:(UIElementIndex)frame from:(NSPoint)from to:(NSPoint)to;
- (UIElement*)blitUIElement:(UIElementIndex)frame at:(NSPoint)point;
- (UIElement*)blitUIElement:(UIElementIndex)frame to:(NSRect)rect;

// render a window/placard
- (void)renderWindow:(NSRect)rect;

// render UI elements that have state
- (BOOL)renderCheckboxWithState:(BOOL)state at:(NSPoint)point;
- (BOOL)renderButtonWithValue:(NSString*)value at:(NSPoint)point;

@end
