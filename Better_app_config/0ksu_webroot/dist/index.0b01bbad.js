function e(e,t,n,d){Object.defineProperty(e,t,{get:n,set:d,enumerable:!0,configurable:!0})}var t=globalThis,n={},d={},o=t.parcelRequiree95e;null==o&&((o=function(e){if(e in n)return n[e].exports;if(e in d){var t=d[e];delete d[e];var o={id:e,exports:{}};return n[e]=o,t.call(o.exports,o,o.exports),o.exports}var i=Error("Cannot find module '"+e+"'");throw i.code="MODULE_NOT_FOUND",i}).register=function(e,t){d[e]=t},t.parcelRequiree95e=o);var i=o.register;i("7qALL",function(e,t){var n=o("5tSLu");console.log("Loader Webui"),(0,n.toast)("WebUI已加载"),(0,n.fullScreen)(!1);let d=document.getElementById("app");if(!d){console.error("未找到#app容器");return}let i="/data/adb/modules/better_app_config";async function l(e,t=i,d=!1){let o=d?e:`${i}/lib/busybox_run.sh "${e}"`;try{let{errno:e,stdout:d,stderr:i}=await (0,n.exec)(o,{cwd:t});if(0===e)return d;throw Error(`\u{547D}\u{4EE4}\u{6267}\u{884C}\u{5931}\u{8D25}: 
${i}`)}catch(e){return`\u{9519}\u{8BEF}: 
${e.message}`}}let a=document.createElement("div");a.classList.add("title-container");let s=document.createElement("h5");s.textContent="Module Webui",s.classList.add("allowClick");let c=0;s.addEventListener("click",function(){c++,ksu.toast("被点了一次"),3===c&&(c=0,window.location.href="https://github.com/linying2024/Better_root_environment/tree/main/Better_app_config/0ksu_webroot")});let r=document.createElement("h5");r.textContent="version",r.classList.add("allowClick");let p=0;async function u(e,t=i,n=!1){H.textContent="执行中",setTimeout(async()=>{try{let d=await l(e,t,n);H.textContent=d,P.scrollTop=P.scrollHeight}catch(e){console.error("执行命令时发生错误:",e),H.textContent="执行命令时发生错误: "+e.message}},100)}r.addEventListener("click",function(){1==++p&&ksu.toast("?"),2===p&&ksu.toast("你干嘛??"),3===p&&ksu.toast("你到底要做什么???"),4===p&&ksu.toast("不要再点了啊!!!!"),5===p&&ksu.toast("别点了,再点要坏掉了....."),6===p&&ksu.toast("真的不能再点了,真的会坏掉的啊......"),7===p&&(p=0,ksu.toast("不听劝是吧?你完了......."),window.location.href="error.html")}),a.appendChild(r),a.appendChild(s),d.appendChild(a),async function(){try{let e=await l(`sed -n 's/^version=//p' ${i}/module.prop`),t=await l(`sed -n 's/^versionCode=//p' ${i}/module.prop`);r.textContent=`\u{7248}\u{672C}: ${e} (${t})`}catch(e){console.error("执行命令时发生错误:",e)}}();let m=document.createElement("div");m.classList.add("card");let h=document.createElement("div");h.classList.add("card-header"),h.textContent="控制区";let C=document.createElement("div");C.classList.add("card-body");let E=document.createElement("div");E.classList.add("button-container");let f=["配置 Tricky-Store 模块","更新 boot hash(必须保证模块自带的密钥认证APP已安装)","一键重新配置","安装模块自带的app"].map(e=>{let t=document.createElement("button");return t.textContent=e,E.appendChild(t),t});C.appendChild(E);let b=document.createElement("button");b.textContent="打开隐藏应用列表菜单";let y=document.createElement("p");y.classList.add("input-container"),y.textContent="提示:命令较多时可能会卡住或者日志未输出,这是正常现象";let v=document.createElement("div");v.classList.add("input-container");let x=document.createElement("p");x.textContent="自定义shell执行";let g=document.createElement("input");g.type="text",g.placeholder="输入自定义sh命令";let w=document.createElement("button");w.textContent="执行",v.appendChild(g),v.appendChild(w);let L=document.createElement("div");L.classList.add("input-container");let $=document.createElement("p");$.textContent="←打开网址";let k=document.createElement("input");k.type="text",k.placeholder="输入您想要打开的网址";let _=document.createElement("button");_.textContent="打开",L.appendChild(k),L.appendChild(_),C.appendChild(b),C.appendChild(y),C.appendChild(document.createElement("br")),C.appendChild(x),C.appendChild(v),C.appendChild(document.createElement("br")),C.appendChild(L),C.appendChild($),m.appendChild(h),m.appendChild(C);let A=document.createElement("div");A.classList.add("card");let M=document.createElement("div");M.classList.add("card-header"),M.textContent="日志信息";let P=document.createElement("div"),H=document.createElement("pre");H.classList.add("log-body"),H.textContent="还没有命令执行呢";let N=document.createElement("ul");N.appendChild(H),P.appendChild(N),A.appendChild(M),A.appendChild(P),f.forEach((e,t)=>{e.addEventListener("click",()=>{u([`sh ${i}/Tricky_Store/get_config.sh`,`rm -f gethash.done;sh ${i}/getboothash.sh`,`sh ${i}/action.sh`,`sh ${i}/apks/install.sh`][t])})}),w.addEventListener("click",async()=>{u(g.value)}),_.addEventListener("click",async()=>{(0,n.fullScreen)(!1),ksu.toast("已打开网页"),window.location.href=k.value}),b.addEventListener("click",()=>{let e=document.createElement("div");e.classList.add("hma-body"),e.classList.add("card");let t=document.createElement("button");t.textContent="x",t.classList.add("close-button"),t.addEventListener("click",()=>{document.body.removeChild(e)});let n=document.createElement("div");n.classList.add("card-header"),n.textContent="设置隐藏应用列表",n.appendChild(t),document.createElement("div").classList.add("card-body");let o=document.createElement("div");o.classList.add("button-container"),["配置 隐藏应用列表 APP","隐藏应用列表切换黑名单模式","隐藏应用列表切换白名单模式","关闭隐藏应用列表自动重载","开启隐藏应用列表自动重载"].map(e=>{let t=document.createElement("button");return t.textContent=e,o.appendChild(t),t}).forEach((t,n)=>{t.addEventListener("click",()=>{document.body.removeChild(e),u([`sh ${i}/Hide_My_Applist/get_config.sh`,`rm -f ${i}/Hide_My_Applist/whitelist.mode;sh ${i}/Hide_My_Applist/get_config.sh`,`touch ${i}/Hide_My_Applist/whitelist.mode;sh ${i}/Hide_My_Applist/get_config.sh`,`rm -f ${i}/Hide_My_Applist/reload`,`touch ${i}/Hide_My_Applist/reload`][n])})});let a=`sed -n 's/^HMAPackageName=//p' "${i}/webroot/webUiConfig.prop"`,s=`sed -n 's/^ProfileName=//p' "${i}/webroot/webUiConfig.prop"`,c=`sed -n 's/^GetExcludeList=//p' "${i}/webroot/webUiConfig.prop"`,r=document.createElement("p");function p(e,t,n){let d=document.createElement("div");d.classList.add("input-container");let o=document.createElement("p");o.classList.add("description-up"),o.textContent=e;let l=document.createElement("input");l.id=`${n}Input`,l.type="text",l.placeholder=`\u{5728}\u{8FD9}\u{91CC}\u{8F93}\u{5165}\u{81EA}\u{5B9A}\u{4E49}${t}`;let a=document.createElement("button");return a.textContent="保存",a.addEventListener("click",async()=>{u(`sed -i 's/^${n}=.*/${n}=${l.value}/' "${i}/webroot/webUiConfig.prop" && echo "\u{5DF2}\u{5199}\u{5165}"`)}),d.appendChild(l),d.appendChild(a),d.appendChild(o),d}r.classList.add("description-up"),r.textContent="自定义导入配置";let m=p("↑输入正确的app包名,默认为 fuck.app.check","app包名","HMAPackageName"),h=p("↑输入正确的隐藏应用列表模板名字,默认为 不可见名单","模板配置名","ProfileName"),C=p("↑输入正确的类型(输入 true 开启,输入 false 关闭),默认为 true","是否开启排除名单生成","GetExcludeList");setTimeout(async()=>{try{let e=await l("sed -n 's/^HMAPackageName=//p' "+i+"/webroot/webUiConfig.prop",i);document.getElementById("HMAPackageNameInput").value=`${e}`;let t=await l("sed -n 's/^ProfileName=//p' "+i+"/webroot/webUiConfig.prop",i);document.getElementById("ProfileNameInput").value=`${t}`;let n=await l("sed -n 's/^GetExcludeList=//p' "+i+"/webroot/webUiConfig.prop",i);document.getElementById("GetExcludeListInput").value=`${n}`}catch(e){console.error("执行命令时发生错误:",e)}},100);let E=document.createElement("button");E.textContent="一键导入并生成配置",E.addEventListener("click",()=>{document.body.removeChild(e),u(`"${i}/Hide_My_Applist/0unpack_config.sh" "/data/user/0/$(${a})/files/config.json" "$(${s})" "$(${c})";`)}),e.appendChild(n),e.appendChild(o),e.appendChild(r),e.appendChild(m),e.appendChild(h),e.appendChild(C),e.appendChild(E),document.body.insertBefore(e,d)}),d.appendChild(m),d.appendChild(A);let U=document.createElement("div");U.id="footer",U.textContent="Designed by linying",document.body.appendChild(U)}),i("5tSLu",function(t,n){e(t.exports,"exec",()=>o),e(t.exports,"fullScreen",()=>a),e(t.exports,"toast",()=>s);let d=0;function o(e,t){return void 0===t&&(t={}),new Promise((n,o)=>{let i=`exec_callback_${Date.now()}_${d++}`;function l(e){delete window[e]}window[i]=(e,t,d)=>{n({errno:e,stdout:t,stderr:d}),l(i)};try{ksu.exec(e,JSON.stringify(t),i)}catch(e){o(e),l(i)}})}function i(){this.listeners={}}function l(){this.listeners={},this.stdin=new i,this.stdout=new i,this.stderr=new i}function a(e){ksu.fullScreen(e)}function s(e){ksu.toast(e)}i.prototype.on=function(e,t){this.listeners[e]||(this.listeners[e]=[]),this.listeners[e].push(t)},i.prototype.emit=function(e,...t){this.listeners[e]&&this.listeners[e].forEach(e=>e(...t))},l.prototype.on=function(e,t){this.listeners[e]||(this.listeners[e]=[]),this.listeners[e].push(t)},l.prototype.emit=function(e,...t){this.listeners[e]&&this.listeners[e].forEach(e=>e(...t))}}),o("7qALL");
//# sourceMappingURL=index.0b01bbad.js.map