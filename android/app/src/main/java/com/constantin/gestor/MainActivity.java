package com.constantin.gestor;

import android.app.Activity;
import android.content.ContentValues;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import androidx.webkit.WebViewAssetLoader;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

/**
 * O app é a mesma página do PWA rodando numa WebView.
 *
 * Os arquivos não são carregados por file:// — nesse esquema o Chromium bloqueia
 * IndexedDB e o app não conseguiria salvar nada. Em vez disso, o WebViewAssetLoader
 * serve a pasta assets/www sob https://appassets.androidplatform.net, que é uma
 * origem segura de verdade, e aí o armazenamento local funciona normalmente.
 */
public class MainActivity extends Activity {

    private static final String ORIGEM = "https://appassets.androidplatform.net";
    private WebView web;
    private ValueCallback<Uri[]> escolhaArquivo;
    private static final int PEDIDO_ARQUIVO = 1001;

    @Override
    protected void onCreate(Bundle estado) {
        super.onCreate(estado);

        final WebViewAssetLoader loader = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
                .build();

        web = new WebView(this);
        setContentView(web);

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setSupportZoom(false);
        s.setTextZoom(100);

        web.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView v, WebResourceRequest r) {
                return loader.shouldInterceptRequest(r.getUrl());
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest r) {
                Uri u = r.getUrl();
                if (u.toString().startsWith(ORIGEM)) return false;
                // qualquer link externo abre no navegador, não dentro do app
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, u));
                } catch (Exception ignored) { }
                return true;
            }
        });

        // necessário para o "Importar backup" abrir o seletor de arquivos
        web.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView v, ValueCallback<Uri[]> cb,
                                             FileChooserParams params) {
                if (escolhaArquivo != null) escolhaArquivo.onReceiveValue(null);
                escolhaArquivo = cb;
                try {
                    // params.createIntent() repassa o filtro de tipo da página, e o
                    // seletor do Android acinzenta .ofx/.csv porque esses arquivos
                    // chegam como tipo desconhecido. Aqui abrimos sem filtro.
                    Intent i = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                    i.addCategory(Intent.CATEGORY_OPENABLE);
                    i.setType("*/*");
                    startActivityForResult(
                            Intent.createChooser(i, "Escolher extrato"), PEDIDO_ARQUIVO);
                } catch (Exception e) {
                    escolhaArquivo = null;
                    return false;
                }
                return true;
            }
        });

        web.addJavascriptInterface(new Ponte(), "AndroidBridge");
        web.loadUrl(ORIGEM + "/assets/www/index.html");
    }

    @Override
    protected void onActivityResult(int pedido, int resultado, Intent dados) {
        if (pedido == PEDIDO_ARQUIVO) {
            if (escolhaArquivo != null) {
                escolhaArquivo.onReceiveValue(
                        WebChromeClient.FileChooserParams.parseResult(resultado, dados));
                escolhaArquivo = null;
            }
            return;
        }
        super.onActivityResult(pedido, resultado, dados);
    }

    /**
     * O botão físico de voltar pergunta ao app o que fazer: fechar o modal aberto,
     * voltar uma tela, ou — se não houver para onde voltar — sair.
     */
    @Override
    public void onBackPressed() {
        web.evaluateJavascript(
                "(window.androidBack ? window.androidBack() : false)",
                valor -> { if (!"true".equals(valor)) finish(); });
    }

    /** Exposta ao JavaScript como window.AndroidBridge. */
    public class Ponte {
        @JavascriptInterface
        public void salvar(String nome, String conteudo) {
            runOnUiThread(() -> {
                try {
                    byte[] bytes = conteudo.getBytes(StandardCharsets.UTF_8);
                    String tipo = nome.endsWith(".csv") ? "text/csv" : "application/json";

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        ContentValues cv = new ContentValues();
                        cv.put(MediaStore.Downloads.DISPLAY_NAME, nome);
                        cv.put(MediaStore.Downloads.MIME_TYPE, tipo);
                        cv.put(MediaStore.Downloads.IS_PENDING, 1);
                        Uri destino = getContentResolver()
                                .insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, cv);
                        if (destino == null) throw new Exception("sem destino");
                        try (OutputStream os = getContentResolver().openOutputStream(destino)) {
                            os.write(bytes);
                        }
                        cv.clear();
                        cv.put(MediaStore.Downloads.IS_PENDING, 0);
                        getContentResolver().update(destino, cv, null, null);
                    } else {
                        File dir = Environment.getExternalStoragePublicDirectory(
                                Environment.DIRECTORY_DOWNLOADS);
                        if (!dir.exists()) dir.mkdirs();
                        try (FileOutputStream fos = new FileOutputStream(new File(dir, nome))) {
                            fos.write(bytes);
                        }
                    }
                    Toast.makeText(MainActivity.this,
                            "Salvo em Downloads: " + nome, Toast.LENGTH_LONG).show();
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this,
                            "Não consegui salvar o arquivo", Toast.LENGTH_LONG).show();
                }
            });
        }
    }
}
