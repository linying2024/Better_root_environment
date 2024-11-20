// 导入kernelsu的webui库
import { fullScreen, exec, toast } from 'kernelsu';

// 浏览器打印一个日志
console.log("Loader Webui");
// 让app在android设备屏幕上弹出一个toast
toast('WebUI已加载');
// 让webui关闭网页全屏模式
fullScreen(false);

// 获取#app容器
const appContainer = document.getElementById('app');
// 确保appContainer已找到，否则后续操作会导致错误
if (!appContainer) {
  console.error('未找到#app容器');
  // 退出执行
  return;
}

// 设置默认的shell工作路径
const MODDIR = "/data/adb/modules/better_app_config";

// 封装异步函数，用于执行命令并返回输出
// 接收三个参数, 传入的shell命令,如果不传入工作目录则使用默认值 MODDIR,以及一个布尔值 noBusybox
// 如果 noBusybox 为 true，则直接执行传入的 command 否则，使用 busybox 来执行 command
async function executeCommand(command, cwd = MODDIR, noBusybox = false) {
  let cmdToExecute = noBusybox ? command : `${MODDIR}/lib/busybox_run.sh \"${command}\"`;
  try {
    // 执行命令并获取输出
    const { errno, stdout, stderr } = await exec(cmdToExecute, { cwd });
    // 判断是否成功执行
    if (errno === 0) {
      // 成功时返回标准输出
      return stdout;
    } else {
      // 失败时抛出错误，包含标准错误输出
      throw new Error(`命令执行失败: \n${stderr}`);
    }
  } catch (error) {
    // 捕获执行过程中的任何错误，并返回错误信息
    return `错误: \n${error.message}`;
  }
}

// 创建标题容器
const titleContainer = document.createElement('div');
titleContainer.classList.add('title-container');
// 创建标题元素
const title = document.createElement('h5');
title.textContent = 'Module Webui';
// 嵌入css样式，允许被点击
title.classList.add('allowClick');
// 初始化变量
let title_clickCount = 0;
title.addEventListener('click', function() {
  title_clickCount++;
  ksu.toast('被点了一次');
  if (title_clickCount === 3) {
    title_clickCount = 0;
    window.location.href = "https://github.com/linying2024/Better_root_environment/tree/main/Better_app_config/0ksu_webroot";
  };
});
// 创建版本标题元素
const versiontitle = document.createElement('h5');
versiontitle.textContent = 'version';
// 嵌入css样式，允许被点击
versiontitle.classList.add('allowClick');
// 初始化变量
let versiontitle_clickCount = 0;
versiontitle.addEventListener('click', function() {
  versiontitle_clickCount++;
  if (versiontitle_clickCount === 1) {
    ksu.toast('?');
  };
  if (versiontitle_clickCount === 2) {
    ksu.toast('你干嘛??');
  };
  if (versiontitle_clickCount === 3) {
    ksu.toast('你到底要做什么???');
  };
  if (versiontitle_clickCount === 4) {
    ksu.toast('不要再点了啊!!!!');
  };
  if (versiontitle_clickCount === 5) {
    ksu.toast('别点了,再点要坏掉了.....');
  };
  if (versiontitle_clickCount === 6) {
    ksu.toast('真的不能再点了,真的会坏掉的啊......');
  };
  if (versiontitle_clickCount === 7) {
    versiontitle_clickCount = 0;
    ksu.toast('不听劝是吧?你完了.......');
    window.location.href = "error.html";
  };
});
// 将版本号和标题添加到容器中，确保标题从右边开始
titleContainer.appendChild(versiontitle);
titleContainer.appendChild(title);
// 将标题容器追加到#app容器中
appContainer.appendChild(titleContainer);

// 立即执行异步函数来获取模块版本号并设置标题
(async function getVersions() {
  try {
    let version = await executeCommand(`sed -n \'s/^version=//p\' ${MODDIR}/module.prop`);
    let versionCode = await executeCommand(`sed -n \'s/^versionCode=//p\' ${MODDIR}/module.prop`);
    // 设置版本标题元素的文本内容
    versiontitle.textContent = `版本: ${version} (${versionCode})`;
  } catch (error) {
    console.error('执行命令时发生错误:', error);
  }
})();

// 定义一个异步函数，用于将shell执行结果输出到日志区
// 接收传入的命令,如果不传入工作目录则使用默认值 MODDIR
async function PrintExecuteCommandLogToUi(command, cwd = MODDIR, noBusybox = false) {
  // 先给个提醒，防止多次点击
  logEntry.textContent = '执行中';
  // 设置延迟,让ui有机会更新出来
  setTimeout(async () => {
    // 尝试执行
    try {
      // 调用封装好的异步函数执行命令
      const result = await executeCommand(command, cwd, noBusybox);
      // 将命令执行的结果直接设置到 <pre> 元素中
      logEntry.textContent = result;
      // 滚动日志区域到最新内容（如果日志区域有滚动条的话）
      logBody.scrollTop = logBody.scrollHeight;
    } catch (error) {
      console.error('执行命令时发生错误:', error);
      // 将错误信息设置到 <pre> 元素中
      logEntry.textContent = '执行命令时发生错误: ' + error.message;
    }
  }, 100);
}

// 创建命令行控制卡片
const serverStatusCard = document.createElement('div');
serverStatusCard.classList.add('card');
const serverStatusHeader = document.createElement('div');
serverStatusHeader.classList.add('card-header');
serverStatusHeader.textContent = '控制区';
const serverStatusBody = document.createElement('div');
serverStatusBody.classList.add('card-body');

// 创建按钮容器并应用样式
const buttonsContainer = document.createElement('div');
buttonsContainer.classList.add('button-container');
// 创建按钮并添加到buttonsContainer
const buttons = ['配置 Tricky-Store 模块', '更新 boot hash(必须保证模块自带的密钥认证APP已安装)', '一键重新配置', '安装模块自带的app'].map(text => {
  const button = document.createElement('button');
  button.textContent = text;
  buttonsContainer.appendChild(button);
  return button;
});
// 将按钮容器添加到serverStatusBody
serverStatusBody.appendChild(buttonsContainer);

// 创建执行按钮
const hmaButton = document.createElement('button');
hmaButton.textContent = '打开隐藏应用列表菜单';

// 添加提示
const buttonDescription = document.createElement('p');
buttonDescription.classList.add('input-container');
buttonDescription.textContent = '提示:命令较多时可能会卡住或者日志未输出,这是正常现象';

// 添加输入框和执行按钮的容器
const inputContainer = document.createElement('div');
inputContainer.classList.add('input-container');
const inputDescription = document.createElement('p');
inputDescription.textContent = '自定义shell执行';
// 创建输入框
const inputBox = document.createElement('input');
inputBox.type = 'text';
inputBox.placeholder = '输入自定义sh命令';
// 创建执行按钮
const CustomExecuteButton = document.createElement('button');
CustomExecuteButton.textContent = '执行';
// 将所有元素添加到inputContainer中
inputContainer.appendChild(inputBox);
inputContainer.appendChild(CustomExecuteButton);

// 添加输入框和按钮的容器
const inputContainer2 = document.createElement('div');
inputContainer2.classList.add('input-container');
const inputDescription2 = document.createElement('p');
inputDescription2.textContent = '←打开网址';
// 创建输入框
const inputBox2 = document.createElement('input');
inputBox2.type = 'text';
inputBox2.placeholder = '输入您想要打开的网址';
// 创建按钮
const CustomExecuteButton2 = document.createElement('button');
CustomExecuteButton2.textContent = '打开';
// 将所有元素添加到inputContainer2中
inputContainer2.appendChild(inputBox2);
inputContainer2.appendChild(CustomExecuteButton2);

// 将所有元素添加到卡片中
serverStatusBody.appendChild(hmaButton);
serverStatusBody.appendChild(buttonDescription); // 添加描述
serverStatusBody.appendChild(document.createElement('br')); // 添加换行
serverStatusBody.appendChild(inputDescription); // 添加描述
serverStatusBody.appendChild(inputContainer); // 添加输入框和执行按钮的容器
serverStatusBody.appendChild(document.createElement('br')); // 添加换行
serverStatusBody.appendChild(inputContainer2); 
serverStatusBody.appendChild(inputDescription2); // 添加换行
serverStatusCard.appendChild(serverStatusHeader);
serverStatusCard.appendChild(serverStatusBody);

// 创建日志信息卡片（类似地）
const logCard = document.createElement('div');
logCard.classList.add('card');

const logHeader = document.createElement('div');
logHeader.classList.add('card-header');
logHeader.textContent = '日志信息';

const logBody = document.createElement('div');

// 创建日志信息的列表项
const logEntry = document.createElement('pre');
logEntry.classList.add('log-body');
logEntry.textContent = '还没有命令执行呢';

// 创建一个ul元素并将列表项添加到其中
const logList = document.createElement('ul');
logList.appendChild(logEntry);

// 将所有元素添加到日志卡片中
logBody.appendChild(logList);
logCard.appendChild(logHeader);
logCard.appendChild(logBody);

// 为按钮添加点击事件监听器
buttons.forEach((button, index) => {
  button.addEventListener('click', () => {
    // 定义要执行的命令和目录(尽量使用完整路径以减少错误)
    const commands = [
      `sh ${MODDIR}/Tricky_Store/get_config.sh`,
      `rm -f gethash.done;sh ${MODDIR}/getboothash.sh`,
      `sh ${MODDIR}/action.sh`,
      `sh ${MODDIR}/apks/install.sh`
    ];
    // 调用封装好的异步函数执行命令
    PrintExecuteCommandLogToUi(commands[index]);
  });
});

CustomExecuteButton.addEventListener('click', async () => {
  // 调用封装好的异步函数执行命令
  PrintExecuteCommandLogToUi(inputBox.value);
});
CustomExecuteButton2.addEventListener('click', async () => {
  // 让webui网页调整全屏模式
  fullScreen(false);
  ksu.toast('已打开网页');
  window.location.href = inputBox2.value;
});

// 为菜单项添加点击事件监听器
hmaButton.addEventListener('click', () => {
  // 创建一个新的div，用于包含新的菜单项
  const HMANewMenuContainer = document.createElement('div');
  HMANewMenuContainer.classList.add('hma-body'); // 添加class
  HMANewMenuContainer.classList.add('card');
  
  // 创建关闭按钮并添加点击事件监听器
  const HMACloseButton = document.createElement('button');
  HMACloseButton.textContent = 'x';
  HMACloseButton.classList.add('close-button');
  HMACloseButton.addEventListener('click', () => {
    // 当关闭按钮被点击时，删除整个菜单
    document.body.removeChild(HMANewMenuContainer);
  });
  
  // 创建菜单头部并添加关闭按钮
  const HMAMenuHeader = document.createElement('div');
  HMAMenuHeader.classList.add('card-header');
  HMAMenuHeader.textContent = '设置隐藏应用列表';
  HMAMenuHeader.appendChild(HMACloseButton); // 将关闭按钮添加到头部
  
  const HMAMenuBody = document.createElement('div');
  HMAMenuBody.classList.add('card-body');
  
  // 创建按钮容器并应用样式
  const HMAButtonsContainer = document.createElement('div');
  HMAButtonsContainer.classList.add('button-container');
  
  // 创建按钮并添加到HMAButtonsContainer
  const HMAButtons = ['配置 隐藏应用列表 APP', '隐藏应用列表切换黑名单模式', '隐藏应用列表切换白名单模式', '关闭隐藏应用列表自动重载', '开启隐藏应用列表自动重载'].map(text => {
    const button = document.createElement('button');
    button.textContent = text;
    HMAButtonsContainer.appendChild(button);
    return button;
  });
  
  // 为按钮添加点击事件监听器
  HMAButtons.forEach((button, index) => {
    button.addEventListener('click', () => {
      // 当按钮被点击时，删除整个菜单
      document.body.removeChild(HMANewMenuContainer);
      const commands = [
        `sh ${MODDIR}/Hide_My_Applist/get_config.sh`,
        `rm -f ${MODDIR}/Hide_My_Applist/whitelist.mode;sh ${MODDIR}/Hide_My_Applist/get_config.sh`,
        `touch ${MODDIR}/Hide_My_Applist/whitelist.mode;sh ${MODDIR}/Hide_My_Applist/get_config.sh`,
        `rm -f ${MODDIR}/Hide_My_Applist/reload`,
        `touch ${MODDIR}/Hide_My_Applist/reload`,
        ];
      // 调用封装好的异步函数执行命令
      PrintExecuteCommandLogToUi(commands[index]);
    });
  });

  // 获取信息
  const HMAPackageName = `sed -n 's/^HMAPackageName=//p' "${MODDIR}/webroot/webUiConfig.prop"`;
  const ProfileName = `sed -n 's/^ProfileName=//p' "${MODDIR}/webroot/webUiConfig.prop"`;
  const GetExcludeList = `sed -n 's/^GetExcludeList=//p' "${MODDIR}/webroot/webUiConfig.prop"`;
  
  const HMAInputDescription = document.createElement('p');
  HMAInputDescription.classList.add('description-up');
  HMAInputDescription.textContent = '自定义导入配置';

  // 定义一个函数来创建输入框和执行按钮容器
  function createInputContainer(descriptionText, inputDescriptionText, configKey) {
    const container = document.createElement('div');
    container.classList.add('input-container');

    const description = document.createElement('p');
    description.classList.add('description-up');
    description.textContent = descriptionText;

    const inputBox = document.createElement('input');
    inputBox.id = `${configKey}Input`
    inputBox.type = 'text';
    inputBox.placeholder = `在这里输入自定义${inputDescriptionText}`;

    const executeButton = document.createElement('button');
    executeButton.textContent = '保存';

    executeButton.addEventListener('click', async () => {
      const command = `sed -i 's/^${configKey}=.*/${configKey}=${inputBox.value}/' "${MODDIR}/webroot/webUiConfig.prop" && echo "已写入"`;
      PrintExecuteCommandLogToUi(command);
    });

    container.appendChild(inputBox);
    container.appendChild(executeButton);
    container.appendChild(description);
    return container;
  }

  // 添加输入框和执行按钮的容器
  const HMAInputContainer1 = createInputContainer('↑输入正确的app包名,默认为 fuck.app.check', 'app包名', 'HMAPackageName');
  const HMAInputContainer2 = createInputContainer('↑输入正确的隐藏应用列表模板名字,默认为 不可见名单', '模板配置名', 'ProfileName');
  const HMAInputContainer3 = createInputContainer('↑输入正确的类型(输入 true 开启,输入 false 关闭),默认为 true', '是否开启排除名单生成', 'GetExcludeList');

  // 定义一个异步函数
  setTimeout(async () => {
    try {
      // 获取内容
      const HMAPackageName = await executeCommand('sed -n \'s/^HMAPackageName=//p\' ' + MODDIR + '/webroot/webUiConfig.prop', MODDIR);
      // 设置元素的文本内容
      document.getElementById('HMAPackageNameInput').value = `${HMAPackageName}`;

      // 获取内容
      const ProfileName = await executeCommand('sed -n \'s/^ProfileName=//p\' ' + MODDIR + '/webroot/webUiConfig.prop', MODDIR);
      // 设置元素的文本内容
      document.getElementById('ProfileNameInput').value = `${ProfileName}`;

      // 获取内容
      const GetExcludeList = await executeCommand('sed -n \'s/^GetExcludeList=//p\' ' + MODDIR + '/webroot/webUiConfig.prop', MODDIR);
      // 设置元素的文本内容
      document.getElementById('GetExcludeListInput').value = `${GetExcludeList}`;

    } catch (error) {
      console.error('执行命令时发生错误:', error);
    }
  }, 100); // 延迟毫秒
  // 创建导入按钮
  const inputConfig = document.createElement('button');
  inputConfig.textContent = '一键导入并生成配置';
  inputConfig.addEventListener('click', () => {
    // 当按钮被点击时，删除整个菜单
    document.body.removeChild(HMANewMenuContainer);
    // 定义要执行的命令和目录
    const command = `"${MODDIR}/Hide_My_Applist/0unpack_config.sh" "/data/user/0/$(${HMAPackageName})/files/config.json" "$(${ProfileName})" "$(${GetExcludeList})";`;
    // 调用封装好的异步函数执行命令
    PrintExecuteCommandLogToUi(command);
  });

  HMANewMenuContainer.appendChild(HMAMenuHeader); // 添加头部到菜单容器
  HMANewMenuContainer.appendChild(HMAButtonsContainer); // 添加按钮容器到菜单容器
  HMANewMenuContainer.appendChild(HMAInputDescription);
  HMANewMenuContainer.appendChild(HMAInputContainer1); // 添加HMAInputContainer1到菜单容器
  HMANewMenuContainer.appendChild(HMAInputContainer2); // 添加HMAInputContainer2到菜单容器
  HMANewMenuContainer.appendChild(HMAInputContainer3); // 添加HMAInputContainer3到菜单容器
  HMANewMenuContainer.appendChild(inputConfig);

  // 将菜单项添加到页面中
  document.body.insertBefore(HMANewMenuContainer, appContainer);
});

// 最后，将卡片和标题添加到#app容器中
appContainer.appendChild(serverStatusCard);
appContainer.appendChild(logCard);

// 创建一个新的 div 元素用于制作者提醒
const footer = document.createElement('div');
footer.id = 'footer';
// 设置制作者提醒的内容
footer.textContent = 'Designed by linying';
// 将制作者提醒添加到页面的 body 中
document.body.appendChild(footer);