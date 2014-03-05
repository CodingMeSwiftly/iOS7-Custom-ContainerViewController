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


#import "INCCustomContainer.h"

#import "INCCustomContainerTransition.h"


@interface INCCustomContainer () <UIViewControllerContextTransitioning>

@property (nonatomic, readwrite) UIScreenEdgePanGestureRecognizer *interactivePopGestureRecognizer;

@property (nonatomic) INCCustomContainerTransition *transitionController;

@property (nonatomic) UILabel *titleLabel;

@end

@implementation INCCustomContainer {
    
    NSMutableArray *_viewControllerStack;
    
    /*
     *  We are using a separate containerView to add the ChildViewControllers's views in.
     *  I don't like adding them to "self.view" because the container has to bring it's own
     *  supplementary views to front every time the childs are changed. <- Bad.
     *  UINavigationControllers, for example, add the NavigationBar to "self.view" and then
     *  add the _containerView below it.
     *  Like that, the navigationBar always stays on top of every childViewController's view.
     *  -> containerView and supplementary views (NavigationBar, TabBar, etc.) are both direct subviews of 'self.view'.
     *  -> childViewController.views are subviews of containerView and don't ever appear over the supplementary views.
     *
     *  Another advantage: Gesture recognizers can be added to self.view instead of the containing view.
     *  This reduces the number of recognizers in one single view, as the childViewController's views are in a separate subview. 
     *  (The more gestureRecognizers in one single view, the worse !?)
     */
     UIView *_containerView;
    
    
    /*
     *  Ivars to store the viewControllers currently taking part in the transition.
     *  Apple uses a separate, private class for that. See the contextTransitioning delegate implementation below, for more info.
     */
    UIViewController *toViewController;
    UIViewController *fromViewController;
    
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super init];
    if (self) {
        if (rootViewController) {
            _viewControllerStack = [NSMutableArray arrayWithObject:rootViewController];
        } else {
            _viewControllerStack = [NSMutableArray array];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    /*
     *  The containerView where the childViewController's views will be added.
     *  Don't add childViewController views directly to self.view to always keep supplementary views above childVC views.
     */
    _containerView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_containerView];

    
    /*
     *  Note that adding a UINavigationBar to your containerViewController may be tempting at this point to replicate
     *  UINavigationController behavior (as you can simply call [self.navigationBar pushNavigationItem:] when you are pushing
     *  a new viewController.
     *  BUT: This more or less disables the ability to use interactive transitions, because the interactive UINavigationBar - transition
     *  API is not public. You would have to mess around with animating snapshotViews, etc. -> not worth it !
     *  In that case, you will be better off using a UINavigationController sublass and providing custom transitions through it's delegate.
     */
    //  A toolbar added as a supplementary view.
    //  It will show the current ViewController's title.
    UIToolbar *bottomBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,
                                                                       self.view.bounds.size.height - 44.0,
                                                                       self.view.bounds.size.width,
                                                                       44.0)];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:bottomBar.bounds];
    [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.titleLabel setTextColor:[UIColor colorWithWhite:0.4 alpha:1.0]];
    [self.titleLabel setFont:[UIFont systemFontOfSize:24.0]];
    
    [bottomBar addSubview:self.titleLabel];
    
    [self.view addSubview:bottomBar];
    
    
    //  The pop recognizer
    //  Note that is is added to self.view, NOT to the containerView.
    self.interactivePopGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePopGesture:)];
    [self.interactivePopGestureRecognizer setEdges:UIRectEdgeLeft];
    [self.view addGestureRecognizer:self.interactivePopGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"ViewWillAppear: %@", [self.class description]);
    
    if (self.childViewControllers.count == 0) {
        /*
         *  We are adding the rootViewController in viewWillAppear: and NOT in viewDidLoad.
         *
         *  Reasons: 
         *  The ChildViewController should be able to get a reference to this container (through the category implementation below)
         *  during its viewDidLoad method. When we add the rootVC as a child in the container's viewDidLoad, we have to call [super viewDidLoad]
         *  AFTER adding the rootVC as a child. Othewise, in the child's viewDidLoad, the category would return 'nil', because the
         *  containerViewController is not yet loaded completely.
         *  As calling super should stay the first thing to do in viewDidLoad, we move the root-adding to viewWillAppear.
         *  If you cross-check with UINavigationController and UITabBarController, you will find that they are also adding
         *  the root-childs in their viewWillAppear: method, so why not stick to Apple's coding here ? :)
         */
        
        /*
         *  This is the common sequence of calls when simply adding a childViewController
         *  without animating.
         *  beginAppearanceTransition:animated: and endAppearanceTransition will call the
         *  viewWillAppear:, viewDidAppear:, viewWillDisappear: and viewDidDisappear: methods of
         *  the corresponding viewController appropriately.
         *  beginAppearanceTransition:YES will call viewWillAppear:, :NO will call viewWillDisappear:
         *  endAppearanceTransition will end the current transition direction.
         *
         *  This is useful when you have an interactive transition that is cancelled.
         *  When it is cancelled, call beginAppearanceTransition: again in the opposite direction (NO->YES, YES->NO)
         *  See below in - cancelInteractiveTransition for an example of this usecase.
         *
         *  See http://stackoverflow.com/questions/21306496/how-to-cancel-view-appearance-transitions-for-custom-container-controller-tran/21797579?noredirect=1 for good, detailed info about that.
         */
        
        UIViewController *root = [_viewControllerStack firstObject];
        
        [self addChildViewController:root];
        
        [root beginAppearanceTransition:YES animated:NO];
        [_containerView addSubview:root.view];
        [root endAppearanceTransition];
        
        [root didMoveToParentViewController:self];
        
        [self.titleLabel setText:root.title];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSLog(@"ViewDidAppear: %@", [self.class description]);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    NSLog(@"ViewWillDisappear: %@", [self.class description]);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    NSLog(@"ViewDidDisappear: %@", [self.class description]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    /*
     *  This is important.
     *  If you return YES here, the containment-methods (addChildViewController:, etc.) will call appearance methods (viewWillAppear:, etc.)
     *  on the childViewControllers. Problem: They are not really reliable in that case ;). E.g. viewWillAppear:, etc. will not get called properly.
     *  You would most likely get a warning: "Unbalanced calls to appearance methods", when adding / removing childVCs.
     *  Doing it on your own is much more accurate / reliable.
     */
    
    return NO;
}


#pragma mark - UI Interaction

- (void)handlePopGesture:(UIScreenEdgePanGestureRecognizer *)recognizer
{
    if (_viewControllerStack.count < 2) {
        //  Nothing to pop here.
        return;
    }
    
    /*
     *  I guess this is self explaining.
     *
     *  Hint: Press CMD+CTRL+J while the cursor (not the mouse ! ;)) is on startInteractiveTransition:, etc. and see where it is going.
     *  In the transitionController class, do the same for [context updateInteractiveTransition:], etc.
     *  Note that you will be jumping back and forth between this class and INCCustomContainerTransition.
     *
     *  This helped me a lot understanding the call hierarchy and relationship.
     *
     *  This only works if your keyboard settings are default.
     *  It also works through 'Navigate > Jump to Definition' in the Menu.
     */
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        fromViewController = self.topViewController;
        toViewController = [_viewControllerStack objectAtIndex:_viewControllerStack.count - 2];
        
        [fromViewController willMoveToParentViewController:nil];
        
        [fromViewController beginAppearanceTransition:NO animated:YES];
        [toViewController beginAppearanceTransition:YES animated:YES];
        
        [self.transitionController setPushing:NO];
        [self.transitionController startInteractiveTransition:self];
        
    } else {
        CGPoint location = [recognizer translationInView:self.view];
        CGFloat progress = location.x / self.view.bounds.size.width;
        
        if (recognizer.state == UIGestureRecognizerStateChanged) {
            [self.transitionController updateInteractiveTransition:progress];
            
        } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
            CGPoint velocity = [recognizer velocityInView:self.view];
            
            //  When the left edge of the popped viewController is further left than 0.2 * screenWidth; - cancel popping -
            //  When it is further right than 0.8 * screenWidth; - finish popping -
            //  When it is in between, let the velocity (current pan direction) decide.
            BOOL shouldCancel = progress < 0.2 ? YES : progress > 0.8 ? NO : velocity.x < 0;
            
            [self.transitionController endInteractiveTransition:shouldCancel];
        }
    }

}


#pragma mark - Property Getters & Setters

- (NSArray *)viewControllers
{
    return [NSArray arrayWithArray:_viewControllerStack];
}

- (UIViewController *)topViewController
{
    return (UIViewController *)[_viewControllerStack lastObject];
}

- (INCCustomContainerTransition *)transitionController
{
    /*
     *  Create lazily.
     */
    if (! _transitionController) {
        _transitionController = [[INCCustomContainerTransition alloc] init];
    }
    
    return _transitionController;
}


#pragma mark - Manipulating Stack

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    /*
     *  Store Ivars to return them later in the transitionContext delegate
     */
    toViewController = viewController;
    fromViewController = self.topViewController;
 
    
    [_viewControllerStack addObject:viewController];
    
    
    /*
     *  The common squence of calls to swap to childViewControllers.
     *  If animated == NO, simply finish the transition.
     *  If animated == YES, start the transition, let the transitionController do the animation
     *  and finalize the transition below in 'completeTransition:' of the TransitioningContext Delegate.
     */
    
    [self addChildViewController:toViewController];
    
    [fromViewController beginAppearanceTransition:NO animated:animated];
    [toViewController beginAppearanceTransition:YES animated:animated];
    
    if (! animated) {
        /*
         *  Note that this is more or less the same as below in completeTransition:
         *  The animation is just the inner part of the transition, encapsulated by the appearance and containment calls.
         */
        
        [_containerView addSubview:toViewController.view];
        [fromViewController.view removeFromSuperview];
        
        [fromViewController endAppearanceTransition];
        [toViewController endAppearanceTransition];
        
        [toViewController didMoveToParentViewController:self];
        
        /*
         *  Important thing here: Remove the disappearing ViewController's view (here: fromViewController) from the _containerView
         *  but do NOT remove the controller as a child. It stays a child, it's view is just not visible anymore.
         *  Only call removeFromParentViewController: on viewControllers when they are disappearing
         *  and not coming back. (When they are removed from the stack)
         *  Example:
         *  popping a viewController CAN remove the fromVC, because it is not going to come back.
         *  pushing MUST NOT remove fromVC, because it stays in the _viewControllerStack in that case.
         */
//        [fromViewController removeFromParentViewController]; <- WRONG !!
        
        [self.titleLabel setText:toViewController.title];
        
        //  Remember to set them back to nil so they can be released by ARC.
        fromViewController  = nil;
        toViewController    = nil;
    } else {
        [self.transitionController setPushing:YES];
        
        [self.transitionController animateTransition:self];
    }
}


#pragma mark - UIViewControllerContextTransitioning

/*
 *  As this is supposed to be a short example, nothing more:
 *  Most of the methods don't return useful values, mostly because the INCCustomControllerTransition does not need them.
 *  
 *  When implementing a customContainer, you should return real values here.
 */

- (UIView *)containerView
{
    //  Dumb naming from my side: If the _containerView of this container was a property,
    //  this would override it's getter. Return the Ivar here. Maybe just give your
    //  _containerView another name.
    return _containerView;
}

- (BOOL)isAnimated
{
    // Return fake value
    return NO;
}

- (BOOL)isInteractive
{
    // Return fake value
    return NO;
}

- (BOOL)transitionWasCancelled
{
    // Return fake value
    return NO;
}

- (UIModalPresentationStyle)presentationStyle
{
    // Return fake value
    return UIModalPresentationCustom;
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete
{
    /*
     *  This is where containers update the transition for their supplementary views.
     *
     *  For example, a UINavigationController will move around the titles and barButtons in it's NavigationBar.
     *
     *  This container could crossfade between the old titleLabel value and the new one.
     *
     *  It's totally up to you what your supplementary views do during the transition.
     */
}

- (void)finishInteractiveTransition
{
    /*
     *  This is where containers finsih the transition for their supplementary views.
     *
     *  For example, a UINavigationController will finish the animation in it's NavigationBar.
     */
}

- (void)cancelInteractiveTransition
{
    /*
     *  This is where containers cancel the transition for their supplementary views.
     *
     *  For example, a UINavigationController will cancel the animation in it's NavigationBar.
     */
    
    //  Reverse the appearanceTranstion.
    [fromViewController beginAppearanceTransition:YES animated:YES];
    [toViewController beginAppearanceTransition:NO animated:YES];
}

- (void)completeTransition:(BOOL)didComplete
{
    /*
     *  This is the method is called by the id<UIViewControllerAnimated/InteractiveTransitioning> object when the animation / interaction
     *  completes.
     */
    
    if (didComplete) {
        //  The 'toViewController.view' is added by in the animateTransition: method of the transitionController.
        [fromViewController.view removeFromSuperview];
        
        //  Finalize the appearanceTransition
        [fromViewController endAppearanceTransition];
        [toViewController endAppearanceTransition];
        
        
        //  Update supplementary views
        [self.titleLabel setText:toViewController.title];
        
        
        if (self.transitionController.pushing) {
            
            //  Finalize the viewController transition
            [toViewController didMoveToParentViewController:self];
            
            //  Update the stack
            //        [_viewControllerStack addObject:toViewController];
        } else {
            
            //  Finalize the viewController transition
            [fromViewController removeFromParentViewController];
            
            //  Update the stack
            [_viewControllerStack removeLastObject];
        }
    } else {
        //  Finalize the appearanceTransition
        [fromViewController endAppearanceTransition];
        [toViewController endAppearanceTransition];
    }
    
    //  Set Ivars to nil to release their memory (if this reference was the last one)
    //  If you do not set them to nil, popped viewControllers will stay alive (not deallocated, event with ARC)
    //  until the next transition happens, and the Ivar are set to new values.
    fromViewController  = nil;
    toViewController    = nil;
}

- (UIViewController *)viewControllerForKey:(NSString *)key
{
    if ([key isEqualToString:UITransitionContextFromViewControllerKey]) {
        return fromViewController;
    } else {
        return toViewController;
    }
}

- (CGRect)initialFrameForViewController:(UIViewController *)vc
{
    // Return fake value
    return CGRectZero;
}

- (CGRect)finalFrameForViewController:(UIViewController *)vc
{
    // Return fake value
    return CGRectZero;
}

@end



@implementation UIViewController (INCCustomContainer)

- (INCCustomContainer *)customContainer
{
    if ([self isKindOfClass:[INCCustomContainer class]]) {
        return (INCCustomContainer *)self;
    }
    
    UIViewController *parent = self.parentViewController;
    
    while (! [parent isKindOfClass:[INCCustomContainer class]] && parent != nil) {
        parent = parent.parentViewController;
    }
    
    return (INCCustomContainer *)parent;
}

@end