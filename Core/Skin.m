// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Skin.h"

@implementation Skin

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    for(int i = 0;i < UI_Element_Count;i++) {
        m_elt[i].frame = -1UL;
    }
    
    return self;
}

- (void)loadUIElement:(UIElementIndex)i named:(NSString*)name
{
    if ((m_elt[i].frame = [self frameNamed:name]) != -1UL) {
        m_elt[i].size = [[self texture] sizeOfFrame:m_elt[i].frame];
    }
}

- (BOOL)loadFromDisk
{
    if ([super loadFromDisk] == FALSE) {
        return FALSE;
    }
    
    // window/placard elements
    [self loadUIElement:Window_LL named:@"window ll"];
    [self loadUIElement:Window_LM named:@"window lm"];
    [self loadUIElement:Window_LR named:@"window lr"];
    [self loadUIElement:Window_ML named:@"window ml"];
    [self loadUIElement:Window_MM named:@"window mm"];
    [self loadUIElement:Window_MR named:@"window mr"];
    [self loadUIElement:Window_UL named:@"window ul"];
    [self loadUIElement:Window_UM named:@"window um"];
    [self loadUIElement:Window_UR named:@"window ur"];
    
    // button elements
    [self loadUIElement:Button_Unpressed named:@"button unpressed"];
    [self loadUIElement:Button_Pressed named:@"button pressed"];
    
    // checkbox elements
    [self loadUIElement:Checkbox_Off named:@"checkbox off"];
    [self loadUIElement:Checkbox_On named:@"checkbox on"];
    
    return TRUE;
}

- (UIElement*)uiElement:(UIElementIndex)i
{
    return &m_elt[i];
}

@end
