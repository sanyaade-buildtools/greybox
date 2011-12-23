// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Audio.h"
#import "Camera.h"
#import "Clock.h"
#import "Display.h"
#import "GUI.h"
#import "Input.h"
#import "Network.h"
#import "Project.h"
#import "Random.h"
#import "Scene.h"
#import "Script.h"

@interface Engine : NSObject <NSApplicationDelegate, NSWindowDelegate, ScriptInterface>
{
    NSAutoreleasePool* m_pool;
    NSApplication* m_app;
    
    // major subsystems
    Project* m_project;
    Audio* m_audio;
    Clock* m_clock;
    Display* m_display;
    GUI* m_gui;
    Camera* m_camera;
    Input* m_input;
    Random* m_random;
    Script* m_script;
    Script* m_userEnv;
    Network* m_network;
    World* m_world;
    
    // current and pending scene
    Scene* m_scene;
    Scene* m_pendingScene;
}

// allocator methods
+ (BOOL)launchWithProject:(NSString*)projectFileName;

// initialization methods
- (id)initWithProject:(NSBundle*)bundle;

// create a new render context display
- (Display*)createDisplay;

// accessors
- (Project*)project;
- (Audio*)audio;
- (Clock*)clock;
- (Display*)display;
- (GUI*)gui;
- (Input*)input;
- (Random*)random;
- (Script*)script;
- (Scene*)scene;
- (Camera*)camera;
- (Network*)network;
- (World*)world;

// pre-load the project
- (void)loadAndPrecompileScripts;
- (void)loadGlobalUserScripts;
- (void)loadDefaultAssets;

// set the pending scene to switch to
- (BOOL)loadScene:(NSString*)name;

// called once per frame
- (void)stepFrame:(id)userinfo;

// phases of a frame step
- (void)start;
- (void)advance;
- (void)render;
- (void)update;

// start the game engine
- (void)launchWithApp:(NSApplication*)app;

// NSApplication delegate methods
- (void)applicationDidFinishLaunching:(NSNotification*)notification;
- (BOOL)applicationShouldTerminate:(id)sender;

// NSWindow delegate methods
- (void)windowWillClose:(NSNotification*)notification;

@end

// the one and only engine object
extern Engine* theEngine;

// helper macros
#define theProject [theEngine project]
#define theDisplay [theEngine display]
#define theInput   [theEngine input]
#define theGUI     [theEngine gui]
#define theScene   [theEngine scene]
#define theClock   [theEngine clock]
#define theCamera  [theEngine camera]
#define theNetwork [theEngine network]
#define theWorld   [theEngine world]