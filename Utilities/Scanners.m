// Greybox 2D Game Engine
//
// Copyright (c) 2011 by Jeffrey Massung.
// All rights reserved.
//

#import "Scanners.h"

@implementation NSString (Scanners)

- (NSColor*)colorValue
{
    NSCharacterSet* set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString* color;
    unsigned int rgba;
    
    // default color components
    float red = 0.0f;
    float green = 0.0f;
    float blue = 0.0f;
    float alpha = 1.0f;
    
    // strip whitespace and force uppercase (hex chars A-F)
    color = [[self stringByTrimmingCharactersInSet:set] uppercaseString];
    
    // make sure we start off correctly
    if ([color hasPrefix:@"#"] == NO) {
        return [NSColor colorWithDeviceRed:red 
                                     green:green 
                                      blue:blue 
                                     alpha:alpha];
    }
    
    switch([color length]) {
        case 4: // #rgb
            if ([[NSScanner scannerWithString:[color substringFromIndex:1]] scanHexInt:&rgba]) {
                red = (float)(rgba & 0xF00) / 0xF00;
                green = (float)(rgba & 0x0F0) / 0x0F0;
                blue = (float)(rgba & 0x00F) / 0x00F;
            }
            break;
            
        case 5: // #rgba
            if ([[NSScanner scannerWithString:[color substringFromIndex:1]] scanHexInt:&rgba]) {
                red = (float)(rgba & 0xF000) / 0xF000;
                green = (float)(rgba & 0x0F00) / 0x0F00;
                blue = (float)(rgba & 0x00F0) / 0x00F0;
                alpha = (float)(rgba & 0x000F) / 0x000F;
            }
            break;
            
        case 7: // #rrggbb
            if ([[NSScanner scannerWithString:[color substringFromIndex:1]] scanHexInt:&rgba]) {
                red = (float)(rgba & 0xFF0000) / 0xFF0000;
                green = (float)(rgba & 0x00FF00) / 0x00FF00;
                blue = (float)(rgba & 0x0000FF) / 0x0000FF;
            }
            break;
            
        case 9: // #rrggbbaa
            if ([[NSScanner scannerWithString:[color substringFromIndex:1]] scanHexInt:&rgba]) {
                red = (float)(rgba & 0xFF000000) / 0xFF000000;
                green = (float)(rgba & 0x00FF0000) / 0x00FF0000;
                blue = (float)(rgba & 0x0000FF00) / 0x0000FF00;
                alpha = (float)(rgba & 0x000000FF) / 0x000000FF;
            }
            break;
    }
    
    return [NSColor colorWithDeviceRed:red 
                                 green:green 
                                  blue:blue 
                                 alpha:alpha];
}

@end
