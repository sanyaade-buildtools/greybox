// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Script.h"

@interface Project : NSBundle <ScriptInterface>
{
    // static project data
    NSDictionary* m_settings;
    
    // dynamically loaded resources
    NSMutableDictionary* m_manifest;
    NSMutableDictionary* m_assets;
    
    // default assets (one for each class type)
    NSMutableDictionary* m_defaultAssets;
    
    // tracks all currently loaded groups
    NSMutableArray* m_loadQueue;
    NSConditionLock* m_lock;
}

// allocator methods
+ (Project*)projectWithPath:(NSString*)path;

// get the default asset for a class
- (id)defaultAssetForClass:(Class)cls;

// lookup project settings
- (id)settingForKey:(NSString*)key;
- (id)settingForKey:(NSString*)key withDefault:(id)object;

// helper functions for reading project data
- (NSData*)dataWithContentsOfFile:(NSString*)fileName;
- (NSString*)stringWithContentsOfFile:(NSString*)fileName;
- (NSXMLDocument*)xmlDocumentWithContentsOfPath:(NSString*)fileName;
- (NSURL*)URLForFile:(NSString*)fileName;

// parses the manifest dictionary from the project and loads asset groups
- (BOOL)loadManifest;

// parse an asset group XML file and get a list of asset in it
- (BOOL)loadAssetGroup:(NSString*)fileName withName:(NSString*)groupName;

// creates a default asset group, loads, and blocks until loaded
- (void)loadAsset:(Asset*)asset;
- (void)loadDefaultAssetGroup:(NSArray*)assets;

// load and unload a group of assets
- (void)loadAssets:(NSString*)group;
- (void)unloadAssets:(NSString*)group;

// spin until the load queue is empty
- (void)waitUntilLoadComplete;

// lookup an asset by its name
- (id)assetWithName:(NSString*)name;
- (id)assetWithName:(NSString*)name type:(Class)cls;

@end
