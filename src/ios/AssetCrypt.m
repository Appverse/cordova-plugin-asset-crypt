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

