// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Engine.h"
#import "Intro.h"

@implementation Intro

- (void)start
{
    // fetch the logo
    m_logo = [theProject assetWithName:@"logo" type:[Texture class]];
    
    // default screen
    m_stage = Splashscreen_Stage_EaseIn;
    
    // countdown timers
    m_easeIn = Splashscreen_Ease_Time;
    m_easeOut = Splashscreen_Ease_Time;
    
    // how long the splash screen will be up for
    m_delay = 1.0f;
}

- (void)advance
{
    float dt = [theClock deltaTime];
    
    switch(m_stage) {
        case Splashscreen_Stage_EaseIn:
            if ((m_easeIn -= dt) < 0.0f) {
                m_stage = Splashscreen_Stage_Delay;
            }
            break;
            
        case Splashscreen_Stage_EaseOut:
            if ((m_easeOut -= dt) < 0.0f) {
                NSString* scene = [theProject settingForKey:@"Initial Scene"];
                
                if ([theEngine loadScene:scene] == NO) {
                    // TODO:
                }
            }
            break;
            
        case Splashscreen_Stage_Delay:
            if ((m_delay -= dt) < 0.0f) {
                m_stage = Splashscreen_Stage_EaseOut;
            }
            break;
    }
}

- (void)render
{
    float fade;
    float x;
    float y;
    float scale;
    
    switch(m_stage) {
        case Splashscreen_Stage_EaseIn:
            fade = 1.0f - (m_easeIn / Splashscreen_Ease_Time);
            break;
            
        case Splashscreen_Stage_EaseOut:
            fade = m_easeOut / Splashscreen_Ease_Time;
            break;
            
        case Splashscreen_Stage_Delay:
            fade = 1.0f;
            break;
    }
    
    NSSize frame = [[theDisplay contentView] frame].size;
    NSSize size = [m_logo size];
    
    // calculate the scale based on the display size
    if (frame.width < frame.height) {
        scale = frame.width * 3 / 4 / size.width;
    } else {
        scale = frame.height * 3 / 4 / size.height;
    }
    
    // clamp the scale size
    if (scale > 1.0f) {
        scale = 1.0f;
    }
    
    // center in the display
    x = frame.width / 2 - size.width * scale / 2;
    y = frame.height / 2 - size.height * scale / 2;
    
    // position in the center of the screen and set opacity
    glLoadIdentity();
    glColor4f(1.0f, 1.0f, 1.0f, fade);
    glTranslatef(x, y, 0.0f);
    glScalef(scale, scale, 1.0f);
    
    // display the logo on the screen
    [m_logo render];
}

- (void)update
{
    // do nothing - no script
}

- (void)leave
{
    // do nothing - no script
}

- (void)gui
{
    // do nothing - no script
}

@end
