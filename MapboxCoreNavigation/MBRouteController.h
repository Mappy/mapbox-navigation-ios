#import <Foundation/Foundation.h>

/**
 Posted when `MBRouteController` receives a user location update representing movement along the expected route.
 
 The user info dictionary contains the keys `MBRouteControllerRouteProgressKey` and `MBRouteControllerLocationKey`.
 
 :nodoc:
 */
extern const NSNotificationName MBRouteControllerProgressDidChangeNotification;

/**
 Posted after the user diverges from the expected route, just before `MBRouteController` attempts to calculate a new route.
 
 The user info dictionary contains the key `MBRouteControllerLocationKey`.
 
 :nodoc:
 */
extern const NSNotificationName MBRouteControllerWillRerouteNotification;

/**
 Posted when `MBRouteController` is about to use a new route.

 :nodoc:
 */
extern const NSNotificationName MBRouteControllerWillRerouteAlongNotification;

/**
 Posted when `MBRouteController` obtains a new route in response to the user diverging from a previous route.
 
 The user info dictionary contains the keys `MBRouteControllerLocationKey` and `MBRouteControllerIsProactiveKey`.
 
 :nodoc:
 */
extern const NSNotificationName MBRouteControllerDidRerouteNotification;

/**
 Posted when `MBRouteController` fails to reroute the user after the user diverges from the expected route.
 
 The user info dictionary contains the key `MBRouteControllerRoutingErrorKey`.
 
 :nodoc:
 */
extern const NSNotificationName MBRouteControllerDidFailToRerouteNotification;

/**
 Posted when `MBRouteController` detects that the user has passed an ideal point for saying an instruction aloud.
 
 The user info dictionary contains the key `MBRouteControllerRouteProgressKey`.
 
 :nodoc:
 */
extern const NSNotificationName MBRouteControllerDidPassSpokenInstructionPointNotification;

extern const NSNotificationName MBRouteControllerDidPassVisualInstructionPointNotification;

/**
 Keys in the user info dictionaries of various notifications posted by instances of `MBRouteController`.
 
 :nodoc:
 */
typedef NSString *MBRouteControllerNotificationUserInfoKey NS_EXTENSIBLE_STRING_ENUM;

/**
 A key in the user info dictionary of a `MBRouteControllerProgressDidChangeNotification`, `MBRouteControllerDidPassVisualInstructionPointNotification`, or `MBRouteControllerDidPassVisualInstructionPointNotification` notification. The corresponding value is a `RouteProgress` object representing the current route progress.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerRouteProgressKey;

/**
 A key in the user info dictionary of a `Notification.Name.RouteControllerWillRerouteAlong` notification. The corresponding value is a `MBRoute` object.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerRouteKey;

/**
 A key in the user info dictionary of an `MBRouteControllerDidPassVisualInstructionPointNotification`. The corresponding value is an `MBVisualInstruction` object representing the current visual instruction.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerVisualInstructionKey;

/**
 A key in the user info dictionary of a `MBRouteControllerDidPassSpokenInstructionPointNotification` notification. The corresponding value is an `MBVisualInstruction` object representing the current visual instruction.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerSpokenInstructionKey;

/**
 A key in the user info dictionary of a `MBRouteControllerProgressDidChangeNotification` or `MBRouteControllerWillRerouteNotification` notification. The corresponding value is a `CLLocation` object representing the current idealized user location.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerLocationKey;

/**
 A key in the user info dictionary of a `MBRouteControllerProgressDidChangeNotification` or `MBRouteControllerWillRerouteNotification` notification. The corresponding value is a `CLLocation` object representing the current raw user location.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerRawLocationKey;

/**
 A key in the user info dictionary of a `MBRouteControllerDidFailToRerouteNotification` notification. The corresponding value is an `NSError` object indicating why `RouteController` was unable to calculate a new route.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerRoutingErrorKey;

/**
 A key in the user info dictionary of a `MBRouteControllerDidRerouteNotification` notification. The corresponding value is an `NSNumber` instance containing a Boolean value indicating whether `RouteController` proactively rerouted the user onto a faster route.
 */
extern const MBRouteControllerNotificationUserInfoKey MBRouteControllerIsProactiveKey;

@interface NSString (MD5)
- (NSString * _Nonnull)md5;
@end

