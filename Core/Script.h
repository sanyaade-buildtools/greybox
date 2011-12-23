// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "lua.h"
#import "lualib.h"
#import "lauxlib.h"
#import "lapi.h"
#import "lstate.h"

// interface for objects that can be registered
@protocol ScriptInterface;

// registered script method
@interface ScriptMethod : NSObject
@property (readwrite,assign) NSString* name;
@property (readwrite,assign) SEL sel;
@end

// registered script contants
@interface ScriptConstant : NSObject
@property (readwrite,assign) NSString* name;
@property (readwrite,assign) id value;
@end

@interface Script : NSObject
{
	lua_State* m_lua;
	int m_ref;
}

// allocator methods
+ (Script*)sharedInstance;

// create constants and methods to register
+ (ScriptConstant*)constantWithName:(NSString*)name value:(id)value;
+ (ScriptMethod*)methodWithName:(NSString*)name selector:(SEL)sel;

// internal lua state accessor
- (lua_State*)L;

// registry index
- (int)ref;

// spawn a child of this thread with its own local environment
- (Script*)newThreadWithNamespace:(NSString*)name;
- (Script*)newThread;

// precompile and compile a script, compile will leave it on the stack
- (BOOL)precompile:(NSString*)fileName;
- (BOOL)compile:(NSString*)fileName;

// load a script off disk
- (BOOL)loadScript:(NSString*)fileName withNamespace:(NSString*)name;
- (BOOL)loadScript:(NSString*)fileName;

// let an object register its namespace table
- (void)registerObject:(id <ScriptInterface>)object withNamespace:(NSString*)name;
- (void)registerObject:(id <ScriptInterface>)object withNamespace:(NSString*)name locked:(BOOL)locked;

// register methods and constants with a namespace table
- (void)registerMethods:(NSArray*)methods
              constants:(NSArray*)constants
              forObject:(id)object 
          withNamespace:(NSString*)name;

// push value to any lua state
+ (BOOL)push:(id)value to:(lua_State*)L;

// push a value onto the lua stack
- (BOOL)push:(id)value;

// push this thread's environment to another state or this state
- (void)pushEnvTo:(lua_State*)L;
- (void)pushEnv;

// bind a value to the environment
- (BOOL)bind:(id)value to:(NSString*)name;

// call a lua function in the script
- (BOOL)call:(const char*)func;
- (BOOL)call:(const char*)func withArgs:(int)n;

// parse and execute a lua command
- (BOOL)eval:(const char*)string;

// dumps the last error to the console
- (BOOL)logError;

@end

// helper macros for defining a script constants and methods to register
#define script_Constant(name,val) [Script constantWithName:name value:val]
#define script_Method(name,sel) [Script methodWithName:name selector:sel]

// registering objects must implement this
@protocol ScriptInterface
@optional
- (NSArray*)scriptConstants;
- (NSArray*)scriptMethods;
@end