// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Script.h"

@interface Camera : NSObject <ScriptInterface>
{
    NSMutableArray* m_stack;
}

// allocator methods
+ (Camera*)camera;

// push and pop the projection stack
- (void)push;
- (void)pop;

// projection bounds
- (float)left;
- (float)bottom;
- (float)right;
- (float)top;

// transform accessors
- (float)x;
- (float)y;
- (float)angle;
- (float)z;

// rendering
- (void)loadProjectionMatrix;
- (void)applyScaleMatrix;

// creates the default pixel-perfect projection for a display
- (void)pushDefaultProjection:(NSSize)size;

// projection methods
- (void)setOrigin:(NSPoint)origin width:(float)width;

// set the zoom factor
- (void)zoom:(float)z;

// transform setters
- (void)setPosition:(NSPoint)point;
- (void)setAngle:(float)degrees;
- (void)translateBy:(NSPoint)delta global:(BOOL)global;
- (void)rotateBy:(float)degrees;

@end
