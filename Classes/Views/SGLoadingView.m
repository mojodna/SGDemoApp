//
//  SGLoadingView.m
//  SGDemoApp
//
//  Copyright (c) 2009-2010, SimpleGeo
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without 
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, 
//  this list of conditions and the following disclaimer. Redistributions 
//  in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  
//  Neither the name of the SimpleGeo nor the names of its contributors may
//  be used to endorse or promote products derived from this software 
//  without specific prior written permission.
//   
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
//  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  Created by Derek Smith.
//

#import "SGLoadingView.h"

#define kSGLoadingView_InsetX               7.0

static SGLoadingView* sharedLoadingView = nil;

@implementation SGLoadingView

@synthesize titleLabel, activityIndicator, lock;

- (id) initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame]) {

        backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LoadingBackground.png"]];
        [self addSubview:backgroundImage];
        
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 50.0)];
        titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.text = @"Loading...";
        [self addSubview:titleLabel];
        
        activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0, 0.0, 20.0, 20.0)];
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        [self addSubview:activityIndicator];
        
        lock = NO;
    }
    
    return self;
}

+ (SGLoadingView*) sharedLoadingView
{
    if(!sharedLoadingView) {
        sharedLoadingView = [[[SGLoadingView alloc] initWithFrame:CGRectMake(92.0, 360.0, 140.0, 50.0)] retain];
        [[UIApplication sharedApplication].keyWindow addSubview:sharedLoadingView];
    }
    
    return sharedLoadingView;
}

+ (void) setTitle:(NSString*)title
{
    if(!sharedLoadingView)
        [SGLoadingView sharedLoadingView];
    
    if(!sharedLoadingView.lock) {
    
        sharedLoadingView.titleLabel.text = title;
    
        CGSize titleSize = [title sizeWithFont:sharedLoadingView.titleLabel.font];
    
        if(titleSize.width > 200)
            titleSize.width = 200;
    
        CGFloat width = titleSize.width + sharedLoadingView.activityIndicator.frame.size.width + kSGLoadingView_InsetX * 3;
    
        sharedLoadingView.frame = CGRectMake((320.0 - width) / 2.0,
                                             sharedLoadingView.frame.origin.y, 
                                             width, 
                                             sharedLoadingView.frame.size.height);
    
        [sharedLoadingView setNeedsLayout];
        
    }
}

+ (void) showLoading:(BOOL)loading
{
    if(!sharedLoadingView)
        [SGLoadingView sharedLoadingView];        
     
    if(!sharedLoadingView.lock) {
        if(loading) {
            sharedLoadingView.hidden = NO;
            [sharedLoadingView.activityIndicator startAnimating];
            [[UIApplication sharedApplication].keyWindow bringSubviewToFront:sharedLoadingView];
        } else {
            sharedLoadingView.hidden = YES;
            [sharedLoadingView.activityIndicator stopAnimating];
        }
    }
}

+ (void) showLoading:(BOOL)loading lock:(BOOL)locked
{
    if(!sharedLoadingView)
        [SGLoadingView sharedLoadingView];

    sharedLoadingView.lock = locked;
    
    if(loading) {
        sharedLoadingView.hidden = NO;
        [sharedLoadingView.activityIndicator startAnimating];
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:sharedLoadingView];
    } else {
        sharedLoadingView.hidden = YES;
        [sharedLoadingView.activityIndicator stopAnimating];
    }        
}

+ (void) setPoint:(CGPoint)origin
{
    if(!sharedLoadingView)
        [SGLoadingView sharedLoadingView]; 
    
    sharedLoadingView.frame = CGRectMake(origin.x, origin.y,
                                            sharedLoadingView.frame.size.width,
                                            sharedLoadingView.frame.size.height);
        
}

+ (BOOL) isLoading
{
    BOOL loading = NO;
    if(sharedLoadingView)
        loading = [sharedLoadingView.activityIndicator isAnimating];
    
    return loading;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    backgroundImage.frame = self.bounds;
    activityIndicator.frame = CGRectMake(kSGLoadingView_InsetX, 
                                         (self.bounds.size.height - activityIndicator.frame.size.height) / 2.0, 
                                         activityIndicator.frame.size.width,
                                         activityIndicator.frame.size.height);
    titleLabel.frame = CGRectMake(activityIndicator.frame.origin.x + activityIndicator.frame.size.width + kSGLoadingView_InsetX,
                                  0.0,
                                  titleLabel.frame.size.width,
                                  self.bounds.size.height);
}

- (void) dealloc 
{
    [backgroundImage release];
    [titleLabel release];
    [activityIndicator release];
    
    [super dealloc];
}


@end
