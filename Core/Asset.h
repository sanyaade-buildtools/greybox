// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

// forward declaration
@protocol AssetInterface;

@interface Asset : NSObject
{
    // load and unload reference count
    unsigned int m_refs;
    
    // used to load and identify in project
    NSString* m_name;
    NSString* m_path;
}

// initialization methods
- (id)initWithName:(NSString*)name path:(NSString*)path;
- (id)initWithPath:(NSString*)path;

// accessors
- (NSString*)name;
- (NSString*)path;

// true if the asset is already in memory
- (BOOL)isLoaded;

// load/unload the asset into/from memory
- (BOOL)load;
- (BOOL)unload;

@end

// subclasses that can be loaded conform to this protocol
@protocol AssetInterface
- (BOOL)loadFromDisk;
- (BOOL)unloadFromMemory;
@end