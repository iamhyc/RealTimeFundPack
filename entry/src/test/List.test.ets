import localUnitTest from './LocalUnit.test';
import httpProxyTest from './HttpProxy.test';

export default function testsuite() {
  localUnitTest();
  httpProxyTest();
}