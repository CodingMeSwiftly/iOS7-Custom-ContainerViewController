iOS7 Custom- ContainerViewController
===================================

 An example for implementing a custom, animation and interaction enabled Container ViewController in iOS7.
 <br>This sample replicates a portion of the UINavigationController behavior.
 
 ViewControllers can be pushed animated and popped interactively using the iOS7 pan-to-pop gesture from the left screen edge.
 
 This class is just an example to show what the workflow for a custom container is.
 Therefore, only the pushing (animated) and popping (interactive) of childViewControllers is implemented
 and the interface is kept as simple as possible.
 
 Note that there are some things in this example that do not follow Apple's container implementation style for the sake of simplicity.
 
 1.  An custom transitionController object is used to control the animation and interaction during pushing and popping.
Also, the container provides the built-in ability to interactively pop a viewController (like UINavigationController).
If you want to write a more "distributable" containerController which can be used by 3rd parties, you should add a delegate to your container which can be asked to provide an animation / transitionController, like UINavigationController and UITabbarController do.
 2.  This container implements the \<UIViewControllerContextTransitioning\> protocol.
Apple-containers (UINavigationController, UITabBarController) use a separate, PRIVATE class (_UIViewControllerOneToOneTransitionContext) which implements this protocol. Such a high grade of modularity is not covered in this example.
