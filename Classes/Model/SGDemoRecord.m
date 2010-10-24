//
//  SGDemoRecord.m
//  SGDemoApp
//
//  Created by Derek Smith on 10/4/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "SGDemoRecord.h"

@implementation SGDemoRecord
@synthesize titleKey;

- (NSString*) title
{
    if(titleKey && ![titleKey isEqualToString:@""])
        return [self.properties objectForKey:titleKey];
    else
        return self.recordId;
}

- (void) dealloc
{
    [titleKey release];
    [super dealloc];
}

@end
