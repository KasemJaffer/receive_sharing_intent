#import "ReceiveSharingIntentPlugin.h"
#if __has_include(<receive_sharing_intent/receive_sharing_intent-Swift.h>)
#import <receive_sharing_intent/receive_sharing_intent-Swift.h>
#else
#import "receive_sharing_intent-Swift.h"
#endif

@implementation ReceiveSharingIntentPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftReceiveSharingIntentPlugin registerWithRegistrar:registrar];
}
@end
