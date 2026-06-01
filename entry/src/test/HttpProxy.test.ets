import { describe, it, expect } from '@ohos/hypium';
import { HttpProxy } from '../main/ets/proxy/HttpProxy';

export default function httpProxyTest() {
  describe('HttpProxy', () => {
    describe('isJsonpDataSource', () => {
      it('should return true for 天天基金 fundgz domain', 0, () => {
        const result = HttpProxy.isJsonpDataSource(
          'https://fundgz.1234567.com.cn/js/110022.js?callback=jsonpCallback'
        );
        expect(result).assertTrue();
      });

      it('should return true for 东方财富 eastmoney domain', 0, () => {
        const result = HttpProxy.isJsonpDataSource(
          'https://fund.eastmoney.com/api/FundNetValue/Get'
        );
        expect(result).assertTrue();
      });

      it('should return true for 腾讯财经 gtimg domain', 0, () => {
        const result = HttpProxy.isJsonpDataSource(
          'https://qt.gtimg.cn/q=sh600519'
        );
        expect(result).assertTrue();
      });

      it('should return false for local fake domain', 0, () => {
        const result = HttpProxy.isJsonpDataSource(
          'https://real-time-fund.local/index.html'
        );
        expect(result).assertFalse();
      });

      it('should return false for empty string', 0, () => {
        const result = HttpProxy.isJsonpDataSource('');
        expect(result).assertFalse();
      });

      it('should return false for random external URL', 0, () => {
        const result = HttpProxy.isJsonpDataSource('https://www.example.com/');
        expect(result).assertFalse();
      });
    describe('mapToRawfilePath', () => {
      it('should map root path to index.html', 0, () => {
        const result = HttpProxy.mapToRawfilePath('https://real-time-fund.local/');
        expect(result).assertEqual('web/index.html');
      });

      it('should map absolute static asset path', 0, () => {
        const result = HttpProxy.mapToRawfilePath(
          'https://real-time-fund.local/_next/static/chunks/main-abc123.js'
        );
        expect(result).assertEqual('web/_next/static/chunks/main-abc123.js');
      });

      it('should map deeply nested path', 0, () => {
        const result = HttpProxy.mapToRawfilePath(
          'https://real-time-fund.local/sub/dir/file.html'
        );
        expect(result).assertEqual('web/sub/dir/file.html');
      });

      it('should return null for non-matching domain', 0, () => {
        const result = HttpProxy.mapToRawfilePath('https://other.com/index.html');
        expect(result).assertNull();
      });
    describe('getMimeType', () => {
      it('should return text/html for .html', 0, () => {
        expect(HttpProxy.getMimeType('index.html')).assertEqual('text/html');
      });

      it('should return application/javascript for .js', 0, () => {
        expect(HttpProxy.getMimeType('main.js')).assertEqual('application/javascript');
      });

      it('should return text/css for .css', 0, () => {
        expect(HttpProxy.getMimeType('style.css')).assertEqual('text/css');
      });

      it('should return application/json for .json', 0, () => {
        expect(HttpProxy.getMimeType('data.json')).assertEqual('application/json');
      });

      it('should return image/svg+xml for .svg', 0, () => {
        expect(HttpProxy.getMimeType('icon.svg')).assertEqual('image/svg+xml');
      });

      it('should return application/octet-stream for unknown extension', 0, () => {
        expect(HttpProxy.getMimeType('file.xyz')).assertEqual('application/octet-stream');
      });
    });
  });
}
