/*
    Copyright (c) 2015 GFT Appverse, S.L., Sociedad Unipersonal.

    This Source Code Form is subject to the terms of the Appverse Public License
    Version 2.0 (“APL v2.0”). If a copy of the APL was not distributed with this
    file, You can obtain one at <http://appverse.org/#/license/information>. 

    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the conditions of the AppVerse Public License v2.0
    are met.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. EXCEPT IN CASE OF WILLFUL MISCONDUCT OR GROSS NEGLIGENCE, IN NO EVENT
    SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE)
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
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

