// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Component.h"
#import "Engine.h"
#import "Prefab.h"

@implementation Prefab

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_components = [[NSMutableDictionary alloc] init];
    m_tags = [[NSMutableSet alloc] init];
    m_doc = nil;
    
    return self;
}

- (void)dealloc
{
    [m_doc release];
    [m_components release];
    [m_tags release];
    [super dealloc];
}

- (NSDictionary*)components
{
    return [[m_components retain] autorelease];
}

- (NSSet*)tags
{
    return [[m_tags retain] autorelease];
}

- (BOOL)loadFromDisk
{
    NSXMLElement* root;
    
    // try and parse the prefab document
    if ((m_doc = [theProject xmlDocumentWithContentsOfPath:[self path]]) == nil) {
        return FALSE;
    }
    
    // get the root element
    if ((root = [m_doc rootElement]) == nil) {
        return FALSE;
    }
    
    // verify all the components
    for(NSXMLElement* components in [root elementsForName:@"components"]) {
        for(NSXMLElement* elt in [components elementsForName:@"component"]) {
            NSString* type;
            Class cls;
            NSMutableArray* instanceProps;
            NSMutableDictionary* prefabProps;
            NSMutableArray* set;
            
            // create a new dictionary to hold all the instance properties
            prefabProps = [NSMutableDictionary dictionary];
            instanceProps = [NSMutableArray array];
            
            // lookup the type of the component
            if ((type = [[elt attributeForName:@"type"] stringValue]) == nil) {
                NSLog(@"Missing type attribute for component in prefab %@\n", [self name]);
                continue;
            }
            
            // lookup the class for the type of asset
            if ((cls = [BaseComponent componentInterfaceForName:type]) == nil) {
                NSLog(@"Unknown component type %@ in prefab %@\n", type, [self name]);
                continue;
            }
            
            // make sure it has a script interface
            if ([cls conformsToProtocol:@protocol(ScriptInterface)] == NO) {
                NSLog(@"component %@ does not contain a script interface\n", type);
                continue;
            }
            
            // loop over all the properties and collect them
            for(NSXMLElement* proplist in [elt elementsForName:@"properties"]) {
                for(NSXMLNode* prop in [proplist attributes]) {
                    NSString* name = [prop name];
                    NSString* value = [[proplist attributeForName:name] stringValue];
                    
                    // add the property to the dictionary of properties
                    [prefabProps setObject:value forKey:name];
                }
            }
            
            // loop over all the properties for this component class
            for(Property* prop in [cls properties]) {
                NSString* value;
                
                if ((value = [prefabProps objectForKey:prop.value]) != nil) {
                    [instanceProps addObject:prop_WIRE(value, prop.sel)];
                }
            }
            
            // check to see if there's already a component of this type
            if ((set = [m_components objectForKey:NSStringFromClass(cls)]) == nil) {
                set = [NSMutableArray arrayWithObject:instanceProps];
            } else {
                [set addObject:instanceProps];
            }
            
            // add the class to the component list
            [m_components setObject:set forKey:NSStringFromClass(cls)];
        }
    }
    
    // parse all the tags
    for(NSXMLElement* tags in [root elementsForName:@"tags"]) {
        for(NSXMLElement* tag in [tags elementsForName:@"tag"]) {
            NSString* value = [tag stringValue];
            
            // add the tag to the prefab
            [m_tags addObject:[value lowercaseString]];
        }
    }
    
    return TRUE;
}

- (BOOL)unloadFromMemory
{
    [m_doc release];
    [m_components removeAllObjects];
    
    return TRUE;
}

@end
