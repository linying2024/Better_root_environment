function e(e,t,n,o){Object.defineProperty(e,t,{get:n,set:o,enumerable:!0,configurable:!0})}var t=globalThis,n={},o={},i=t.parcelRequiree95e;null==i&&((i=function(e){if(e in n)return n[e].exports;if(e in o){var t=o[e];delete o[e];var i={id:e,exports:{}};return n[e]=i,t.call(i.exports,i,i.exports),i.exports}var d=Error("Cannot find module '"+e+"'");throw d.code="MODULE_NOT_FOUND",d}).register=function(e,t){o[e]=t},t.parcelRequiree95e=i);var d=i.register;d("juEFD",function(e,t){var n=i("8sjuV");console.log("Loader Webui"),(0,n.toast)("WebUI已加载"),(0,n.fullScreen)(!1);let o=document.getElementById("app");if(!o){console.error("未找到#app容器");return}let d="/data/adb/modules/better_app_config";async function a(e,t=!1,o=d,i=!1){let s=i?e:`${d}/lib/busybox_run.sh "${e}"`;try{let{errno:e,stdout:i,stderr:d}=await (0,n.exec)(s,{cwd:o});if(0===e)return t?`\u{6807}\u{51C6}\u{8F93}\u{51FA}\u{6D41}: 
${i}
\u{9519}\u{8BEF}\u{8F93}\u{51FA}\u{6D41}: 
${d}
\u{9000}\u{51FA}\u{4EE3}\u{7801}: ${e}`:i;return t?`\u{9519}\u{8BEF}: 
\u{6807}\u{51C6}\u{8F93}\u{51FA}\u{6D41}: 
${i}
\u{9519}\u{8BEF}\u{8F93}\u{51FA}\u{6D41}: 
${d}
\u{9000}\u{51FA}\u{4EE3}\u{7801}: ${e}`:`\u{9519}\u{8BEF}: 
${d}`}catch(e){return t?`\u{9519}\u{8BEF}: 
\u{6807}\u{51C6}\u{8F93}\u{51FA}\u{6D41}: 
${e.stdout}
\u{9519}\u{8BEF}\u{8F93}\u{51FA}\u{6D41}: 
${e.stderr}
\u{9000}\u{51FA}\u{4EE3}\u{7801}: ${e.errno}`:`\u{9519}\u{8BEF}: 
${e.message}`}}let s=document.createElement("div");s.classList.add("title-container");let l=document.createElement("h5");l.textContent="Module Webui",l.classList.add("allowClick");let u=0;l.addEventListener("click",function(){u++,ksu.toast("被点了一次"),3===u&&(u=0,window.location.href="https://github.com/linying2024/Better_root_environment/tree/main/Better_app_config/0ksu_webroot")});let c=document.createElement("h5");c.textContent="version",c.classList.add("allowClick");let r=0;async function p(e,t=!0,n=d,o=!1){P.textContent="执行中",setTimeout(async()=>{try{let i=await a(e,t,n,o);P.textContent=i,U.scrollTop=U.scrollHeight}catch(e){console.error("执行命令时发生错误:",e),P.textContent="执行命令时发生错误: "+e.message}},100)}function h(e){return"boolean"==typeof e?e:"string"==typeof e&&["1","true","yes","on"].includes(e.trim().toLowerCase())}function m(e,t,n,o,i,d,a){let s=document.createElement("div");s.className="settings-item";let l=document.createElement("span");l.className="settings-label",l.textContent=t;let u=document.createElement("span");u.id=e,u.className="settings-switch",u.style.setProperty("--switch-transition-duration",`${d}s`);let c=h(n),r=!1;return c&&u.classList.add("active"),u.addEventListener("click",()=>{r||(r=!0,c=!c,u.classList.toggle("active"),c?o():i(),setTimeout(()=>{r=!1},a))}),s.appendChild(l),s.appendChild(u),s}c.addEventListener("click",function(){switch(++r){case 1:ksu.toast("?");break;case 2:ksu.toast("你干嘛??");break;case 3:ksu.toast("你到底要做什么???");break;case 4:ksu.toast("不要再点了啊!!!!");break;case 5:ksu.toast("别点了,再点要坏掉了.....");break;case 6:ksu.toast("真的不能再点了,真的会坏掉的啊......");break;case 7:r=0,ksu.toast("不听劝是吧?你完了......."),window.location.href="error.html"}}),s.appendChild(c),s.appendChild(l),o.appendChild(s),async function(){try{let e=await a(`sed -n 's/^version=//p' ${d}/module.prop`),t=await a(`sed -n 's/^versionCode=//p' ${d}/module.prop`);c.textContent=`\u{7248}\u{672C}: ${e} (${t})`}catch(e){console.error("执行命令时发生错误:",e)}}();let C=document.createElement("div");C.classList.add("card");let f=document.createElement("div");f.classList.add("card-header"),f.textContent="控制区";let E=document.createElement("div");E.classList.add("card-body");let b=document.createElement("div"),g=document.createElement("p");async function y(e){h(await a(`sed -n 's/^${e}=//p' "${d}/webroot/webUiConfig.prop"`))&&document.getElementById(e).classList.toggle("active")}g.textContent="功能开关",E.appendChild(g),b.appendChild(m("AutoConfigHMA","自动配置隐藏应用列表",!1,()=>p(`touch "${d}/Hide_My_Applist/disable" && sed -i 's/^AutoConfigHMA=.*/AutoConfigHMA=false/' "${d}/webroot/webUiConfig.prop" && echo "\u{64CD}\u{4F5C}\u{5B8C}\u{6210}"`),()=>p(`rm -f "${d}/Hide_My_Applist/disable" && sed -i 's/^AutoConfigHMA=.*/AutoConfigHMA=true/' "${d}/webroot/webUiConfig.prop" && echo "\u{64CD}\u{4F5C}\u{5B8C}\u{6210}"`),.4,100)),y("AutoConfigHMA"),b.appendChild(m("AutoConfigTrickyStore","自动配置Tricky_Store模块作用域",!1,()=>p(`touch "${d}/Tricky_Store/disable" && sed -i 's/^AutoConfigTrickyStore=.*/AutoConfigTrickyStore=false/' "${d}/webroot/webUiConfig.prop" && echo "\u{64CD}\u{4F5C}\u{5B8C}\u{6210}"`),()=>p(`rm -f "${d}/Tricky_Store/disable" && sed -i 's/^AutoConfigTrickyStore=.*/AutoConfigTrickyStore=true/' "${d}/webroot/webUiConfig.prop" && echo "\u{64CD}\u{4F5C}\u{5B8C}\u{6210}"`),.4,100)),y("AutoConfigTrickyStore"),b.appendChild(m("WhtielistHMA","隐藏应用列表白名单模式",!1,()=>p(`rm -f "${d}/Hide_My_Applist/whtielist.mode" && sed -i 's/^WhtielistHMA=.*/WhtielistHMA=false/' "${d}/webroot/webUiConfig.prop" && echo "\u{64CD}\u{4F5C}\u{5B8C}\u{6210}"`),()=>p(`touch "${d}/Hide_My_Applist/whtielist.mode" && sed -i 's/^WhtielistHMA=.*/WhtielistHMA=true/' "${d}/webroot/webUiConfig.prop" && echo "\u{64CD}\u{4F5C}\u{5B8C}\u{6210}"`),.4,100)),y("WhtielistHMA"),b.appendChild(m("AutoReloadHMA","隐藏应用列表配置自动重载",!1,()=>p(`rm -f "${d}/Hide_My_Applist/reload" && sed -i 's/^AutoReloadHMA=.*/AutoReloadHMA=false/' "${d}/webroot/webUiConfig.prop" && echo "\u{64CD}\u{4F5C}\u{5B8C}\u{6210}"`),()=>p(`touch "${d}/Hide_My_Applist/reload" && sed -i 's/^AutoReloadHMA=.*/AutoReloadHMA=true/' "${d}/webroot/webUiConfig.prop" && echo "\u{64CD}\u{4F5C}\u{5B8C}\u{6210}"`),.4,100)),y("AutoReloadHMA"),E.appendChild(b);let $=document.createElement("p");$.textContent="快捷命令";let w=document.createElement("div");w.classList.add("button-container");let A=["配置 隐藏应用列表 APP","配置 Tricky-Store 模块","更新 boot hash(必须保证模块自带的密钥认证APP已安装)","一键重新配置","安装模块自带的app"].map(e=>{let t=document.createElement("button");return t.textContent=e,w.appendChild(t),t}),k=document.createElement("p");k.classList.add("input-container"),k.textContent="提示:命令较多时可能会卡住或者日志未输出,这是正常现象";let v=document.createElement("div");v.classList.add("input-container");let x=document.createElement("p");x.textContent="自定义shell执行";let L=document.createElement("input");L.type="text",L.placeholder="输入自定义sh命令";let F=document.createElement("button");F.textContent="执行",v.appendChild(L),v.appendChild(F);let _=document.createElement("div");_.classList.add("input-container");let M=document.createElement("p");M.textContent="打开网址";let H=document.createElement("input");H.type="text",H.placeholder="输入您想要打开的网址";let B=document.createElement("button");B.textContent="打开",_.appendChild(H),_.appendChild(B);let D=document.createElement("button");D.textContent="自定义导入隐藏应用列表配置",w.appendChild(D),E.appendChild($),E.appendChild(k),E.appendChild(w),E.appendChild(x),E.appendChild(v),E.appendChild(M),E.appendChild(_),C.appendChild(f),C.appendChild(E);let T=document.createElement("div");T.classList.add("card");let S=document.createElement("div");S.classList.add("card-header"),S.textContent="日志信息";let U=document.createElement("div"),P=document.createElement("pre");P.classList.add("log-body"),P.textContent="还没有命令执行呢";let N=document.createElement("ul");N.appendChild(P),U.appendChild(N),T.appendChild(S),T.appendChild(U),A.forEach((e,t)=>{e.addEventListener("click",()=>{p([`sh ${d}/Hide_My_Applist/get_config.sh`,`sh ${d}/Tricky_Store/get_config.sh`,`rm -f ${d}/gethash.done;sh ${d}/getboothash.sh`,`sh ${d}/action.sh`,`sh ${d}/apks/install.sh`][t])})}),F.addEventListener("click",async()=>{p(L.value)}),B.addEventListener("click",async()=>{(0,n.fullScreen)(!1),ksu.toast("已打开网页"),window.location.href=H.value}),D.addEventListener("click",()=>{let e=document.createElement("div");e.classList.add("hma-body"),e.classList.add("card");let t=document.createElement("button");t.textContent="x",t.classList.add("close-button"),t.addEventListener("click",()=>{document.body.removeChild(e)});let n=document.createElement("div");n.classList.add("card-header"),n.textContent="自定义导入配置",n.appendChild(t),document.createElement("div").classList.add("card-body");let i=document.createElement("div");i.classList.add("button-container");let s=`sed -n 's/^HMAPackageName=//p' "${d}/webroot/webUiConfig.prop"`,l=`sed -n 's/^ProfileName=//p' "${d}/webroot/webUiConfig.prop"`,u=`sed -n 's/^GetExcludeList=//p' "${d}/webroot/webUiConfig.prop"`;function c(e,t,n){let o=document.createElement("div");o.classList.add("input-container");let i=document.createElement("p");i.classList.add("description-up"),i.textContent=e;let a=document.createElement("input");a.id=`${n}Input`,a.type="text",a.placeholder=`\u{5728}\u{8FD9}\u{91CC}\u{8F93}\u{5165}\u{81EA}\u{5B9A}\u{4E49}${t}`;let s=document.createElement("button");return s.textContent="保存",s.addEventListener("click",async()=>{p(`sed -i 's/^${n}=.*/${n}=${a.value}/' "${d}/webroot/webUiConfig.prop" && echo "\u{5DF2}\u{5199}\u{5165}"`)}),o.appendChild(a),o.appendChild(s),o.appendChild(i),o}let r=c("↑输入正确的app包名,默认为 fuck.app.check","app包名","HMAPackageName"),h=c("↑输入正确的隐藏应用列表模板名字,默认为 不可见名单","模板配置名","ProfileName"),m=c("↑输入正确的类型(输入 true 开启,输入 false 关闭),默认为 true","是否开启排除名单生成","GetExcludeList");setTimeout(async()=>{try{let e=await a(s);document.getElementById("HMAPackageNameInput").value=`${e}`;let t=await a(l);document.getElementById("ProfileNameInput").value=`${t}`;let n=await a(u);document.getElementById("GetExcludeListInput").value=`${n}`}catch(e){console.error("执行命令时发生错误:",e)}},100);let C=document.createElement("button");C.textContent="一键导入并生成配置",C.addEventListener("click",()=>{document.body.removeChild(e),p(`"${d}/Hide_My_Applist/0unpack_config.sh" "/data/user/0/$(${s})/files/config.json" "$(${l})" "$(${u})";`)}),e.appendChild(n),e.appendChild(i),e.appendChild(r),e.appendChild(h),e.appendChild(m),e.appendChild(C),document.body.insertBefore(e,o)}),o.appendChild(C),o.appendChild(T);let I=document.createElement("div");I.id="footer",I.textContent="Designed by linying",document.body.appendChild(I)}),d("8sjuV",function(t,n){e(t.exports,"exec",()=>i),e(t.exports,"fullScreen",()=>s),e(t.exports,"toast",()=>l);let o=0;function i(e,t){return void 0===t&&(t={}),new Promise((n,i)=>{let d=`exec_callback_${Date.now()}_${o++}`;function a(e){delete window[e]}window[d]=(e,t,o)=>{n({errno:e,stdout:t,stderr:o}),a(d)};try{ksu.exec(e,JSON.stringify(t),d)}catch(e){i(e),a(d)}})}function d(){this.listeners={}}function a(){this.listeners={},this.stdin=new d,this.stdout=new d,this.stderr=new d}function s(e){ksu.fullScreen(e)}function l(e){ksu.toast(e)}d.prototype.on=function(e,t){this.listeners[e]||(this.listeners[e]=[]),this.listeners[e].push(t)},d.prototype.emit=function(e,...t){this.listeners[e]&&this.listeners[e].forEach(e=>e(...t))},a.prototype.on=function(e,t){this.listeners[e]||(this.listeners[e]=[]),this.listeners[e].push(t)},a.prototype.emit=function(e,...t){this.listeners[e]&&this.listeners[e].forEach(e=>e(...t))}}),i("juEFD");
//# sourceMappingURL=index.1c21e801.js.map