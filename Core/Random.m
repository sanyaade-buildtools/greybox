// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//
// See: http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html
//

#import "Random.h"

@implementation Random

- (id)init
{
	return [self initWithSeed:0];
}

- (id)initWithSeed:(unsigned int)seed
{
	if ((self = [super init]) == nil) {
		return nil;
	}
	
	if (seed == 0) {
		seed = (unsigned int)time(NULL);
	}
	
	// initialize state
	m_a = 0xF1EA5EED;
	m_b = seed;
	m_c = seed;
	m_d = seed;
	
	// move into the sequence
	for(int i = 0;i < 20;i++) {
		[self next];
	}
	
	return self;
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"uniform", @selector(l_uniform:)),
            script_Method(@"rand", @selector(l_rand:)),
            script_Method(@"sample", @selector(l_sample:)),
            nil];
}

- (unsigned int)next
{
	#define rot(x, k) (((x) << (k)) | ((x) >> (32 - (k))))
	
	m_e = m_a - rot(m_b, 27);
	m_a = m_b ^ rot(m_c, 17);
	m_b = m_c + m_d;
	m_c = m_d + m_e;
	m_d = m_e + m_a;
	
	return m_d;
}

- (float)uniform
{
	double x = [self next] * (1.0 / 4294967295.0);
	
	// return a value in the range [0,1]
	return (float)(x);
}

- (int)rand:(int)max
{
    return [self next] % max;
}

/*
 * LUA INTERFACE
 */

- (int)l_uniform:(lua_State*)L
{
    float m = 0.0f;
    float n = 1.0f;
    
    // get the min value
    if (lua_gettop(L) > 0) {
        if (lua_gettop(L) >= 1) {
            m = lua_tonumber(L, 1);
        }
        
        // get the max value
        if (lua_gettop(L) >= 2) {
            n = lua_tonumber(L, 2);
        } else {
            n = m;
            m = 0.0f;
        }
    }
    
    return lua_pushnumber(L, ((n - m) * [self uniform]) + m), 1;
}

- (int)l_rand:(lua_State*)L
{
    int m = 0;
    int n = 1;
    
    // get the min value
    if (lua_gettop(L) > 0) {
        if (lua_gettop(L) >= 1) {
            m = (int)lua_tonumber(L, 1);
        }
        
        // get the max value
        if (lua_gettop(L) >= 2) {
            n = (int)lua_tonumber(L, 2);
        } else {
            n = m;
            m = 0;
        }
    }
    
    // return a random number in the domain [min,max]
    return lua_pushnumber(L, (int)((n - m + 1) * [self uniform]) + m), 1;
}

- (int)l_sample:(lua_State*)L
{
    int i, len = (int)lua_tonumber(L, 1);
    
    lua_newtable(L);
    
    // loop over each index
    for(i = 1;i <= len;i++) {
        lua_pushnumber(L, i);
        lua_pushnumber(L, [self uniform]);
        lua_settable(L, -3);
    }
    
    return 1;
}

@end
