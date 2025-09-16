package ca.pkay.rcloneexplorer.util;

import android.app.Activity;
import android.content.Context;
import android.content.res.AssetManager;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.AttributeSet;
import android.webkit.WebView;
import android.widget.Toast;

import org.markdownj.MarkdownProcessor;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.ref.WeakReference;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import es.dmoral.toasty.Toasty;

public class MarkdownView extends WebView {

    private static final String TAG = "MarkdownView";
    private static ExecutorService executor;
    private static Handler mainHandler;

    static {
        executor = Executors.newCachedThreadPool();
        mainHandler = new Handler(Looper.getMainLooper());
    }

    public MarkdownView(Context context) {
        super(patchContext(context));
    }

    public MarkdownView(Context context, AttributeSet attrs) {
        super(patchContext(context), attrs);
    }

    public static void closeOnMissingWebView(Activity host, Exception exception) {
        if (exception.getMessage() != null && exception.getMessage().contains("Failed to load WebView provider: No WebView installed")) {
            FLog.e(TAG, "onCreate: Failed to load WebView (Appcenter PUB #49494606u)", exception);
            Toasty.error(host.getApplicationContext(), "Install WebView and try again", Toast.LENGTH_LONG, true).show();
            host.finish();
        } else {
            throw new RuntimeException(exception);
        }
    }

    private static Context patchContext(Context context) {
        // TODO: Only affects appcompat 1.1.x, remove with 1.2.x
        //       https://stackoverflow.com/questions/41025200/android-view-inflateexception-error-inflating-class-android-webkit-webview/58131421
        if (Build.VERSION.SDK_INT == 22 || Build.VERSION.SDK_INT == 23) {
            return context.createConfigurationContext(new Configuration());
        }
        return context;
    }

    public void loadAsset(String path) {
        if (path == null || path.trim().isEmpty()) {
            loadUrl("about:blank");
            return;
        }
        
        // Get context on main thread before background processing
        Context context = getContext();
        if (context == null) {
            FLog.e(TAG, "Context is null, cannot load asset: " + path);
            loadUrl("about:blank");
            return;
        }
        
        new LoadMarkdownAsset(path, this, context).execute();
    }

    private static class LoadMarkdownAsset {
        private static final String TAG = "LoadMarkdownAsset";
        private final String assetName;
        private final WeakReference<WebView> webViewRef;
        private final Context context;

        public LoadMarkdownAsset(String assetName, WebView webView, Context context) {
            this.assetName = assetName;
            this.webViewRef = new WeakReference<>(webView); // Prevent memory leaks
            this.context = context.getApplicationContext(); // Use application context to avoid leaks
        }

        public void execute() {
            executor.execute(() -> {
                try {
                    String html = doInBackground();
                    
                    // Post result back to main thread
                    mainHandler.post(() -> onPostExecute(html));
                } catch (Exception e) {
                    FLog.e(TAG, "Error loading markdown asset: " + assetName, e);
                    mainHandler.post(() -> onPostExecute(null));
                }
            });
        }

        private String doInBackground() {
            if (context == null) {
                FLog.e(TAG, "Context is null in background thread");
                return null;
            }

            AssetManager assetManager = context.getAssets();
            StringBuilder markdown = new StringBuilder(4096);
            
            try (BufferedReader br = new BufferedReader(new InputStreamReader(assetManager.open(assetName)))) {
                String line;
                while ((line = br.readLine()) != null) {
                    // Use \n as line separator so that the processor does not
                    // have to replace this.
                    markdown.append(line).append('\n');
                }
                
                if (markdown.length() == 0) {
                    FLog.w(TAG, "Empty markdown content for asset: " + assetName);
                    return null;
                }
                
                return new MarkdownProcessor().markdown(markdown.toString());
            } catch (IOException e) {
                FLog.e(TAG, "Could not load asset: " + assetName, e);
                return null;
            } catch (Exception e) {
                FLog.e(TAG, "Error processing markdown for asset: " + assetName, e);
                return null;
            }
        }

        private void onPostExecute(String html) {
            WebView webView = webViewRef.get();
            if (webView == null) {
                FLog.w(TAG, "WebView reference is null, cannot load content");
                return;
            }

            try {
                if (html == null || html.trim().isEmpty()) {
                    webView.loadUrl("about:blank");
                } else {
                    webView.loadDataWithBaseURL("local://", html, "text/html", "UTF-8", null);
                }
            } catch (Exception e) {
                FLog.e(TAG, "Error loading HTML content into WebView", e);
                try {
                    webView.loadUrl("about:blank");
                } catch (Exception fallbackException) {
                    FLog.e(TAG, "Failed to load blank page as fallback", fallbackException);
                }
            }
        }
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        // Clean up resources if needed
    }

    // Clean up static resources when no longer needed
    public static void cleanup() {
        if (executor != null && !executor.isShutdown()) {
            executor.shutdown();
        }
    }
}
