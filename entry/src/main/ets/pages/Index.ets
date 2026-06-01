import { webview } from '@kit.ArkWeb';
import { HttpProxy } from '../proxy/HttpProxy';

/**
 * 基估宝 HarmonyOS WebView 封装主页面。
 *
 * 架构：
 * - 通过伪域名 https://real-time-fund.local/ 加载本地 rawfile 中的 Web 资源
 * - onInterceptRequest 拦截伪域名请求，映射到 rawfile 对应文件
 * - JSONP 数据请求不拦截，由 WebView 引擎原生处理（<script> 标签天然跨域）
 * - fetchJsonpData 保留用于未来 V2 后台缓存/预取增强
 */
@Entry
@Component
struct Index {
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    Column() {
      Web({ src: 'https://real-time-fund.local/index.html', controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .mixedMode(MixedMode.All)
        .onInterceptRequest((event) => {
          if (!event) {
            return null;
          }
          const url: string = event.request.getRequestUrl();

          // 分支1：伪域名本地资源 → rawfile 映射
          if (url.includes('real-time-fund.local')) {
            const rawPath: string | null = HttpProxy.mapToRawfilePath(url);
            if (rawPath) {
              const response: WebResourceResponse = new WebResourceResponse();
              response.setResponseData($rawfile(rawPath));
              response.setResponseMimeType(HttpProxy.getMimeType(rawPath));
              return response;
            }
          }

          // 分支2：其他所有请求（JSONP/Supabase/CDN）→ 放行，WebView 原生处理
          return null;
        })
    }
    .height('100%')
    .width('100%')
  }
}