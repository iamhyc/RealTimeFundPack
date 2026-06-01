# RealTimeFund

基估宝（real-time-fund）的 HarmonyOS WebView 混合增强封装。将 Next.js 静态导出的 Web 应用通过伪域名 + `onInterceptRequest` 架构嵌入原生 App，原生层代理所有金融数据 HTTP 请求。

## Language

**上游（Upstream）**:
`hzm0321/real-time-fund` Git 仓库，纯 JavaScript Next.js 16 静态导出 Web 应用。
_Avoid_: Web 端、前端、源项目

**封装（Wrapper）**:
HarmonyOS 原生 App 壳，通过 `Web` 组件承载上游 Web 应用的 UI 渲染。
_Avoid_: 宿主、容器、壳子

**伪域名（Fake Domain）**:
形如 `https://real-time-fund.local/` 的虚拟 URL，用于加载本地 rawfile 中的 Web 资源，使 WebView 内核以 HTTP 协议（而非 `file://` 或 `resource://`）解析路径和跨域策略。
_Avoid_: 本地域名、虚拟主机

**HTTP 代理层（HTTP Proxy Layer）**:
`onInterceptRequest` 回调中对指定外部域名（天天基金、东方财富、腾讯财经）发起的原生 HTTP 请求，替代 WebView 内的 JSONP/script 注入。
_Avoid_: 请求拦截层、网络代理

**JSONP 数据源（JSONP Data Source）**:
天天基金（`fundgz.1234567.com.cn`）、东方财富（`fund.eastmoney.com`）、腾讯财经（`qt.gtimg.cn`）——这些外部 API 的响应格式是 JavaScript 回调函数调用，而非 JSON。
_Avoid_: API、数据接口

**rawfile 产物（Rawfile Artifact）**:
上游 `npm run build` 输出的 `out/` 目录内容，经 Python 构建脚本复制到 `entry/src/main/resources/rawfile/web/`。
_Avoid_: 静态资源、dist

**上游版本锁定（Upstream Pin）**:
通过 Git Submodule 的 commit hash 精确锁定上游 Web 代码版本，发版节奏由 RealTimeFund 项目控制。
_Avoid_: 依赖锁定
