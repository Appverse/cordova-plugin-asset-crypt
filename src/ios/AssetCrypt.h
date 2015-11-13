/**
 * Created by jordi.murgo@gft.com on 21/01/2016.
 */

#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

@interface AssetCrypt : CDVPlugin 

- (void) pluginInitialize;
+ (NSData *) keyData;
+ (NSData *) ivData;
+ (NSString *) passwordString;

@end