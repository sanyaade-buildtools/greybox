// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "CircleCollider.h"

@implementation CircleCollider

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_offset = cpv(0.0f, 0.0f);
    m_radius = 1.0f;
    
    return self;
}

+ (NSArray*)properties
{
    return [[NSArray arrayWithObjects:
             prop_WIRE(@"radius", @selector(setRadius:)),
             prop_WIRE(@"x", @selector(setX:)), 
             prop_WIRE(@"y", @selector(setY:)), 
             nil]
            arrayByAddingObjectsFromArray:[super properties]];
}

- (float)radius
{
    return m_radius;
}

- (float)x
{
    return m_offset.x;
}

- (float)y
{
    return m_offset.y;
}

- (void)setRadius:(NSString*)value
{
    m_radius = [value floatValue];
}

- (void)setXOffset:(NSString*)value
{
    m_offset.x = [value floatValue];
}

- (void)setYOffset:(NSString*)value
{
    m_offset.y = [value floatValue];
}

- (cpShape*)createShape
{
    return cpCircleShapeNew([m_actor body], m_radius, m_offset);
}

@end
