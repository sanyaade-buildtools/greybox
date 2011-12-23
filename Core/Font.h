// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Asset.h"

typedef struct {
    unsigned long frame;
    long page;
    
    // size of the glyph
    float width;
    float height;
} Glyph;

@interface Font : Asset <AssetInterface>
{
    // the font description file
    NSXMLDocument* m_doc;
    
    // all the characters in the font
    NSMutableDictionary* m_glyphs;
    
    // the texture pages
    NSMutableArray* m_pages;
}

// lookup a glyph in the font
- (const Glyph*)glyphForCharacter:(unichar)c;

// get the size of a string
- (NSSize)sizeOfString:(NSString*)string;
- (NSSize)sizeOfString:(NSString*)string withBounds:(NSSize)bounds;

// render a whole list of characters
- (void)render:(NSString*)string;
- (void)render:(NSString*)string withBounds:(NSSize)bounds;

@end
