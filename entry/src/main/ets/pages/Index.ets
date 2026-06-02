import { webview } from '@kit.ArkWeb';
import { window } from '@kit.ArkUI';
import { display } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
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
          if (HttpProxy.isInternalUrl(url)) {
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
        .onLoadIntercept((event) => {
          if (!event) return false;
          const url: string = event.data.getRequestUrl();
          // 只允许内部伪域名在 WebView 内加载
          if (HttpProxy.isInternalUrl(url)) {
            return false;
          }
          // 外部链接：拦截并用系统浏览器打开
          try {
            const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
            const want: Want = {
              action: 'ohos.want.action.viewData',
              entities: ['entity.system.browsable'],
              uri: url
            };
            ctx.startAbility(want);
          } catch (err) {
            // 静默失败
          }
          return true; // 拦截，不在 WebView 内加载
        })
    }
    .height('100%')
    .width('100%')
    .padding({ top: this.statusBarHeight })
  }
}