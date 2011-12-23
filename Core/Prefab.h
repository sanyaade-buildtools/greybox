// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Asset.h"

@interface Prefab : Asset <AssetInterface>
{
    NSXMLDocument* m_doc;
    
    // a list of components and tags
    NSMutableDictionary* m_components;
    NSMutableSet* m_tags;
}

// accessors
- (NSDictionary*)components;
- (NSSet*)tags;

@end
