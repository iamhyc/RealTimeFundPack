# 伪域名 + onInterceptRequest 透明代理架构

决定使用 `https://real-time-fund.local/` 伪域名加载本地 Web 资源，并通过 `onInterceptRequest` 统一处理资源映射与 JSONP 数据代理，实现 Web 端零改动接入。

## 决策背景

上游 `real-time-fund` 是 Next.js 静态导出的纯 Web 应用，所有外部数据通过 JSONP（动态 `<script>` 标签）从天天基金/东方财富/腾讯财经获取。需要将其封装为 HarmonyOS 原生 App，约束是**不修改上游 Web 代码**。

## 考虑过的方案

**A. `file://` 协议直接加载 rawfile**
- 问题：`file://` 协议下跨域策略极为严格，JSONP 的 `<script>` 标签注入外部域名可能被阻止；绝对路径（`/_next/static/...`）解析错误。
- 结论：不可靠。

**B. `resource://rawfile/` 协议加载**
- 问题：同 A，且 `resource://` 协议行为未在公开文档中完全定义。
- 结论：不可靠。

**C. 内嵌本地 HTTP Server（C++/mongoose）**
- 问题：增加 C++ 依赖和包体积；端口冲突风险；构建复杂度显著增加。
- 结论：过度工程化。

**D. 伪域名 + onInterceptRequest（选中）**
- 做法：WebView 加载 `https://real-time-fund.local/index.html`，所有该域名的资源请求被 `onInterceptRequest` 拦截，映射到 `rawfile/web/` 对应文件；外部 JSONP 数据源 URL 同样拦截，由 ArkTS `http` 模块代理。
- 优势：Web 端路径解析完全正确（`/_next/static/xxx.js` → `https://real-time-fund.local/_next/static/xxx.js`）；CORS 无问题（所有请求同源）；零修改上游代码；OpenHarmony 官方示例（`LocCrossOriginResAccSol`）验证可行。

## 后果

- `onInterceptRequest` 成为架构咽喉，所有资源请求经过此回调；回调中需根据 URL 做三分支分发（本地资源/JSONP代理/放行）。
- JSONP 数据源域名白名单需维护。上游若新增数据源，只需加一行域名常量。
- 伪域名选择需确保不与真实域名冲突。`real-time-fund.local` 使用 `.local` TLD（RFC 6762 保留用于多播 DNS），不会解析到公网。
- **V1 限制**：`onInterceptRequest` 是同步回调，无法在其中 await 异步 HTTP 请求。因此 V1 阶段 JSONP 请求不拦截，由 WebView 引擎原生处理（`<script>` 标签天然跨域）。V2 可通过 C++ `ArkWeb_SchemeHandler` 或 `onLoadIntercept` + `runJavaScript` 注入实现原生 HTTP 代理。
