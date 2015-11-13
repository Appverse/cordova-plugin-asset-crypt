#!/usr/bin/env node

var crypto = require('crypto');
var fs = require('fs');
var path = require('path');

module.exports = function(_context) {

    var ConfigParser = _context.requireCordovaModule('cordova-lib').configparser;

    var password =  crypto.randomBytes(16).toString('hex');
    var key = crypto.createHash("sha256").update(password).digest();
    var iv = crypto.createHash("md5").update(password).digest();

    console.log("Password=%s key=%s iv=%s", password, key.toString('hex'), iv.toString('hex'));

    // console.log("platforms: %j", _context);

    var rootDir = _context.opts.projectRoot;

    _context.opts.platforms.map(function(_platform) {

        if (_platform == 'android') {
            var androidDir = path.join(rootDir, 'platforms/android');
            var assetsDir = path.join(androidDir, 'assets');
            var cdataDir = path.join(assetsDir, 'cdata');
            var wwwDir = path.join(assetsDir, 'www');

            // Fix configuration
            changeConfigXml(path.join(androidDir, 'res/xml/config.xml'));

            // Fix Java Code
            changePassword_android(androidDir, password);

            // Create or clean cdata Directory
            deleteFolderRecursive(cdataDir);
            fs.mkdirSync(cdataDir);

            console.log("Encrypting android assets...");
            findAssets(assetsDir, "www/").forEach(function(_fileName) {
                var cryptedPath = path.join(cdataDir, encodeName(_fileName, password));
                var originalPath = path.join(assetsDir, _fileName);
                // console.log("encrypting %s to %s", originalPath, cryptedPath);
                encryptAsset(originalPath, cryptedPath, key, iv);
            });
            console.log("Deleting decrypted assets...");
            deleteFolderRecursive(wwwDir);
        } else if (_platform == 'ios') {
            var config = new ConfigParser(path.join(rootDir, 'config.xml'));
            var appName = config.doc.findall('name')[0].text;

            var iosDir = path.join(rootDir, 'platforms', _platform);
            var cdataDir = path.join(iosDir, appName, 'Resources', 'cdata.bundle');
            var srcDir = path.join(iosDir, appName, 'Plugins', 'cordova-plugin-asset-crypt');
            var wwwDir = path.join(iosDir, 'www');

            // Fix configuration
            changeConfigXml(path.join(iosDir, appName, 'config.xml'));

            // Fix Objective C Code
            changePassword_ios(srcDir, password);

            // Create or clean cdata Directory
            deleteFolderRecursive(cdataDir);
            fs.mkdirSync(cdataDir);

            console.log("Encrypting android assets...");
            findAssets(iosDir, "www/").forEach(function (_fileName) {
                var cryptedPath = path.join(cdataDir, encodeName(_fileName, password));
                var originalPath = path.join(iosDir, _fileName);
                // console.log("encrypting %s to %s", originalPath, cryptedPath);
                encryptAsset(originalPath, cryptedPath, key, iv);
            });
            console.log("Deleting decrypted assets...");
            deleteFolderRecursive(wwwDir);
            fs.mkdirSync(wwwDir);

        } else {
          console.log("I'm sorry, platform " + _platform + " is not supported yet!");
        }
    });

    var Q = _context.requireCordovaModule('q');
    var deferral = new Q.defer();

    deferral.resolve();

    return deferral.promise;
}

//----------------------------------------------------------- Private functions

/**
 * Returns an array of asset files
 *
 * @param baseDir Base directory to perform scan
 * @param relativeDir Relative dir we are scanning
 *
 * @returns {Array} of file assets found
 */
function findAssets(baseDir, relativeDir) {
    var files = [];
    relativeDir = relativeDir || '';

    var scanDir = path.join(baseDir, relativeDir);
    var fileNames = fs.readdirSync(scanDir);
    fileNames.forEach( function(name) {
        var filePath = path.join(scanDir, name);
        var fileName = path.join(relativeDir, name);
        if(fs.lstatSync(filePath).isDirectory()) {
            findAssets(baseDir, fileName).forEach( function (__name) {
                files.push( __name );
            });
        } else {
            files.push(fileName);
        }
    });
    return files;
}

/**
 * FileName obfuscation.
 *
 * @param fileName
 * @param password
 * @returns {*}
 */
function encodeName(fileName, password) {
    var hash = crypto.createHash('sha256');
    hash.update(password + fileName, 'utf8');
    var digest = hash.digest('hex');
    return digest;
}

/**
 * Asset encryption.
 *
 * @param plainFile
 * @param cryptedFile
 * @param key
 * @param iv
 */
function encryptAsset(plainFile, cryptedFile, key, iv) {
    var cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
    cipher.setAutoPadding(true);
    var input = fs.createReadStream(plainFile);
    var output = fs.createWriteStream(cryptedFile);

    input.pipe(cipher).pipe(output);
}

/**
 * Update content source in config.xml
 * @param configFile
 */
function changeConfigXml(configFile) {
    var content = fs.readFileSync(configFile, 'utf-8');
    var replacedContent = content.replace(/content src=".*"/, 'content src="crypt://localhost/index.html"');
    fs.writeFileSync(configFile, replacedContent, 'utf-8');
}

/**
 * Update password content in java source
 * @param pluginDir
 * @param password
 */
function changePassword_android(pluginDir, password) {
    var javaFile = path.join(pluginDir, 'src/com/gft/cordova/plugins/assetcrypt/AssetCrypt.java');
    var content = fs.readFileSync(javaFile, 'utf-8');

    var replacedContent = content.replace(/_PASSWORD_ = ".*";/, '_PASSWORD_ = "' + password + '";');

    fs.writeFileSync(javaFile, replacedContent, 'utf-8');
}

/**
 * Update password content in java source
 * @param srcDir
 * @param password
 */
function changePassword_ios(srcDir, password) {
    var objcFile = path.join(srcDir, 'AssetCrypt.m');
    var content = fs.readFileSync(objcFile, 'utf-8');

    var replacedContent = content.replace(/_PASSWORD_ = @".*";/, '_PASSWORD_ = @"' + password + '";');

    fs.writeFileSync(objcFile, replacedContent, 'utf-8');
}


/**
 * Remove directory and all contained files and directories.
 * @param _path
 */
function deleteFolderRecursive(_path) {
    var files = [];
    if( fs.existsSync(_path) ) {
        files = fs.readdirSync(_path);
        files.forEach(function(file,index){
            var curPath = _path + "/" + file;
            if(fs.lstatSync(curPath).isDirectory()) { // recurse
                deleteFolderRecursive(curPath);
            } else { // delete file
                fs.unlinkSync(curPath);
            }
        });
        fs.rmdirSync(_path);
    }
};