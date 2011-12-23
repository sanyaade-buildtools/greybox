// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Input.h"

@implementation Input

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // reset the input states
    [self flush:YES];
    
    return self;
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"key_down", @selector(l_keyDown:)),
            script_Method(@"key_pressed", @selector(l_keyPressed:)),
            script_Method(@"key_hits", @selector(l_keyHits:)),
            nil];
}

- (NSArray*)scriptConstants
{
    return [NSArray arrayWithObjects:
            script_Constant(@"BUTTON_LEFT", [NSNumber numberWithInt:0]),
            script_Constant(@"BUTTON_RIGHT", [NSNumber numberWithInt:1]),
            script_Constant(@"BUTTON_MIDDLE", [NSNumber numberWithInt:2]),
            
            // standard keys
            script_Constant(@"KEY_A", [NSNumber numberWithInt:0]),
            script_Constant(@"KEY_B", [NSNumber numberWithInt:11]),
            script_Constant(@"KEY_C", [NSNumber numberWithInt:8]),
            script_Constant(@"KEY_D", [NSNumber numberWithInt:2]),
            script_Constant(@"KEY_E", [NSNumber numberWithInt:14]),
            script_Constant(@"KEY_F", [NSNumber numberWithInt:3]),
            script_Constant(@"KEY_G", [NSNumber numberWithInt:5]),
            script_Constant(@"KEY_H", [NSNumber numberWithInt:4]),
            script_Constant(@"KEY_I", [NSNumber numberWithInt:34]),
            script_Constant(@"KEY_J", [NSNumber numberWithInt:38]),
            script_Constant(@"KEY_K", [NSNumber numberWithInt:40]),
            script_Constant(@"KEY_L", [NSNumber numberWithInt:37]),
            script_Constant(@"KEY_M", [NSNumber numberWithInt:46]),
            script_Constant(@"KEY_N", [NSNumber numberWithInt:45]),
            script_Constant(@"KEY_O", [NSNumber numberWithInt:31]),
            script_Constant(@"KEY_P", [NSNumber numberWithInt:35]),
            script_Constant(@"KEY_Q", [NSNumber numberWithInt:12]),
            script_Constant(@"KEY_R", [NSNumber numberWithInt:15]),
            script_Constant(@"KEY_S", [NSNumber numberWithInt:1]),
            script_Constant(@"KEY_T", [NSNumber numberWithInt:17]),
            script_Constant(@"KEY_U", [NSNumber numberWithInt:32]),
            script_Constant(@"KEY_V", [NSNumber numberWithInt:9]),
            script_Constant(@"KEY_W", [NSNumber numberWithInt:13]),
            script_Constant(@"KEY_X", [NSNumber numberWithInt:7]),
            script_Constant(@"KEY_Y", [NSNumber numberWithInt:16]),
            script_Constant(@"KEY_Z", [NSNumber numberWithInt:6]),
            script_Constant(@"KEY_1", [NSNumber numberWithInt:18]),
            script_Constant(@"KEY_2", [NSNumber numberWithInt:19]),
            script_Constant(@"KEY_3", [NSNumber numberWithInt:20]),
            script_Constant(@"KEY_4", [NSNumber numberWithInt:21]),
            script_Constant(@"KEY_5", [NSNumber numberWithInt:23]),
            script_Constant(@"KEY_6", [NSNumber numberWithInt:22]),
            script_Constant(@"KEY_7", [NSNumber numberWithInt:26]),
            script_Constant(@"KEY_8", [NSNumber numberWithInt:28]),
            script_Constant(@"KEY_9", [NSNumber numberWithInt:25]),
            script_Constant(@"KEY_0", [NSNumber numberWithInt:29]),
            
            // named keys
            script_Constant(@"KEY_SPACE", [NSNumber numberWithInt:49]),
            script_Constant(@"KEY_TILDE", [NSNumber numberWithInt:50]),
            script_Constant(@"KEY_ESCAPE", [NSNumber numberWithInt:53]),
            script_Constant(@"KEY_MINUS", [NSNumber numberWithInt:27]),
            script_Constant(@"KEY_PLUS", [NSNumber numberWithInt:24]),
            script_Constant(@"KEY_LEFTBRACKET", [NSNumber numberWithInt:33]),
            script_Constant(@"KEY_RIGHTBRACKET", [NSNumber numberWithInt:30]),
            script_Constant(@"KEY_BACKSLASH", [NSNumber numberWithInt:42]),
            script_Constant(@"KEY_COLON", [NSNumber numberWithInt:41]),
            script_Constant(@"KEY_QUOTE", [NSNumber numberWithInt:39]),
            script_Constant(@"KEY_COMMA", [NSNumber numberWithInt:43]),
            script_Constant(@"KEY_PERIOD", [NSNumber numberWithInt:47]),
            script_Constant(@"KEY_SLASH", [NSNumber numberWithInt:44]),
            script_Constant(@"KEY_BACKSPACE", [NSNumber numberWithInt:51]),
            script_Constant(@"KEY_RETURN", [NSNumber numberWithInt:36]),
            script_Constant(@"KEY_TAB", [NSNumber numberWithInt:48]),
            script_Constant(@"KEY_UP", [NSNumber numberWithInt:126]),
            script_Constant(@"KEY_LEFT", [NSNumber numberWithInt:123]),
            script_Constant(@"KEY_RIGHT", [NSNumber numberWithInt:124]),
            script_Constant(@"KEY_DOWN", [NSNumber numberWithInt:125]),
            script_Constant(@"KEY_PAGEUP", [NSNumber numberWithInt:116]),
            script_Constant(@"KEY_PAGEDOWN", [NSNumber numberWithInt:121]),
            script_Constant(@"KEY_HOME", [NSNumber numberWithInt:115]),
            script_Constant(@"KEY_END", [NSNumber numberWithInt:119]),
            script_Constant(@"KEY_DELETE", [NSNumber numberWithInt:117]),
            script_Constant(@"KEY_CLEAR", [NSNumber numberWithInt:71]),
            
            // number pad keys
            script_Constant(@"KEY_NUMPAD_EQUAL", [NSNumber numberWithInt:81]),
            script_Constant(@"KEY_NUMPAD_DIVIDE", [NSNumber numberWithInt:75]),
            script_Constant(@"KEY_NUMPAD_TIMES", [NSNumber numberWithInt:64]),
            script_Constant(@"KEY_NUMPAD_MINUS", [NSNumber numberWithInt:78]),
            script_Constant(@"KEY_NUMPAD_PLUS", [NSNumber numberWithInt:69]),
            script_Constant(@"KEY_NUMPAD_DOT", [NSNumber numberWithInt:65]),
            script_Constant(@"KEY_NUMPAD_ENTER", [NSNumber numberWithInt:76]),
            script_Constant(@"KEY_NUMPAD_1", [NSNumber numberWithInt:83]),
            script_Constant(@"KEY_NUMPAD_2", [NSNumber numberWithInt:84]),
            script_Constant(@"KEY_NUMPAD_3", [NSNumber numberWithInt:85]),
            script_Constant(@"KEY_NUMPAD_4", [NSNumber numberWithInt:86]),
            script_Constant(@"KEY_NUMPAD_5", [NSNumber numberWithInt:87]),
            script_Constant(@"KEY_NUMPAD_6", [NSNumber numberWithInt:88]),
            script_Constant(@"KEY_NUMPAD_7", [NSNumber numberWithInt:89]),
            script_Constant(@"KEY_NUMPAD_8", [NSNumber numberWithInt:91]),
            script_Constant(@"KEY_NUMPAD_9", [NSNumber numberWithInt:92]),
            script_Constant(@"KEY_NUMPAD_0", [NSNumber numberWithInt:82]),
            
            // function keys
            script_Constant(@"KEY_F1", [NSNumber numberWithInt:122]),
            script_Constant(@"KEY_F2", [NSNumber numberWithInt:120]),
            script_Constant(@"KEY_F3", [NSNumber numberWithInt:99]),
            script_Constant(@"KEY_F4", [NSNumber numberWithInt:118]),
            script_Constant(@"KEY_F5", [NSNumber numberWithInt:96]),
            script_Constant(@"KEY_F6", [NSNumber numberWithInt:97]),
            script_Constant(@"KEY_F7", [NSNumber numberWithInt:98]),
            script_Constant(@"KEY_F8", [NSNumber numberWithInt:100]),
            script_Constant(@"KEY_F9", [NSNumber numberWithInt:101]),
            script_Constant(@"KEY_F10", [NSNumber numberWithInt:109]),
            nil];
}

- (void)flushMouse:(BOOL)reset
{
    int i;
    
    // wipe the button state for the mouse
    for(i = 0;i < sizeof(m_mouse.button) / sizeof(m_mouse.button[0]);i++) {
        if (reset) {
            m_mouse.button[i].status = NO;
        }
        
        // reset the hit count
        m_mouse.button[i].hits = 0;
    }
    
    // reset the position
    if (reset) {
        m_mouse.x = 0;
        m_mouse.y = 0;
    }
    
    // reset the current position
    m_mouse.dx = m_mouse.x;
    m_mouse.dy = m_mouse.y;
}

- (void)flushKeyboard:(BOOL)reset
{
    int i;
    
    // wipe the button state for the mouse
    for(i = 0;i < sizeof(m_keyboard.key) / sizeof(m_keyboard.key[0]);i++) {
        if (reset) {
            m_keyboard.key[i].status = NO;
        }
        
        // reset the hit count
        m_keyboard.key[i].hits = 0;
    }
}

- (void)flush:(BOOL)reset
{
    [self flushKeyboard:reset];
    [self flushMouse:reset];
}

- (BOOL)validKey:(Key)key
{
    return key < sizeof(m_keyboard.key) / sizeof(m_keyboard.key[0]);
}

- (BOOL)validButton:(Button)button
{
    return button < sizeof(m_mouse.button) / sizeof(m_mouse.button[0]);
}

- (void)pressKey:(Key)key
{
    if ([self validKey:key]) {
        m_keyboard.key[key].status = YES;
        m_keyboard.key[key].hits++;
    }
}

- (void)pressButton:(Button)button
{
    if ([self validButton:button]) {
        m_mouse.button[button].status = YES;
        m_mouse.button[button].hits++;
    }
}

- (void)releaseKey:(Key)key
{
    if ([self validKey:key]) {
        m_keyboard.key[key].status = NO;
    }
}

- (void)releaseButton:(Button)button
{
    if ([self validButton:button]) {
        m_mouse.button[button].status = NO;
    }
}

- (void)setMousePosition:(NSPoint)pos
{
    m_mouse.x = pos.x;
    m_mouse.y = pos.y;
}

- (BOOL)keyDown:(Key)key
{
    return [self validKey:key] && m_keyboard.key[key].status;
}

- (BOOL)keyPressed:(Key)key
{
    return [self keyHits:key] > 0;
}

- (BOOL)buttonDown:(Button)button
{
    return [self validButton:button] && m_mouse.button[button].status;
}

- (BOOL)buttonPressed:(Button)button
{
    return [self buttonHits:button] > 0;
}

- (unsigned int)keyHits:(Key)key
{
    unsigned int hits = 0;
    
    if ([self validKey:key]) {
        hits = m_keyboard.key[key].hits;
    }
    
    return hits;
}

- (unsigned int)buttonHits:(Button)button
{
    unsigned int hits = 0;
    
    if ([self validButton:button]) {
        hits = m_mouse.button[button].hits;
    }
    
    return hits;
}

- (NSPoint)mousePosition
{
    return NSMakePoint(m_mouse.x, m_mouse.y);
}

- (NSPoint)mouseDelta
{
    NSPoint d = NSMakePoint(m_mouse.x - m_mouse.dx, m_mouse.y - m_mouse.dy);
    
    // update the last known position
    m_mouse.dx = m_mouse.x;
    m_mouse.dy = m_mouse.y;
    
    return d;
}

/*
 * LUA INTERFACE
 */

- (int)l_keyDown:(lua_State*)L
{
    return lua_pushboolean(L, [self keyDown:lua_tonumber(L, 1)]), 1;
}

- (int)l_keyPressed:(lua_State*)L
{
    return lua_pushboolean(L, [self keyPressed:lua_tonumber(L, 1)]), 1;
}

- (int)l_keyHits:(lua_State*)L
{
    return lua_pushnumber(L, [self keyHits:lua_tonumber(L, 1)]), 1;
}

@end
