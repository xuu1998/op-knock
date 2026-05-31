import { createRequire } from 'node:module'; const require = createRequire(import.meta.url);
import{J as s,ia as n}from"./chunks/chunk-Y5KNKSPS.js";import"./chunks/chunk-37SYSGTE.js";import"./chunks/chunk-6ARAQQSL.js";var r=()=>{console.log(`fn-knock Docker \u7BA1\u7406\u9762\u677F\u5BC6\u7801\u91CD\u7F6E\u5DE5\u5177

\u7528\u6CD5:
  node /opt/fn-knock/server/server-admin/reset-docker-admin-panel.js

\u4F5C\u7528:
  - \u6E05\u9664\u7BA1\u7406\u9762\u677F\u5BC6\u7801
  - \u6E05\u9664\u6240\u6709\u7BA1\u7406\u9762\u677F\u767B\u5F55\u4F1A\u8BDD
  - \u6E05\u9664\u767B\u5F55\u5931\u8D25\u9000\u907F\u72B6\u6001

\u6267\u884C\u5B8C\u6210\u540E\uFF0C\u4E0B\u6B21\u8BBF\u95EE Docker \u7BA1\u7406\u5165\u53E3\u4F1A\u91CD\u65B0\u8FDB\u5165\u201C\u9996\u6B21\u8BBE\u7F6E\u5BC6\u7801\u201D\u6D41\u7A0B\u3002`)},a=async()=>{let e=new Set(process.argv.slice(2));if(e.has("-h")||e.has("--help")){r();return}let o=await n.resetPasswordState();console.log("[fn-knock] Docker \u7BA1\u7406\u9762\u677F\u5BC6\u7801\u72B6\u6001\u5DF2\u6E05\u7406"),console.log(JSON.stringify({passwordCleared:o.password_cleared,sessionsCleared:o.sessions_cleared,loginFailuresCleared:o.login_failures_cleared},null,2)),console.log("[fn-knock] \u4E0B\u6B21\u8BBF\u95EE Docker \u7BA1\u7406\u5165\u53E3\u65F6\uFF0C\u9700\u8981\u91CD\u65B0\u8BBE\u7F6E\u7BA1\u7406\u9762\u677F\u5BC6\u7801")};a().catch(e=>{console.error("[fn-knock] \u6E05\u7406 Docker \u7BA1\u7406\u9762\u677F\u5BC6\u7801\u5931\u8D25:",e instanceof Error?e.message:e),process.exitCode=1}).finally(async()=>{try{await s.quit()}catch{}});
