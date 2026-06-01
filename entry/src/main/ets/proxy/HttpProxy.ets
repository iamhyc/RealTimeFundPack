/**
 * HTTP 代理模块 — 负责 URL 匹配、rawfile 路径映射、MIME 类型检测、JSONP 数据代理。
 * 所有与 onInterceptRequest 相关的纯逻辑集中于此，便于单元测试。
 */

const FAKE_DOMAIN = 'real-time-fund.local';
const RAWFILE_PREFIX = 'web/';

const JSONP_DOMAINS: string[] = [
  'fundgz.1234567.com.cn',   // 天天基金 — 实时估值
  'fund.eastmoney.com',       // 东方财富 — 重仓数据
  'qt.gtimg.cn',              // 腾讯财经 — 股票行情
];

export class HttpProxy {
  /**
   * 判断给定 URL 是否属于需要代理的 JSONP 数据源。
   */
  static isJsonpDataSource(url: string): boolean {
    if (!url || url.length === 0) {
      return false;
    }
    return JSONP_DOMAINS.some((domain: string) => url.includes(domain));
  }

  /**
   * 将伪域名 URL 映射到 rawfile 相对路径。
   * 例如 'https://real-time-fund.local/_next/static/xxx.js' → 'web/_next/static/xxx.js'
   * 非本域 URL 返回 null。
   *
   * ArkTS 不支持标准 URL 类，使用手写字符串解析。
   */
  static mapToRawfilePath(fakeDomainUrl: string): string | null {
    if (!fakeDomainUrl || !fakeDomainUrl.includes(FAKE_DOMAIN)) {
      return null;
    }
    // 提取协议://域名 之后的部分作为路径
    const doubleSlashIdx = fakeDomainUrl.indexOf('://');
    if (doubleSlashIdx < 0) {
      return null;
    }
    const afterProtocol = fakeDomainUrl.substring(doubleSlashIdx + 3);
    const slashIdx = afterProtocol.indexOf('/');
    let path: string;
    if (slashIdx < 0) {
      path = 'index.html'; // 无路径 → 默认首页
    } else {
      path = afterProtocol.substring(slashIdx + 1);
      if (path.length === 0) {
        path = 'index.html';
      }
    }
    return RAWFILE_PREFIX + path;
  }

  /**
   * 根据文件扩展名返回 MIME 类型。
   */
  static getMimeType(filePath: string): string {
    const lastDot: number = filePath.lastIndexOf('.');
    if (lastDot < 0) {
      return 'application/octet-stream';
    }
    const ext: string = filePath.substring(lastDot).toLowerCase();
    switch (ext) {
      case '.html':
      case '.htm':
        return 'text/html';
      case '.js':
        return 'application/javascript';
      case '.css':
        return 'text/css';
      case '.json':
        return 'application/json';
      case '.svg':
        return 'image/svg+xml';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.ico':
        return 'image/x-icon';
      case '.woff':
        return 'font/woff';
      case '.woff2':
        return 'font/woff2';
      default:
        return 'application/octet-stream';
    }
  }
}

