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


#import <UIKit/UIKit.h>


/*
 *  An example for implementing a custom container ViewController in iOS7.
 *  This sample replicates a portion of the UINavigationController behavior.
 *  ViewControllers can be pushed animated and popped interactively using the iOS7 pan-to-pop gesture from the left screen edge.
 *
 *  This class is just an example to show what the workflow for a custom container is.
 *  Therefore, only the pushing (animated) and popping (interactive) of ChildViewControllers are implemented
 *  and the interface is kept as simple as possible.
 *
 *  Note that there are some things in this example that do not follow Apple's container implementation style due to simplification.
 *
 *  1.  An instance of INCCustomAnimatedTransition is used to control the animation and interaction during pushing and popping.
 *      Also, the container provides the built in ability to interactively pop a viewController (like UINavigationController).
 *      If you want to write a more "distributable" containerController which can be used by 3rd parties, you should add a delegate
 *      which can be asked to provide an animation / transitionController, like UINavigationController and UITabbarController do.
 *
 *  2.  This container implements the <UIViewControllerContextTransitioning> protocol.
 *      Apple-containers (UINavigationController, UITabBarController) use a separate, PRIVATE class (_UIViewControllerOneToOneTransitionContext)
 *      which implements this protocol.
 *      As that grade of modularity is just making things too complicated imho, i prefer handling the ContextTransitioning
 *      directly in the container class.
 *      See http://stackoverflow.com/questions/21804111/class-architecture-for-implementing-a-fully-custom-containerviewcontroller-in-io
 *      for more info about the separate class and why or why not to create one.
 *
 *
 *  The appearanceMethods NSLog themselves so that you can see in which order they are called during pushing and popping.
 *  When you compare to UINavigationController or UITabBarController, you will see that this container uses the same order.
 *  -> Good practice.
 *
 */
@interface INCCustomContainer : UIViewController


//  Only make the viewControllerStack available through an NSArray (NOT NSMutableArray)
//  The actual viewControllerStack is saved in an Ivar here (see .m file)
@property (nonatomic, readonly) NSArray *viewControllers;

//  Returns the currently visible ViewController
@property (nonatomic, readonly) UIViewController *topViewController;

//  The recognizer used to pop viewControllers. Similar to UINavigationController behaviour.
@property (nonatomic, readonly) UIScreenEdgePanGestureRecognizer *interactivePopGestureRecognizer;

//  Common initializer
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;


- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end


/*
 *  It's useful to enable every ViewController to get a reference to the custom container,
 *  when / if it is contained in one.
 *  Create a Category for that purpose.
 *
 *  Similar to self.navigationController or self.tabBarController, all UIViewControllers (+ subclasses) can now
 *  call self.customContainer when they import this .h file.
 */
@interface UIViewController (INCCustomContainer)

- (INCCustomContainer *)customContainer;

@end
