// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Atlas.h"

typedef enum {
    // window/placard elements
    Window_LL,
    Window_LM,
    Window_LR,
    Window_ML,
    Window_MM,
    Window_MR,
    Window_UL,
    Window_UM,
    Window_UR,
    
    // button elements
    Button_Unpressed,
    Button_Pressed,
    
    // checkbox elements
    Checkbox_Off,
    Checkbox_On,
    
    // total number of UI elements
    UI_Element_Count,
} UIElementIndex;

typedef struct {
    unsigned long frame;
    NSSize size;
} UIElement;

@interface Skin : Atlas
{
    UIElement m_elt[UI_Element_Count];
}

// fetch a UI element (NULL if it doesn't exist)
- (UIElement*)uiElement:(UIElementIndex)i;

@end
