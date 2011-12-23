// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "SegmentCollider.h"

@implementation SegmentCollider

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_radius = 0.0f;
    
    // default segment
    m_a = cpv(0.0f, 0.0f);
    m_b = cpv(0.0f, 0.0f);
    
    return self;
}

+ (NSArray*)properties
{
    return [[NSArray arrayWithObjects:
             prop_WIRE(@"radius", @selector(setRadius:)),
             prop_WIRE(@"x1", @selector(setX1:)), 
             prop_WIRE(@"y1", @selector(setY1:)), 
             prop_WIRE(@"x2", @selector(setX2:)), 
             prop_WIRE(@"y2", @selector(setY2:)), 
             nil]
            arrayByAddingObjectsFromArray:[super properties]];
}

- (float)radius
{
    return m_radius;
}

- (float)x1
{
    return m_a.x;
}

- (float)y1
{
    return m_a.y;
}

- (float)x2
{
    return m_b.x;
}

- (float)y2
{
    return m_b.y;
}

- (void)setRadius:(NSString*)value
{
    m_radius = [value floatValue];
}

- (void)setX1:(NSString*)value
{
    m_a.x = [value floatValue];
}

- (void)setX2:(NSString*)value
{
    m_b.x = [value floatValue];
}

- (void)setY1:(NSString*)value
{
    m_a.y = [value floatValue];
}

- (void)setY2:(NSString*)value
{
    m_b.y = [value floatValue];
}

- (cpShape*)createShape
{
    return cpSegmentShapeNew([m_actor body], m_a, m_b, m_radius);
}

@end
