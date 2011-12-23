// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Atlas.h"
#import "Engine.h"
#import "Font.h"
#import "Intro.h"
#import "Texture.h"

@implementation Engine

+ (BOOL)launchWithProject:(NSString*)projectFileName
{
    NSAutoreleasePool* pool;
    Project* project;
    Engine* engine;
    
    // create a release pool for the application
    pool = [[NSAutoreleasePool alloc] init];
        
    // load the project bundle with all the resources
    if ((project = [Project projectWithPath:projectFileName]) == nil) {
        return FALSE;
    }
    
    // create the engine, and 
    if ((engine = [[Engine alloc] initWithProject:project]) == nil) {
        return FALSE;
    }
    
    // create the application and start the game
    [engine launchWithApp:[NSApplication sharedApplication]]; 
    [pool release];
    
    return TRUE;
}

- (id)initWithProject:(Project*)project
{
    // there can only be one!
    if (theEngine != nil) {
        return nil;
    }
    
    // initialize superclass
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // save the project for settings and resources
    m_project = [project retain];
    
    // initialize the lua environment
    m_script = [[Script sharedInstance] newThread];
        
    // initialize all major subsystems
    m_audio = [[Audio alloc] init];
    m_input = [[Input alloc] init];
    m_random = [[Random alloc] init];
    m_gui = [[GUI alloc] init];
    m_clock = [[Clock alloc] init];
    m_camera = [[Camera alloc] init];
    m_network = [[Network alloc] init];
    m_world = [[World alloc] init];
    
    // register subsystem methods
    [m_script registerObject:self withNamespace:@"engine" locked:YES];
    [m_script registerObject:m_project withNamespace:@"project" locked:YES];
    [m_script registerObject:m_audio withNamespace:@"audio" locked:YES];
    [m_script registerObject:m_gui withNamespace:@"gui" locked:YES];
    [m_script registerObject:m_input withNamespace:@"input" locked:YES];
    [m_script registerObject:m_clock withNamespace:@"clock" locked:YES];
    [m_script registerObject:m_random withNamespace:@"random" locked:YES];
    [m_script registerObject:m_camera withNamespace:@"camera" locked:YES];
    [m_script registerObject:m_network withNamespace:@"net" locked:YES];
    [m_script registerObject:m_world withNamespace:@"world" locked:YES];
    
    // no current or pending scene
    m_pendingScene = nil;
    m_scene = nil;
    
    // set the global engine object
    theEngine = self;
    
    // load, compile, set defaults, etc. Must happen after theEngine is set
    [self loadAndPrecompileScripts];
    [self loadGlobalUserScripts];
    [self loadDefaultAssets];
    
    // set the default skin for the gui
    [m_gui setSkin:nil];
    
    return self;
}

- (void)dealloc
{
    [m_userEnv release];
    [m_script release];
    [m_scene release];
    [m_pendingScene release];
    [m_world release];
    [m_gui release];
    [m_input release];
    [m_random release];
    [m_clock release];
    [m_network release];
    [m_project release];
    [super dealloc];
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"quit", @selector(l_quit:)),
            nil];
}

- (Display*)createDisplay;
{
    NSNumber* w = [m_project settingForKey:@"Display Width" 
                               withDefault:[NSNumber numberWithFloat:640.0f]];
    NSNumber* h = [m_project settingForKey:@"Display Height"
                               withDefault:[NSNumber numberWithFloat:480.0f]];
    
    // define the size of the display
    NSRect frame = NSMakeRect(0, 0, [w floatValue], [h floatValue]);
    
    // create the display
    if ((m_display = [[Display alloc] initWithFrame:frame]) == nil) {
        return nil;
    }
    
    // add the display to the script
    [m_script registerObject:m_display withNamespace:@"display"];
    
    // initialize display
    [m_display setTitle:[m_project settingForKey:@"Display Title" withDefault:@""]];
    [m_display setInputDelegate:m_input];
    [m_display setDelegate:self];
    
    // setup the camera projection to the default for the display
    [m_camera pushDefaultProjection:[[m_display contentView] frame].size];
    
    return [[m_display retain] autorelease];
}

- (Project*)project
{
    return [[m_project retain] autorelease];
}

- (Audio*)audio
{
    return [[m_audio retain] autorelease];
}

- (Clock*)clock
{
    return [[m_clock retain] autorelease];
}

- (Display*)display
{
    return [[m_display retain] autorelease];
}

- (GUI*)gui
{
    return [[m_gui retain] autorelease];
}

- (Input*)input
{
    return [[m_input retain] autorelease];
}

- (Random*)random
{
    return [[m_random retain] autorelease];
}

- (Script*)script
{
    return [[m_script retain] autorelease];
}

- (Scene*)scene
{
    return [[m_scene retain] autorelease];
}

- (Camera*)camera
{
    return [[m_camera retain] autorelease];
}

- (Network*)network
{
    return [[m_network retain] autorelease];
}

- (World*)world
{
    return [[m_world retain] autorelease];
}

- (void)loadAndPrecompileScripts
{
    NSBundle* main = [NSBundle mainBundle];
    
    // get the project scripts and default scripts
    NSArray* projectScripts = [m_project pathsForResourcesOfType:@"lua" inDirectory:nil];
    NSArray* defaultScripts = [main pathsForResourcesOfType:@"lua" inDirectory:nil];
    
    // loop over all the scripts in the project
    for(NSString* file in [defaultScripts arrayByAddingObjectsFromArray:projectScripts]) {
        [m_script precompile:file];
    }
}

- (void)loadGlobalUserScripts
{
    id scripts = [m_project settingForKey:@"Global Scripts" 
                              withDefault:[NSDictionary dictionary]];
    
    // create the game namespace
    m_userEnv = [m_script newThreadWithNamespace:@"game"];
    
    // make sure the scripts entry exists and is
    if ([scripts isKindOfClass:[NSDictionary class]] == NO) {
        return;
    }
    
    // loop over all the startup scripts
    for(NSString* script in scripts) {
        id fileName = [scripts objectForKey:script];
        id pathName;
        
        // make sure it's a valid filename
        if ([fileName isKindOfClass:[NSString class]] == NO) {
            NSLog(@"Startup script %@ is not a valid filename\n", script);
            continue;
        }
        
        // make sure it exists
        if ((pathName = [m_project pathForResource:fileName ofType:nil]) == nil) {
            NSLog(@"Cannot find startup script %@ in the project\n", fileName);
            continue;
        }
        
        // load the script and assign a namespace for it
        if ([m_userEnv loadScript:pathName withNamespace:script] == FALSE) {
            continue;
        }
    }
}

- (void)loadDefaultAssets
{
    NSArray* assets = [NSArray arrayWithObjects:
                       [[Texture alloc] initWithName:@"logo" path:@"logo.png"],
                       [[Texture alloc] initWithPath:@"missing.png"],
                       [[Font alloc] initWithPath:@"font.xml"],
                       [[Skin alloc] initWithPath:@"skin.xml"],
                       nil];
    
    // load all the default assets
    [m_project loadDefaultAssetGroup:assets];
}

- (BOOL)loadScene:(NSString*)name
{
    NSDictionary* scenes;
    NSString* file;
    Script* script;
    
    // can't load multiple scenes in a queue
    if (m_pendingScene != nil) {
        NSLog(@"Scene change already pending\n");
        return FALSE;
    }
    
    // attempt to fetch the scene map
    if ((scenes = [m_project settingForKey:@"Scenes"]) == nil) {
        NSLog(@"No scenes found in project\n");
        return FALSE;
    }
    
    // lookup the source file
    if ((file = [scenes objectForKey:name]) == nil) {
        NSLog(@"Scene %@ doesn't exist in the project\n", name);
        return FALSE;
    }
    
    // create a child script off the engine
    script = [[m_script newThread] autorelease];
    
    // attempt to load it
    if ([script loadScript:file] == FALSE) {
        NSLog(@"Failed to load scene %@\n", name);
        return FALSE;
    }
    
    // create the new scene
    if ((m_pendingScene = [[Scene alloc] initWithScript:script]) == nil) {
        NSLog(@"Failed to enter scene %@\n", name);
        return FALSE;
    }

    return TRUE;
}

- (void)launchWithApp:(NSApplication*)app
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    // create a default display if none exists
    if (m_display || [self createDisplay]) {
        if ((m_app = [app retain]) != nil) {
            [m_app setDelegate:self];
            [m_app run];
        }
    }
    
    // free all unrelcaimed memory
    [pool release];
}

- (void)stepFrame:(id)userinfo
{
    // prepare frame dependencies
    [m_audio makeCurrent];
    
    // phases of the frame
    [self advance];
    [self render];
    [self update];
}

- (void)start
{
    // start stepping frames
    [NSTimer scheduledTimerWithTimeInterval:5.0 / 1000.0
                                     target:self 
                                   selector:@selector(stepFrame:)
                                   userInfo:nil
                                    repeats:YES];
    
    // show the window
    [m_display makeKeyAndOrderFront:nil];
    
    // set the pending scene to the into splash screen
    m_pendingScene = [[Intro alloc] init];
}

- (void)advance
{
    // update the game clock and framerate
    [m_clock advance];
    
    // update physics (before actors are advanced)
    [m_world step:[m_clock deltaTime]];
    
    // advance all actors in the scene
    [m_scene advance];
}

- (void)render
{
    [m_display prepare];
    {
        [m_camera loadProjectionMatrix];
        [m_scene render];
        
        // perform all the GUI rendering
        [m_gui startRendering:[[m_display contentView] frame].size];
        {
            [m_scene gui];
        }
        [m_gui stopRendering];
    }
    [m_display present];
}

- (void)update
{
    if (m_pendingScene == nil) {
        [m_scene update];
    } else {
        // free the current scene
		[m_scene release];
		
		// enter the new scene
		m_scene = m_pendingScene;
		m_pendingScene = nil;
        
        // register the scene with the engine script
        [m_script registerObject:m_scene withNamespace:@"scene"];
		
		// start loading resources, etc.
		[m_scene start];
    }
    
    // reset the hit counters for buttons and mouse delta
    [m_input flush:NO];
    
    // check audio for completed sounds
    [m_audio update];
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    [self start];
}

- (BOOL)applicationShouldTerminate:(id)sender
{
    return TRUE;
}

- (void)windowWillClose:(NSNotification*)notification
{
    [m_app terminate:notification];
}

/*
 * LUA INTERFACE
 */

- (int)l_quit:(lua_State*)L
{
    return [m_display close], 0;
}

- (int)l_loadScene:(lua_State*)L
{
    NSString* fileName;
    
    // pull the filename from the script
    if ((fileName = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return lua_pushboolean(L, 0), 1;
    }
    
    // try and load the scene
    if ([self loadScene:fileName] == FALSE) {
        return lua_pushboolean(L, 0), 1;
    }
    
    return lua_pushboolean(L, 1), 1;
}

@end

// the one and only engine object
Engine* theEngine = nil;
