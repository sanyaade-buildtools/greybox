// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Asset.h"

@implementation Asset

- (id)initWithName:(NSString*)name path:(NSString*)path
{
    if ((self = [self init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_name = [name retain];
    m_path = [path retain];
    
    // zero reference count
    m_refs = 0;
    
    return self;
}

- (id)initWithPath:(NSString*)path
{
    return [self initWithName:nil path:path];
}

- (void)dealloc
{
    if ([self conformsToProtocol:@protocol(AssetInterface)]) {
        [self performSelector:@selector(unloadFromMemory)];
    }
    
    [super dealloc];
}

- (NSString*)name
{
    return [[m_name retain] autorelease];
}

- (NSString*)path
{
    return [[m_path retain] autorelease];
}

- (BOOL)isLoaded
{
    return m_refs > 0;
}

- (BOOL)load
{
    // already loaded?
    if ([self isLoaded] == FALSE && [self performSelector:@selector(loadFromDisk)] == FALSE) {
        return FALSE;
    }
    
    // increment a reference count
    m_refs++;
    
    return TRUE;
}

- (BOOL)unload
{
    // already unloaded?
    if ([self isLoaded] == FALSE) {
        return TRUE;
    }
    
    // attempt to actually remove from memory if this is the last reference
    if (m_refs == 1 && [self performSelector:@selector(unloadFromMemory)] == FALSE) {
        return FALSE;
    }
    
    // decrement the reference count
    m_refs--;
    
    return TRUE;
}

@end
