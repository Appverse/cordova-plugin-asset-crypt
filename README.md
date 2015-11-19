# Cordova crypted assets plugin
Files in `assets/www` directory are encrypted at build, and decrypted at run.  
Encrypted files are generated into `assets/cdata` using hashed filenames.  

## Add Plugin
`cordova plugin add cordova-plugin-asset-crypt`

## Encrypt (building app)
`cordova build [ios / android]`

## Decrypt (running the app)
`cordova emulate [ios / android]`  
or  
`cordova run [ios / android]`  

## Supported platforms
* iOS
* Android

## License

     Copyright (c) 2015 GFT Appverse, S.L., Sociedad Unipersonal

     This Source  Code Form  is subject to the  terms of  the Appverse Public License
     Version 2.0  ("APL v2.0").  If a copy of  the APL  was not  distributed with this
     file, You can obtain one at <http://appverse.org/#/license/information>.

     Redistribution and use in  source and binary forms, with or without modification,
     are permitted provided that the  conditions  of the  AppVerse Public License v2.0
     are met.

     THIS SOFTWARE IS PROVIDED BY THE  COPYRIGHT HOLDERS  AND CONTRIBUTORS "AS IS" AND
     ANY EXPRESS  OR IMPLIED WARRANTIES, INCLUDING, BUT  NOT LIMITED TO,   THE IMPLIED
     WARRANTIES   OF  MERCHANTABILITY   AND   FITNESS   FOR A PARTICULAR  PURPOSE  ARE
     DISCLAIMED. EXCEPT IN CASE OF WILLFUL MISCONDUCT OR GROSS NEGLIGENCE, IN NO EVENT
     SHALL THE  COPYRIGHT OWNER  OR  CONTRIBUTORS  BE LIABLE FOR ANY DIRECT, INDIRECT,
     INCIDENTAL,  SPECIAL,   EXEMPLARY,  OR CONSEQUENTIAL DAMAGES  (INCLUDING, BUT NOT
     LIMITED TO,  PROCUREMENT OF SUBSTITUTE  GOODS OR SERVICES;  LOSS OF USE, DATA, OR
     PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
     WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE)
     ARISING  IN  ANY WAY OUT  OF THE USE  OF THIS  SOFTWARE,  EVEN  IF ADVISED OF THE
     POSSIBILITY OF SUCH DAMAGE.
