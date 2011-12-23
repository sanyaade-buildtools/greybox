// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Script.h"

typedef struct {
    unsigned int hits;
    BOOL status;
} State;

typedef struct {
    State key[256];
} Keyboard;

typedef struct {
    State button[16];
    float x, y;
    float dx, dy;
} Mouse;

typedef enum {
    Key_A = 0,
    Key_B = 11,
    Key_C = 8,
    Key_D = 2,
    Key_E = 14,
    Key_F = 3,
    Key_G = 5,
    Key_H = 4,
    Key_I = 34,
    Key_J = 38,
    Key_K = 40,
    Key_L = 37,
    Key_M = 46,
    Key_N = 45,
    Key_O = 31,
    Key_P = 35,
    Key_Q = 12,
    Key_R = 15,
    Key_S = 1,
    Key_T = 17,
    Key_U = 32,
    Key_V = 9,
    Key_W = 13,
    Key_X = 7,
    Key_Y = 16,
    Key_Z = 6,
    Key_1 = 18,
    Key_2 = 19,
    Key_3 = 20,
    Key_4 = 21,
    Key_5 = 23,
    Key_6 = 22,
    Key_7 = 26,
    Key_8 = 28,
    Key_9 = 25,
    Key_0 = 29,
    
    // named keys
    Key_Space = 49,
    Key_Tilde = 50,
    Key_Escape = 53,
    Key_Minus = 27,
    Key_Plus = 24,
    Key_LeftBracket = 33,
    Key_RightBracket= 30,
    Key_Backslash = 42,
    Key_Colon = 41,
    Key_Quote = 39,
    Key_Comma = 43,
    Key_Period = 47,
    Key_Slash = 44,
    Key_Backspace = 51,
    Key_Return = 36,
    Key_Tab = 48,
    Key_Up = 126,
    Key_Left = 123,
    Key_Right = 124,
    Key_Down = 125,
    Key_PageUp = 116,
    Key_PageDown = 121,
    Key_Home = 115,
    Key_End = 119,
    Key_Delete = 117,
    Key_Clear = 71,
    
    // number pad keys
    Key_NumPad_Equal = 81,
    Key_NumPad_Divide = 75,
    Key_NumPad_Times = 67,
    Key_NumPad_Minus = 78,
    Key_NumPad_Plus = 69,
    Key_NumPad_Dot = 65,
    Key_NumPad_Enter = 76,
    Key_NumPad_1 = 83,
    Key_NumPad_2 = 84,
    Key_NumPad_3 = 85,
    Key_NumPad_4 = 86,
    Key_NumPad_5 = 87,
    Key_NumPad_6 = 88,
    Key_NumPad_7 = 89,
    Key_NumPad_8 = 91,
    Key_NumPad_9 = 92,
    Key_NumPad_0 = 82,
    
    // function keys
    Key_F1 = 122,
    Key_F2 = 120,
    Key_F3 = 99,
    Key_F4 = 118,
    Key_F5 = 96,
    Key_F6 = 97,
    Key_F7 = 98,
    Key_F8 = 100,
    Key_F9 = 101,
    Key_F10 = 109,
} Key;

typedef enum {
    Button_Left = 0,
    Button_Right = 1,
    Button_Middle = 2,
} Button;

@interface Input : NSObject <ScriptInterface>
{
    Keyboard m_keyboard;
    Mouse m_mouse;
}

// initialization methods
- (id)init;

// reset input states
- (void)flushMouse:(BOOL)reset;
- (void)flushKeyboard:(BOOL)reset;
- (void)flush:(BOOL)reset;

// validation predicates
- (BOOL)validKey:(Key)key;
- (BOOL)validButton:(Button)button;

// simulate button presses
- (void)pressKey:(Key)key;
- (void)pressButton:(Button)button;

// simulate button releases
- (void)releaseKey:(Key)key;
- (void)releaseButton:(Button)button;

// update the mouse position
- (void)setMousePosition:(NSPoint)pos;

// state predicates
- (BOOL)keyDown:(Key)key;
- (BOOL)keyPressed:(Key)key;
- (BOOL)buttonDown:(Button)button;
- (BOOL)buttonPressed:(Button)button;

// button hit counts
- (unsigned int)keyHits:(Key)key;
- (unsigned int)buttonHits:(Button)button;

// mouse position and speed
- (NSPoint)mousePosition;
- (NSPoint)mouseDelta;

@end