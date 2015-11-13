/**
 * Created by jordi.murgo@gft.com on 21/01/2016.
 */
#import "AssetCrypt.h"
#import "CryptProtocol.h"
#import "FBEncryptorAES.h"

static NSData *key = nil;
static NSData *iv = nil;
static NSString *_PASSWORD_ = @"4112fd7444b069da21e906b2d0c5b38c";

@implementation AssetCrypt

- (void) pluginInitialize
{
    //
    // Initialize Crypto
    //
    key = [FBEncryptorAES SHA256ForString:_PASSWORD_];
    iv =  [FBEncryptorAES MD5ForString:_PASSWORD_];

    NSLog(@"Password: %@", _PASSWORD_);
    NSLog(@"Key: %@", [FBEncryptorAES hexStringForData:key]);
    NSLog(@"IV: %@", [FBEncryptorAES hexStringForData:iv]);

    //
    // Register Protocol
    //
    [NSURLProtocol registerClass:[CryptProtocol class]];
}

+ (NSData *) keyData
{
    return key;
}

+ (NSData *) ivData
{
    return iv;
}


+ (NSString *) passwordString
{
    return _PASSWORD_;
}

@end

