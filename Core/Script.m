// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Script.h"

#define CHECK_LUA_STACK

@implementation ScriptMethod
@synthesize name;
@synthesize sel;

- (void)dealloc
{
    [name release];
    [super dealloc];
}
@end

@implementation ScriptConstant
@synthesize name;
@synthesize value;

- (void)dealloc
{
    [value release];
    [name release];
    [super dealloc];
}
@end

static int l_chunkWriter(lua_State* L, const void* buf, long size, void* userdata)
{
    NSOutputStream* stream = (NSOutputStream*)userdata;
    
    // write more data to the stream
    if ([stream write:(const uint8_t*)buf maxLength:size] == 0) {
        return -1;
    }
    
    return 0;
}

static const char* l_chunkReader(lua_State* L, void* userdata, size_t* size)
{
    NSInputStream* stream = (NSInputStream*)userdata;
    
    // buffer to contain the read results
    static uint8_t buf[1024];
    
    // read the data until done
    if ((*size = [stream read:buf maxLength:sizeof(buf)]) == 0) {
        return [stream close], NULL;
    }
    
    return (const char*)buf;
}

@implementation Script

- (id)initWithState:(lua_State*)L registryReference:(int)ref
{
	if ((self = [super init]) == nil) {
		return nil;
	}
	
	// default members
	m_ref = ref;
	m_lua = L;
	
	return self;
}

+ (Script*)sharedInstance
{
	static Script* instance = nil;
	
	if (instance == nil) {
		lua_State* L = lua_open();
		
		// open common libraries (TODO: limit scope)
		luaL_openlibs(L);
		
		// create the singleton instance
		instance = [[Script alloc] initWithState:L registryReference:0];
	}
	
	return [[instance retain] autorelease];
}

+ (ScriptConstant*)constantWithName:(NSString*)name value:(id)value
{
    ScriptConstant* constant = [[ScriptConstant alloc] init];
    
    // initialize the property
    constant.name = [name retain];
    constant.value = [value retain];
    
    return [constant autorelease];
}

+ (ScriptMethod*)methodWithName:(NSString*)name selector:(SEL)sel
{
    ScriptMethod* method = [[ScriptMethod alloc] init];
    
    // initialize the property
    method.name = [name retain];
    method.sel = sel;
    
    return [method autorelease];
}

- (void)dealloc
{
	luaL_unref([Script sharedInstance]->m_lua, LUA_REGISTRYINDEX, m_ref);
    
	// shutdown all of lua?
	if (self == [Script sharedInstance]) {
		lua_close(m_lua);
	}
	
	// supersend
	[super dealloc];
}

- (Script*)newThreadWithNamespace:(NSString*)name
{
    Script* child = [self newThread];
    
    // put the environment of the child on the stack
    [child pushEnvTo:m_lua];
    
    // make the child's environment accessible to this script by name
    lua_setfield(m_lua, LUA_GLOBALSINDEX, [name UTF8String]);
    
    return child;
}

- (Script*)newThread
{
	lua_State* L = lua_newthread(m_lua);
	
	// store it in the registry so it isn't collected
	int ref = luaL_ref(m_lua, LUA_REGISTRYINDEX);
	
    // create a local environment for this script
    lua_pushthread(L);
    lua_newtable(L);
    lua_newtable(L);
    lua_pushvalue(L, LUA_GLOBALSINDEX);
    lua_setfield(L, -2, "__index");
    lua_setmetatable(L, -2);
    lua_pushvalue(L, -1);
    lua_setfenv(L, -3);
    lua_replace(L, -2);
    
    // the environment of the thread we also want bound to `self'
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "self");
    lua_pop(L, 1);
    	
	// create a new script object with this lua state and registry reference
	return [[Script alloc] initWithState:L registryReference:ref];
}

- (lua_State*)L
{
	return m_lua;
}

- (int)ref
{
    return m_ref;
}

- (BOOL)precompile:(NSString*)fileName
{
    // attempt to compile the file
    if ([self compile:fileName] == FALSE) {
        return FALSE;
    }
    
    // remove the compiled function (it's in the registry)
    lua_pop(m_lua, 1);
    
    return TRUE;
}

- (BOOL)compile:(NSString*)fileName
{
    const char* path = [fileName UTF8String];
    const char* file = [[fileName lastPathComponent] UTF8String];
    
    // attempt to find the script in the registry already compiled
    lua_getfield(m_lua, LUA_REGISTRYINDEX, file);
    
    // if found, we need to clone the function
    if (lua_isfunction(m_lua, -1)) {
        NSOutputStream* output = [NSOutputStream outputStreamToMemory];
        
        // open the stream
        [output open];
        
        // dump the contents of the file to memory
        if (lua_dump(m_lua, (lua_Writer)l_chunkWriter, output) == 0) {
            NSData* data = [output propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
            NSInputStream* input = [NSInputStream inputStreamWithData:data];
            
            // prepare the stream
            [output close];
            [input open];
            
            // remove the function from the stack
            lua_pop(m_lua, 1);
            
            // read the input stream to create a new function
            if (lua_load(m_lua, (lua_Reader)l_chunkReader, input, path) != 0) {
                return [self logError];
            }
            
            return TRUE;
        }
        
        // done with the write stream
        [output close];
        
        // log an error result
        NSLog(@"Failed to dump compiled script %@\n", file);
        
        // remove the function from the stack
        lua_pop(m_lua, 1);
        
        return FALSE;
    }
    
    // pop the nil that was put there
    lua_pop(m_lua, 1);

    // load the file from disk
	if (luaL_loadfile(m_lua, path) != 0) {
        return [self logError];
	}

    // dup and save in the registry
    lua_pushvalue(m_lua, -1);
    lua_setfield(m_lua, LUA_REGISTRYINDEX, file);

    return TRUE;
}

- (BOOL)loadScript:(NSString*)fileName withNamespace:(NSString*)name
{
    // load the function of the compiled script onto the stack
    if ([self compile:fileName] == FALSE) {
        return FALSE;
    }
    
    // create a new environment for the script
    lua_newtable(m_lua);
    lua_newtable(m_lua);
    lua_pushvalue(m_lua, LUA_GLOBALSINDEX);
    lua_setfield(m_lua, -2, "__index");
    lua_setmetatable(m_lua, -2);
    lua_pushvalue(m_lua, -1);
    lua_setfenv(m_lua, -3);
    lua_pushvalue(m_lua, -2);
    
    // execute the function
    if (lua_pcall(m_lua, 0, 0, 0) != 0) {
        lua_replace(m_lua, -3);
        lua_pop(m_lua, 2);
        
        // failed
        return [self logError];
    }
    
    // create the named environment
    lua_replace(m_lua, -2);
    lua_setfield(m_lua, LUA_GLOBALSINDEX, [name UTF8String]);
    
    return TRUE;
}

- (BOOL)loadScript:(NSString*)fileName
{
	// compile the script
    if ([self compile:fileName] == FALSE) {
        return FALSE;
    }
    
    // execute the function
	if (lua_pcall(m_lua, 0, 0, 0) != 0) {
        return [self logError];
	}
    
    return TRUE;
}

- (void)registerMethods:(NSArray*)methods forObject:(id)object
{
    for(ScriptMethod* method in methods) {
        lua_pushobjcfunction(m_lua, object, method.sel);
        lua_setfield(m_lua, -2, [method.name UTF8String]);
    }
}

- (void)registerConstants:(NSArray*)constants
{
    for(ScriptConstant* constant in constants) {
        if ([self push:constant.value] == FALSE) {
            continue;
        }
        
        // register the constant value by name
        lua_setfield(m_lua, -2, [constant.name UTF8String]);
    }
}

- (void)registerObject:(id)object withNamespace:(NSString*)name
{
    NSArray* methods = nil;
    NSArray* constants = nil;
    
    // get the list of methods to register
    if ([object respondsToSelector:@selector(scriptMethods)]) {
        methods = [object scriptMethods];
    }
    
    // get the list of constants to register
    if ([object respondsToSelector:@selector(scriptConstants)]) {
        constants = [object scriptConstants];
    }

    // register everything with the namespace
    [self registerMethods:methods
                constants:constants
                forObject:object
            withNamespace:name];
}

- (void)registerObject:(id <ScriptInterface>)object 
         withNamespace:(NSString*)name
                locked:(BOOL)locked
{
    [self registerObject:object withNamespace:name];
    
    if (locked) {
        [self pushEnv];
        
        // create a proxy table
        lua_newtable(m_lua);
        lua_newtable(m_lua);
        
        // we're going to wrap this environment
        lua_getfield(m_lua, -3, [name UTF8String]);
        
        // create a meta-table and assign it
        lua_setfield(m_lua, -2, "__index");
        lua_pushobjcfunction(m_lua, self, @selector(l_readOnly:));
        lua_setfield(m_lua, -2, "__newindex");
        lua_setmetatable(m_lua, -2);
        
        // now, write the read-only table back
        lua_setfield(m_lua, -2, [name UTF8String]);
        lua_pop(m_lua, 1);
    }
}

- (void)registerMethods:(NSArray*)methods
              constants:(NSArray*)constants
              forObject:(id)object
          withNamespace:(NSString*)name
{
    [self pushEnv];
    
    // create a new table for this object if named
    if (name != nil) {
        lua_newtable(m_lua);
    }
    
    // register the methods with the table
    if (methods != nil) {
        [self registerMethods:methods forObject:object];
    }
    
    // register the constants
    if (constants != nil) {
        [self registerConstants:constants];
    }
    
    // assign the namespace
    if (name != nil) {
        lua_setfield(m_lua, -2, [name UTF8String]);
    }
    
    // remove the environment table
    lua_pop(m_lua, 1);
}

+ (BOOL)push:(id)value to:(lua_State*)L
{
    if (value == nil) {
        lua_pushnil(L);
    } else if ([value isKindOfClass:[NSNumber class]]) {
        const char* type = [value objCType];
        
#       define is_type(T) (strcmp(type,@encode(T)) == 0)
        {
            if (is_type(BOOL)) {
                lua_pushboolean(L, [value boolValue]);
            } else if (is_type(float)) {
                lua_pushnumber(L, [value floatValue]);
            } else if (is_type(double)) {
                lua_pushnumber(L, [value doubleValue]);
            } else if (is_type(short)) {
                lua_pushnumber(L, [value shortValue]);
            } else if (is_type(int)) {
                lua_pushnumber(L, [value intValue]);
            } else if (is_type(long)) {
                lua_pushnumber(L, [value longValue]);
            } else if (is_type(unsigned short)) {
                lua_pushnumber(L, [value unsignedShortValue]);
            } else if (is_type(unsigned int)) {
                lua_pushnumber(L, [value unsignedIntValue]);
            } else if (is_type(unsigned long)) {
                lua_pushnumber(L, [value unsignedLongValue]);
            }
        }
#       undef is_type
    } else if ([value isKindOfClass:[NSString class]]) {
        lua_pushstring(L, [value UTF8String]);
    } else if ([value isKindOfClass:[NSArray class]]) {
        lua_newtable(L);
        
        // loop over each value in the array and push it
        for(unsigned long i = 0;i < [value count];i++) {
            lua_pushnumber(L, i + 1);
            
            // push the value
            if ([Script push:[value objectAtIndex:i] to:L] == FALSE) {
                lua_pop(L, 1);
                
                // all or nothing...
                return FALSE;
            }
            
            // assign the value to the index
            lua_settable(L, -3);
        }
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        lua_newtable(L);
        
        // loop over all the keys in the dictionary
        for(id key in value) {
            id entry = [value objectForKey:key];
            
            // push the key
            if ([Script push:key to:L] == FALSE) {
                lua_pop(L, 1);
                
                // all or nothing
                return FALSE;
            }
            
            // push the value
            if ([Script push:entry to:L] == FALSE) {
                lua_pop(L, 2);
                
                // all or nothing
                return FALSE;
            }
            
            // assign the value to the index
            lua_settable(L, -3);
        }
    } else if ([value isKindOfClass:[Script class]]) {
        [value pushEnvTo:L];
    } else {
        return FALSE; // unknown type, don't try and set it
    }
    
    return TRUE;
}

- (BOOL)push:(id)value
{
    return [Script push:value to:m_lua];
}

- (void)pushEnvTo:(lua_State*)L
{
    // lookup the thread in the registry
    lua_rawgeti(L, LUA_REGISTRYINDEX, m_ref);
    
    // fetch the thread environment and pop the thread
    lua_getfenv(L, -1);
    lua_replace(L, -2);
}

- (void)pushEnv
{
    // use the thread (faster)
    lua_pushthread(m_lua);
    
    // fetch the thread environment and pop the thread
    lua_getfenv(m_lua, -1);
    lua_replace(m_lua, -2);
}

- (BOOL)bind:(id)value to:(NSString*)name
{
    if ([self push:value] == FALSE) {
        return FALSE;
    }
    
    // assign it to the name provided
    lua_setfield(m_lua, LUA_GLOBALSINDEX, [name UTF8String]);
    
    return TRUE;
}

- (BOOL)call:(const char*)func
{
    return [self call:func withArgs:0];
}

- (BOOL)call:(const char*)func withArgs:(int)n
{
    BOOL result = FALSE;
    
#ifdef CHECK_LUA_STACK
    int top = lua_gettop(m_lua);
#endif
    
    // get this thread's environment
    [self pushEnv];
    
    // lookup the function and pop the environment
    lua_getfield(m_lua, -1, func);
    lua_replace(m_lua, -2);
	
    // check to make sure it's actually a function
	if (lua_isfunction(m_lua, -1)) {
        int i;
        
        // duplicate parameters on stack
        for(i = 0;i < n;i++) {
            lua_pushvalue(m_lua, -(n + 1) + i);
        }
        
        // call the function
        if ((result = (lua_pcall(m_lua, n, 0, 0) == 0)) == FALSE) {
            [self logError];
        }
	} else {
        // remove the function
        lua_pop(m_lua, 1);
    }
    
    // verify things are still good
#ifdef CHECK_LUA_STACK
    NSAssert(lua_gettop(m_lua) == top, @"Unbalanced Lua stack!");
#endif
     
    // remove the parameters
    lua_pop(m_lua, n);
    
    return result;
}

- (BOOL)eval:(const char*)string
{
	if (luaL_dostring(m_lua, string) != 0) {
        return [self logError];
    }
    
    return TRUE;
}

- (BOOL)logError
{
    NSLog(@"%s\n", lua_tostring(m_lua, -1));
    
    // remove the string from the stack
    lua_pop(m_lua, 1);
    
    // chain return values
    return FALSE;
}

/*
 * LUA INTERFACE
 */

- (int)l_readOnly:(lua_State*)L
{
    lua_pushliteral(L, "Attempting to update a read-only table");
    lua_error(L);
    
    return 0;
}

@end
