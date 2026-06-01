import { webview } from '@kit.ArkWeb';
import { window } from '@kit.ArkUI';
import { display } from '@kit.ArkUI';
import { HttpProxy } from '../proxy/HttpProxy';

/**
 * 全屏适配：
 * - EntryAbility 中 setWindowLayoutFullScreen(true) 让窗口延伸到状态栏后面
 * - getWindowAvoidArea 获取顶部安全区高度 → Column paddingTop 避让
 */
@Entry
@Component
struct Index {
  controller: webview.WebviewController = new webview.WebviewController();
  @State statusBarHeight: number = 0;

  aboutToAppear(): void {
    try {
      const ctx = this.getUIContext().getHostContext();
      window.getLastWindow(ctx).then((win: window.Window) => {
        const avoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        const density = display.getDefaultDisplaySync().densityPixels;
        this.statusBarHeight = avoidArea.topRect.height / density;
      });
    } catch (err) {
      // fallback
    }
  }

  build() {
    Column() {
      Web({ src: 'https://real-time-fund.local/index.html', controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .mixedMode(MixedMode.All)
        .onInterceptRequest((event) => {
          if (!event) return null;
          const url: string = event.request.getRequestUrl();
          if (url.includes('real-time-fund.local')) {
            const rawPath: string | null = HttpProxy.mapToRawfilePath(url);
            if (rawPath) {
              const response: WebResourceResponse = new WebResourceResponse();
              response.setResponseData($rawfile(rawPath));
              response.setResponseMimeType(HttpProxy.getMimeType(rawPath));
              return response;
            }
          }
          return null;
        })
    }
    .height('100%')
    .width('100%')
    .padding({ top: this.statusBarHeight })
  }
}