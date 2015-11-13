/**
 * Created by jordi.murgo@gft.com on 21/01/2016.
 */

#import "CryptProtocol.h"
#import "AssetCrypt.h"
#import "FBEncryptorAES.h"

#import <MobileCoreServices/MobileCoreServices.h>

#define CRYPT_PROTO_SCHEME @"crypt"

@implementation CryptProtocol

/**
 *  return YES when URL scheme is crypt://
 */
+ (BOOL)canInitWithRequest:(NSURLRequest*)request
{
    NSURL* url = request.URL;

    if ([url.scheme isEqual:CRYPT_PROTO_SCHEME]) {
        return YES;
    }

    return [super canInitWithRequest:request];
}

- (void) startLoading
{
    NSURL *url = self.request.URL;
    NSString *mimeType = [self getMimeType:url];
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *uriPath = [@"www" stringByAppendingString:url.path];
    NSString *hashName = [FBEncryptorAES hexStringForData:[FBEncryptorAES SHA256ForString:[[AssetCrypt passwordString] stringByAppendingString:uriPath]]];
    NSString *filePath = [resourcePath stringByAppendingString:[@"/cdata.bundle/" stringByAppendingString:hashName]];

    NSData* cryptedContent = [NSData dataWithContentsOfFile:filePath];
    if (cryptedContent != nil) {
        NSData *data = [FBEncryptorAES decryptData:cryptedContent key:[AssetCrypt keyData] iv:[AssetCrypt ivData]];
        NSLog(@"Decrypted %@ (%@)", url, hashName);
        [self sendResponseWithResponseCode:200 data:data mimeType:mimeType];
    }

    [super startLoading];
}

- (NSString*)getMimeType:(NSURL *)url
{
    NSString *fullPath = url.path;
    NSString *mimeType = nil;

    if (fullPath) {
        CFStringRef typeId = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[fullPath pathExtension], NULL);
        if (typeId) {
            mimeType = (__bridge_transfer NSString*)UTTypeCopyPreferredTagWithClass(typeId, kUTTagClassMIMEType);
            if (!mimeType) {
                // special case for m4a
                if ([(__bridge NSString*)typeId rangeOfString : @"m4a-audio"].location != NSNotFound) {
                    mimeType = @"audio/mp4";
                } else if ([[fullPath pathExtension] rangeOfString:@"wav"].location != NSNotFound) {
                    mimeType = @"audio/wav";
                } else if ([[fullPath pathExtension] rangeOfString:@"css"].location != NSNotFound) {
                    mimeType = @"text/css";
                }
            }
            CFRelease(typeId);
        }
    }
    return mimeType;
}

- (void)sendResponseWithResponseCode:(NSInteger)statusCode data:(NSData*)data mimeType:(NSString*)mimeType
{
    if (mimeType == nil) {
        mimeType = @"text/plain";
    }

    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:[[self request] URL] statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:@{@"Content-Type" : mimeType}];

    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    if (data != nil) {
        [[self client] URLProtocol:self didLoadData:data];
    }
    [[self client] URLProtocolDidFinishLoading:self];
}


@end

