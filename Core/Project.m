// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Asset.h"
#import "Project.h"

@implementation Project

+ (Project*)projectWithPath:(NSString*)path
{
    return [[[Project alloc] initWithPath:path] autorelease];
}

- (id)initWithPath:(NSString*)path
{
    NSString* plistPath;
    
    if ((self = [super initWithPath:path]) == nil) {
        return nil;
    }
    
    // lookup the project settings file
    if ((plistPath = [self pathForResource:@"Project" ofType:@"plist"]) == nil) {
        return nil;
    }
    
    // load them into a local dictionary (fast lookup)
    if ((m_settings = [NSDictionary dictionaryWithContentsOfFile:plistPath]) == nil) {
        return nil;
    }
    
    // initialize members
    m_manifest = [[NSMutableDictionary alloc] init];
    m_assets = [[NSMutableDictionary alloc] init];
    m_defaultAssets = [[NSMutableDictionary alloc] init];
    m_loadQueue = [[NSMutableArray alloc] init];
    m_lock = [[NSConditionLock alloc] initWithCondition:0];
    
    // load the manifest from the settings
    if ([self loadManifest] == FALSE) {
        return nil;
    }
    
    // create the load thread
    [NSThread detachNewThreadSelector:@selector(assetLoader) 
                             toTarget:self
                           withObject:nil];
    
    return self;
}

- (void)dealloc
{
    [m_settings release];
    [m_assets release];
    [m_defaultAssets release];
    [m_manifest release];
    [m_loadQueue release];
    [m_lock release];
    [super dealloc];
}

- (NSArray*)scriptMethods
{
    return [NSArray arrayWithObjects:
            script_Method(@"load_assets", @selector(l_loadAssets:)),
            script_Method(@"unload_assets", @selector(l_unloadAssets:)),
            script_Method(@"is_load_complete", @selector(l_isLoadComplete:)),
            nil];
}

- (id)defaultAssetForClass:(Class)cls
{
    return [m_defaultAssets objectForKey:[NSValue valueWithPointer:cls]];
}

- (id)settingForKey:(NSString*)key
{
    return [m_settings objectForKey:key];
}

- (id)settingForKey:(NSString*)key withDefault:(id)object
{
    id value = [self settingForKey:key];
    
    // use the default object if it wasn't found
    if (value == nil) {
        value = [[object retain] autorelease];
    }
    
    return value;
}

- (NSString*)pathForResource:(NSString*)name ofType:(NSString*)ext
{
    NSString* path;
    
    // try our bundle first, fallback to the main bundle
    if ((path = [super pathForResource:name ofType:ext]) == nil) {
        path = [[NSBundle mainBundle] pathForResource:name ofType:ext];
    }
    
    // make sure it was found and still exists
    if (path == nil || [[NSFileManager defaultManager] fileExistsAtPath:path] == FALSE) {
        return nil;
    }
    
    return path;
}

- (NSData*)dataWithContentsOfFile:(NSString*)fileName
{
    NSString* pathName;
    
    // make sure the file is in the project, try the runtime bundle if not
    if ((pathName = [self pathForResource:fileName ofType:nil]) == nil) {
        NSLog(@"File %@ does not exist in the project bundle", fileName);
        return nil;
    }
    
    return [NSData dataWithContentsOfFile:pathName];
}

- (NSString*)stringWithContentsOfFile:(NSString*)fileName
{
    NSString* path;
    NSString* string;
    
    // attempt to find the file
    if ((path = [self pathForResource:fileName ofType:nil]) == nil) {
        NSLog(@"File %@ does not exist or is missing from the project", fileName);
        return nil;
    }
    
    // load the xml from the file
    if ((string = [NSString stringWithContentsOfFile:path 
                                            encoding:NSUTF8StringEncoding
                                               error:nil]) == nil) {
        NSLog(@"Failed to open file: %@\n", fileName);
        return nil;
    }
    
    return string;
}

- (NSXMLDocument*)xmlDocumentWithContentsOfPath:(NSString*)fileName
{
    NSString* xml;
    NSXMLDocument* doc;
    NSError* err;
    
    // attempt to read the contents of the file
    if ((xml = [self stringWithContentsOfFile:fileName]) == nil) {
        return nil;
    }
    
    // try and parse xml source
    if ((doc = [[NSXMLDocument alloc] initWithXMLString:xml
                                                options:NSXMLDocumentValidate 
                                                  error:&err]) == nil) {
        NSLog(@"%@ parse error: %@\n", fileName, [err localizedFailureReason]);
        return nil;
    }
    
    return [doc autorelease];
}

- (NSURL*)URLForFile:(NSString*)fileName
{
    NSString* path;
    
    // attempt to find the file
    if ((path = [self pathForResource:fileName ofType:nil]) == nil) {
        NSLog(@"File %@ does not exist or is missing from the project", fileName);
        return nil;
    }
    
    return [NSURL fileURLWithPath:path];
}

- (BOOL)loadManifest
{
    id manifest = [self settingForKey:@"Manifest"];
    
    // make sure it's a dictionary
    if ([manifest isKindOfClass:[NSDictionary class]] == NO) {
        return FALSE;
    }
    
    // parse each of the asset groups
    for(NSString* assetGroup in manifest) {
        id fileName = [manifest objectForKey:assetGroup];
        
        // make sure it's a string
        if ([fileName isKindOfClass:[NSString class]] == FALSE) {
            NSLog(@"Asset group %@ in manifest is invalid\n",  assetGroup);
            continue;
        }
        
        // add the asset group to the manifest
        if ([self loadAssetGroup:fileName withName:assetGroup] == FALSE) {
            NSLog(@"Failed to load asset group %@ in manifest\n", assetGroup);
            continue;
        }
    }
    
    return TRUE;
}

- (BOOL)loadAssetGroup:(NSString*)assetFileName withName:(NSString*)groupName
{
    NSXMLDocument* doc;
    NSMutableArray* assets;
    Class cls;
    
    // lookup the manifest file in the bundle
    if ((doc = [self xmlDocumentWithContentsOfPath:assetFileName]) == nil) {
        return FALSE;
    }
    
    // allocate an array for all the asset information to go into
    assets = [[NSMutableArray alloc] init];
    
    // loop over every asset
    for(NSXMLElement* elt in [[doc rootElement] elementsForName:@"asset"]) {
        NSString* name;
        NSString* type;
        NSString* file;
        
        // get the name of the asset
        if ((name = [[elt attributeForName:@"name"] stringValue]) == nil) {
            NSLog(@"No name attribute for asset in %@\n", assetFileName);
            continue;
        }
        
        // get the type of the asset
        if ((type = [[elt attributeForName:@"type"] stringValue]) == nil) {
            NSLog(@"No type attribute for asset %@ in %@\n", name, assetFileName);
            continue;
        }
        
        // get the file of the asset
        if ((file = [[elt attributeForName:@"file"] stringValue]) == nil) {
            NSLog(@"No file attribute for asset %@ in %@\n", name, assetFileName);
            continue;
        }
        
        // lookup the class for the type of asset
        if ((cls = [[NSBundle mainBundle] classNamed:[type capitalizedString]]) == nil) {
            NSLog(@"Unknown asset type %@ for asset %@ in %@\n", type, name, assetFileName);
            continue;
        }
        
        // make sure it's a subclass of Asset
        if ([cls isSubclassOfClass:[Asset class]] == NO) {
            NSLog(@"Invald asset type %@ for asset %@ in %@\n", type, name, assetFileName);
            continue;
        }
        
        // make sure it has an asset interface
        if ([cls conformsToProtocol:@protocol(AssetInterface)] == NO) {
            NSLog(@"Invald asset type %@ for asset %@ in %@\n", type, name, assetFileName);
            continue;
        }
        
        // add the asset to the list
        [assets addObject:[[[cls alloc] initWithName:name path:file] autorelease]];
    }
    
    // make sure something was actually loaded
    if ([assets count] == 0) {
        NSLog(@"No assets found in %@\n", assetFileName);
    }
    
    // add the asset list to the manifest
    [m_manifest setValue:[assets autorelease] forKey:groupName];
    
    return TRUE;
}

- (void)loadDefaultAssetGroup:(NSArray*)assets
{
    // wait until any previous assets are done loading
    [m_lock lockWhenCondition:0];
    {
        [m_loadQueue addObjectsFromArray:assets];
    }
    [m_lock unlockWithCondition:1];
    
    // now block until the assets are completely loaded
    [self waitUntilLoadComplete];
}

- (void)loadAsset:(Asset*)asset
{
    // wait until any previous assets are done loading
    [m_lock lockWhenCondition:0];
    {
        [m_loadQueue addObject:asset];
    }
    [m_lock unlockWithCondition:1];
    
    // now block until the assets are completely loaded
    [self waitUntilLoadComplete];
}

- (void)loadAssets:(NSString*)group
{
    [m_lock lockWhenCondition:0];
    {
        NSArray* assets = [m_manifest objectForKey:group];
        
        // make sure the asset group exists
        if (assets) {
            [m_loadQueue addObjectsFromArray:assets];
        }
    }
    [m_lock unlockWithCondition:1];
}

- (void)unloadAssets:(NSString*)group
{
    [m_lock lockWhenCondition:0];
    {
        NSArray* assets = [m_manifest objectForKey:group];
        
        // make sure the asset group exists
        if (assets) {
            for(Asset* asset in assets) {
                if ([asset isLoaded] == YES) {
                    [asset unload];
                }
                
                // remove it from the asset dictionary
                [m_assets removeObjectForKey:[asset name]];
            }
        }
    }
    [m_lock unlockWithCondition:0];
}

- (void)waitUntilLoadComplete
{
    [m_lock lockWhenCondition:0];
    {
        // basically we'll just spin until the condition == 0
    }
    [m_lock unlockWithCondition:0];
}

- (void)assetLoader
{
    for(;;) {
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        {
            [m_lock lockWhenCondition:1];
            {
                // load all the assets in the queue
                for(Asset* asset in m_loadQueue) {
                    if ([asset load] == FALSE) {
                        NSString* name;
                        
                        // if the name doesn't exist, use the path
                        if ((name = [asset name]) == nil) {
                            name = [asset path];
                        }
                        
                        NSLog(@"Failed to load asset: %@\n", name);
                        continue;
                    }
                    
                    // add it to the asset dictionary, nil names exist for default assets
                    if ([asset name] == nil) {
                        NSValue* key = [NSValue valueWithPointer:[asset class]];
                        
                        // use the class as the default asset key
                        [m_defaultAssets setObject:asset forKey:key];
                    } else {
                        [m_assets setObject:asset forKey:[asset name]];
                    }
                }
                
                // clear the queue
                [m_loadQueue removeAllObjects];
            }
            [m_lock unlockWithCondition:0];
        }
        [pool release];
    }
}

- (id)assetWithName:(NSString*)name
{
    return [m_assets objectForKey:name];
}

- (id)assetWithName:(NSString*)name type:(Class)cls
{
    id object = [self assetWithName:name];
    
    // make sure the object exists and is of the right type
    if (object == nil || [object isKindOfClass:cls] == FALSE) {
        return [self defaultAssetForClass:cls];
    }
    
    return [[object retain] autorelease];
}

/*
 * LUA INTERFACE
 */

- (int)l_loadAssets:(lua_State*)L
{
    NSString* group;
    
    // get the group name to load
    if ((group = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return 0;
    }
    
    // start loading
    [self loadAssets:group];
    
    // optionally wait for the load to complete
    if (lua_toboolean(L, 2) == YES) {
        [self waitUntilLoadComplete];
    }
    
    return 0;
}

- (int)l_unloadAssets:(lua_State*)L
{
    NSString* group;
    
    // get the group name to unload
    if ((group = [NSString stringWithUTF8String:lua_tostring(L, 1)]) == nil) {
        return 0;
    }
    
    return [self unloadAssets:group], 0;
}

- (int)l_isLoadComplete:(lua_State*)L
{
    return lua_pushboolean(L, [m_lock condition] == 0), 1;
}

@end
