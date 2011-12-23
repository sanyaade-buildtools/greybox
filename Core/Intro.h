// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Scene.h"

typedef enum
{
    Splashscreen_Stage_EaseIn,
    Splashscreen_Stage_EaseOut,
    Splashscreen_Stage_Delay,
} Splashscreen_Stage;

#define Splashscreen_Ease_Time (3.0f)

@interface Intro : Scene
{
    Texture* m_logo;
    
    // current stage
    Splashscreen_Stage m_stage;
    
    // countdown timers
    float m_easeIn;
    float m_easeOut;
    float m_delay;
}
@end
