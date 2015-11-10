package com.gft.cordova.plugins.assetcrypt;

import android.net.Uri;
import android.util.Log;
import android.webkit.MimeTypeMap;

import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaResourceApi;
import org.apache.cordova.CordovaWebView;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.MessageDigest;
import java.util.Locale;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

/**
 * Created by jordi.murgo@gft.com on 14/01/16.
 */
public class AssetCrypt extends CordovaPlugin {

    final static String TAG = "AssetCrypt";

    final private String _PASSWORD_ = "android";
    private byte[] key;
    private byte[] iv;

    private String PLUGIN_URI_PREFIX;
    final private String FAKE_URI_PREFIX = "crypt://localhost/";

    /**
     * Called after plugin construction and fields have been initialized.
     * Prefer to use pluginInitialize instead since there is no value in
     * having parameters on the initialize() function.
     *
     * @param cordova
     * @param webView
     */
    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        // Log.i(TAG, "Initializing");
        super.initialize(cordova, webView);

        this.PLUGIN_URI_PREFIX = CordovaResourceApi.PLUGIN_URI_SCHEME + "://" + getServiceName() + "/";

        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update(this._PASSWORD_.getBytes("UTF-8"));
            key = md.digest();
            // Log.d(TAG, "Key " + key.length*8 + " bits: "+ byteToHex(key));

            md = MessageDigest.getInstance("MD5");
            md.update(this._PASSWORD_.getBytes("UTF-8"));
            iv = md.digest();
            // Log.d(TAG, "IV " + iv.length*8 + " bits: "+ byteToHex(iv));
        } catch(Exception ex) {
            Log.e(TAG, ex.getLocalizedMessage(), ex);
        }
    }

    /**
     * Hook for redirecting requests. Applies to WebView requests as well as requests made by plugins.
     * To handle the request directly, return a URI in the form:
     *
     *    cdvplugin://pluginId/...
     *
     * And implement handleOpenForRead().
     *
     * @param uri original uri "crypt://localhost/index.html"
     * @return rewrited uri redirecting requests to the plugin "cdvplugin://AssetCrypt/index.html"
     */
    @Override
    public Uri remapUri(Uri uri) {
        if(!uri.toString().startsWith(FAKE_URI_PREFIX)) {
            Log.d(TAG, "Ignoring URI " + uri.toString());
            return uri;
        }
        Uri toUri =  Uri.parse(uri.toString().replace(FAKE_URI_PREFIX, PLUGIN_URI_PREFIX));
        Log.d(TAG, "Remaping URI from " + uri.toString() + " to " + toUri.toString() );
        return toUri;
    }

    /**
     * Called to handle CordovaResourceApi.openForRead() calls for a cdvplugin://pluginId/ URL.
     * Should never return null.
     * Added in cordova-android@4.0.0
     *
     * @param uri   Uri requested, like "cdvplugin://AssetCrypt/index.html"
     * @return  OpenForReadResult containing data, len and content type.
     * @throws IOException
     */
    @Override
    public CordovaResourceApi.OpenForReadResult handleOpenForRead(Uri uri) throws IOException {
        // Log.i(TAG, "handleOpenForRead " + uri.toString());
        String originalName = "www" + uri.getEncodedPath();
        String assetPath = "cdata/" + encodeAssetName(originalName);
        Log.d(TAG, "handleOpenForRead asset path: " + assetPath);

        CordovaResourceApi.OpenForReadResult readResult = null;

        try {
            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");

            cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(key, "AES"), new IvParameterSpec(iv));

            InputStream is = webView.getContext().getAssets().open(assetPath);
            int size = is.available();
            byte [] buffer = new byte[size];
            is.read(buffer);
            byte [] clean = cipher.doFinal(buffer);
            Log.i(TAG, "Decoded " + clean.length + " bytes.");

            InputStream bis = new ByteArrayInputStream(clean);
            readResult = new CordovaResourceApi.OpenForReadResult(uri, bis, getMimeTypeFromPath(originalName), clean.length, null);

        } catch(Exception ex) {
            Log.e(TAG, ex.getLocalizedMessage(), ex);
        }

        return readResult;
    }

    /**
     * Convert byte array to hexadecimal string.
     *
     * @param bytes the byte array
     * @return String in the form "0e34f5abc43...."
     */
    private String byteToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) // This is your byte[] result..
        {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    /**
     * Obfuscates the asset name, hashing the password and the asset name.
     *
     * @param assetName The asset name.
     *
     * @return Obfuscated equivalent like "c49206425605a343e74df1834590fd2492fa9f6fca6278984c9b459ec97ec80e"
     */
    private String encodeAssetName(String assetName) {
        String base = this._PASSWORD_ + assetName;
        String digest = null;
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update(base.getBytes("UTF-8"));
            byte[] result = md.digest();
            digest = byteToHex(result);

        } catch(Exception ex) {
            Log.e(TAG, ex.getLocalizedMessage(), ex);
        }
        // Log.i(TAG, "HASH ********* [" + base + "] [" + digest + "]");
        return digest;
    }

    /**
     * Get the content type based on file extension.
     *
     * @param path asset path.
     * @return String with the content type.
     */
    private String getMimeTypeFromPath(String path) {
        String extension = path;
        int lastDot = extension.lastIndexOf('.');
        if (lastDot != -1) {
            extension = extension.substring(lastDot + 1);
        }
        // Convert the URI string to lower case to ensure compatibility with MimeTypeMap (see CB-2185).
        extension = extension.toLowerCase(Locale.getDefault());
        if (extension.equals("3ga")) {
            return "audio/3gpp";
        } else if (extension.equals("js")) {
            // Missing from the map :(.
            return "text/javascript";
        }

        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
    }

}
