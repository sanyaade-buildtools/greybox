// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Script.h"

@interface Random : NSObject <ScriptInterface>
{
	unsigned int m_a;
	unsigned int m_b;
	unsigned int m_c;
	unsigned int m_d;
	unsigned int m_e;
}

// initializers
- (id)initWithSeed:(unsigned int)seed;

// return the next random number
- (unsigned int)next;

// return the next random number in the range of [0,1]
- (float)uniform;

// return a random integer in the range of [0,n)
- (int)rand:(int)max;

@end
