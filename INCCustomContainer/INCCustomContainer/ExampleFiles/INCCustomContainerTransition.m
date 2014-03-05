//
//  INCCustomContainer.h
//  INCCustomContainer
//
//  Created by Maximilian Kraus on 04.03.14.
//
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Maximilian Kraus
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


#import "INCCustomContainerTransition.h"

@implementation INCCustomContainerTransition {
    CGRect middleFrame;
    CGRect leftFrame;
    CGRect rightFrame;
    
    __weak UIViewController *toViewController;
    __weak UIViewController *fromViewController;
    
    __weak id<UIViewControllerContextTransitioning> context;
}

- (void)fillIvarsFromContext:(id<UIViewControllerContextTransitioning>)transitionContext
{
    context = transitionContext;
    
    toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];;
    
    middleFrame = [context containerView].frame;
    rightFrame = CGRectOffset(middleFrame, middleFrame.size.width, 0);
    leftFrame = CGRectOffset(middleFrame, - middleFrame.size.width / 4.0, 0);
}


#pragma mark - UIViewController AnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    [self fillIvarsFromContext:transitionContext];
    
    UIView *containerView = [transitionContext containerView];
    
    CGFloat transitionDuration = [self transitionDuration:transitionContext];
    
    
    [containerView addSubview:toViewController.view];
    
    
    if (_pushing) {
        [toViewController.view setFrame:rightFrame];
        
        
        [UIView animateWithDuration:transitionDuration animations:^{
            [toViewController.view setFrame:middleFrame];
            [fromViewController.view setFrame:leftFrame];
            
        } completion:^(BOOL finished) {
            
            [transitionContext completeTransition:YES];
        }];
    } else {
        [containerView bringSubviewToFront:fromViewController.view];
        
        
        [UIView animateWithDuration:transitionDuration animations:^{
            [toViewController.view setFrame:middleFrame];
            [fromViewController.view setFrame:rightFrame];
            
        } completion:^(BOOL finished) {
            
            [transitionContext completeTransition:YES];
        }];
    }}


#pragma mark - UIViewController InteractiveTransitioning

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    [self fillIvarsFromContext:transitionContext];
    
    UIView *containerView = [transitionContext containerView];
    
    [toViewController.view setFrame:leftFrame];
    [containerView insertSubview:toViewController.view belowSubview:fromViewController.view];
}

- (void)updateInteractiveTransition:(CGFloat)progress {
    [fromViewController.view setFrame:CGRectOffset(middleFrame, MAX(0, middleFrame.size.width * progress), 0)];
    [toViewController.view setFrame:CGRectOffset(leftFrame, (middleFrame.size.width / 4.0) * progress, 0)];
    
    [context updateInteractiveTransition:progress];
}

- (void)endInteractiveTransition:(BOOL)cancelled {
    
    CGFloat remainingAnimationDuration;
    
    if (cancelled) {
        [context cancelInteractiveTransition];
        
        remainingAnimationDuration = (CGRectGetMinX(fromViewController.view.frame) / CGRectGetWidth(fromViewController.view.frame)) * [self transitionDuration:context];
        
        [UIView animateWithDuration:remainingAnimationDuration animations:^{
            [fromViewController.view setFrame:middleFrame];
            [toViewController.view setFrame:leftFrame];
            
        } completion:^(BOOL finished) {
            
            [context completeTransition:NO];
            
        }];
    } else {
        [context finishInteractiveTransition];
        
        remainingAnimationDuration = (1.0 - (CGRectGetMinX(fromViewController.view.frame) / CGRectGetWidth(fromViewController.view.frame))) * [self transitionDuration:context];
        
        [UIView animateWithDuration:remainingAnimationDuration animations:^{
            [fromViewController.view setFrame:rightFrame];
            [toViewController.view setFrame:middleFrame];
            
        } completion:^(BOOL finished) {
            [context completeTransition:YES];
        }];
    }
}

@end
