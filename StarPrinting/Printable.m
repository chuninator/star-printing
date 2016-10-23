//
//  NSObject+Printable.m
//  StarPrinting
//
//  Created by Matthew Newberry on 4/11/13.
//  OpenTable
//

#import "Printable.h"

@implementation NSObject (Printable)

- (void)print_p
{
    [self print_p:[Printer connectedPrinter]];
}

- (void)print_p:(Printer *)printer
{
    [printer print_p:[self performSelector:@selector(printedFormat)]];
}

@end
