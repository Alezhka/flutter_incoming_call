#import "FlutterIncomingCallPlugin.h"
#if __has_include(<flutter_incoming_call/flutter_incoming_call-Swift.h>)
#import <flutter_incoming_call/flutter_incoming_call-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_incoming_call-Swift.h"
#endif

@implementation FlutterIncomingCallPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterIncomingCallPlugin registerWithRegistrar:registrar];
}
@end
