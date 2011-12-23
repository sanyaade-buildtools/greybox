// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Engine.h"
#import "Font.h"
#import "Texture.h"

@implementation Font

- (id)init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    // initialize members
    m_pages = [[NSMutableArray alloc] init];
    m_glyphs = [[NSMutableDictionary alloc] init];
    m_doc = nil;
    
    return self;
}

- (void)dealloc
{
    [m_doc release];
    [m_glyphs release];
    [m_pages release];
    [super dealloc];
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
    
    // parse and load all the texture pages
    for(NSXMLElement* pages in [root elementsForName:@"pages"]) {
        for(NSXMLElement* page in [pages elementsForName:@"page"]) {
            NSString* index;
            NSString* fileName;
            NSData* data;
            NSImage* image;
            Texture* texture;
            int pageIndex;
            
            // lookup the index
            if ((index = [[page attributeForName:@"index"] stringValue]) == nil) {
                NSLog(@"Missing index attribute for font %@\n", [self name]);
                continue;
            }
            
            // make sure it's a valid page
            if ((pageIndex = [index intValue]) < 1) {
                NSLog(@"Invalid index attribute for font %@\n", [self name]);
                continue;
            }
            
            // lookup the filename
            if ((fileName = [[page attributeForName:@"texture"] stringValue]) == nil) {
                NSLog(@"Missing texture attribute for font %@\n", [self name]);
                continue;
            }
            
            // attempt to load the image file
            if ((data = [theProject dataWithContentsOfFile:fileName]) == nil) {
                continue;
            }
            
            // attempt to open the image file
            if ((image = [[NSImage alloc] initWithData:data]) == nil) {
                NSLog(@"Invalid texture page %@ for font %@\n", fileName, [self name]);
                continue;
            }
            
            // create the texture
            if ((texture = [Texture textureFromImage:[image autorelease]]) == nil) {
                NSLog(@"Invalid texture page %@ for font %@\n", fileName, [self name]);
                continue;
            }
            
            // make sure the array is large enough
            while([m_pages count] < pageIndex) {
                [m_pages addObject:[NSNull null]];
            }
            
            // assign it to the texture pages
            [m_pages replaceObjectAtIndex:pageIndex - 1 withObject:texture];
        }
    }
    
    // parse all the glyphs and create the texture frames
    for(NSXMLElement* glyphs in [root elementsForName:@"glyphs"]) {
        for(NSXMLElement* glyph in [glyphs elementsForName:@"glyph"]) {
            NSString* page;
            NSString* name;
            NSString* x;
            NSString* y;
            NSString* w;
            NSString* h;
            Glyph g;
            
            // lookup the name
            if ((name = [[glyph attributeForName:@"name"] stringValue]) == nil) {
                NSLog(@"Missing name attribute for glyph in font %@\n", [self name]);
                continue;
            }
            
            // get the left-origin of the frame
            if ((x = [[glyph attributeForName:@"x"] stringValue]) == nil) {
                NSLog(@"Missing x attribute for glyph %@ in font %@\n", name, [self name]);
                continue;
            }
            
            // get the top-origin of the frame
            if ((y = [[glyph attributeForName:@"y"] stringValue]) == nil) {
                NSLog(@"Missing y attribute for glyph %@ in font %@\n", name, [self name]);
                continue;
            }
            
            // get the width of the frame
            if ((w = [[glyph attributeForName:@"w"] stringValue]) == nil) {
                NSLog(@"Missing w attribute for glyph %@ in font %@\n", name, [self name]);
                continue;
            }
            
            // get the height of the frame
            if ((h = [[glyph attributeForName:@"h"] stringValue]) == nil) {
                NSLog(@"Missing h attribute for glyph %@ in font %@\n", name, [self name]);
                continue;
            }
            
            // lookup the index
            if ((page = [[glyph attributeForName:@"page"] stringValue]) == nil) {
                NSLog(@"Missing page attribute for glyph %@ font %@\n", name, [self name]);
                continue;
            }
            
            // get the page index texture
            g.page = [page intValue] - 1;
            
            // make sure it's a valid index
            if (g.page < 0 || g.page >= [m_pages count]) {
                NSLog(@"Invalid page attribute for glyph %@ front %@\n", name, [self name]);
                continue;
            }
            
            // find the size of the glyph
            g.width = [w intValue];
            g.height = [h intValue];
            
            // create the glyph's frame
            g.frame = [[m_pages objectAtIndex:g.page] addFrame:NSMakeRect([x intValue], 
                                                                          [y intValue], 
                                                                          g.width, 
                                                                          g.height)];
            
            // write the glyph to the table
            [m_glyphs setObject:[NSData dataWithBytes:&g length:sizeof(g)] 
                         forKey:name];
        }
    }
    
    return TRUE;
}

- (BOOL)unloadFromMemory
{
    [m_pages removeAllObjects];
    [m_glyphs removeAllObjects];
    [m_doc release];
    
    return TRUE;
}

- (const Glyph*)glyphForCharacter:(unichar)c
{
    NSString* character = [NSString stringWithCharacters:&c length:1];
    NSData* glyph = [m_glyphs objectForKey:character];
    
    // lookup the character glyph in the map
    if (glyph == nil) {
        return NULL;
    }
    
    return (const Glyph*)[glyph bytes];
}

- (NSSize)sizeOfString:(NSString*)string
{
    return NSMakeSize(0, 0);
}

- (NSSize)sizeOfString:(NSString*)string withBounds:(NSSize)bounds
{
    return NSMakeSize(0, 0);
}

- (void)render:(NSString*)string
{
    for(int i = 0;i < [string length];i++) {
        NSData* data;
        NSString* character;
        const Glyph* glyph;
        
        // lookup the glyph for this character
        character = [string substringWithRange:NSMakeRange(i, 1)];
        data = [m_glyphs objectForKey:character];
        
        // skip if not found
        if (data == nil) {
            continue;
        }
        
        // fetch the glyph structure
        glyph = (const Glyph*)[data bytes];
        
        // render it to the display
        [(Texture*)[m_pages objectAtIndex:glyph->page] render:(int)glyph->frame];
        
        // translate for the next character
        glTranslatef(glyph->width, 0.0f, 0.0f);
    }
}

- (void)render:(NSString*)string withBounds:(NSSize)bounds
{
    
}

@end
