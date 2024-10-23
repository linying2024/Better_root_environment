// 导入kernelsu的webui库
import { fullScreen, exec, toast } from 'kernelsu';

// 浏览器打印一个日志
console.log("Loader Webui");
// 让app在android设备屏幕上弹出一个toast
toast('WebUI已加载');
// 让webui关闭网页全屏模式
fullScreen(false);

// 封装异步函数，用于执行命令并返回输出
async function executeCommand(command, cwd) {
  try {
    // 执行命令并获取输出
    const { errno, stdout, stderr } = await exec(command, { cwd });
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

// 获取#app容器
const appContainer = document.getElementById('app');

// 确保appContainer已找到，否则后续操作会导致错误
if (!appContainer) {
  console.error('未找到#app容器');
  return;
}

// 创建标题元素
const title = document.createElement('h5');
title.textContent = 'Module Webui';

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
const buttons = ['一键重新配置', '配置 隐藏应用列表 APP', '隐藏应用列表切换白名单模式', '隐藏应用列表切换黑名单模式', '关闭隐藏应用列表自动重载', '开启隐藏应用列表自动重载', '配置 Tricky-Store 模块', '更新 boot hash(必须保证模块自带的密钥认证APP已安装)', '安装模块自带的app'].map(text => {
  const button = document.createElement('button');
  button.textContent = text;
  buttonsContainer.appendChild(button);
  return button;
});

// 将按钮容器添加到serverStatusBody
serverStatusBody.appendChild(buttonsContainer);

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
inputBox.placeholder = '在这里可以输入自定义sh命令';

// 创建执行按钮
const CustonExecuteButton = document.createElement('button');
CustonExecuteButton.textContent = '执行';

// 将所有元素添加到inputContainer中
inputContainer.appendChild(inputBox);
inputContainer.appendChild(CustonExecuteButton);

// 将所有元素添加到卡片中
serverStatusBody.appendChild(buttonDescription); // 添加描述
serverStatusBody.appendChild(document.createElement('br')); // 添加换行
serverStatusBody.appendChild(inputDescription); // 添加描述
serverStatusBody.appendChild(inputContainer); // 添加输入框和执行按钮的容器
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

// 设置默认的工作路径
const MODDIR = "/data/adb/modules/better_app_config";

// 为按钮添加点击事件监听器
buttons.forEach((button, index) => {
  button.addEventListener('click', () => {
    // 先给个提醒,防止多次点击
    logEntry.textContent = '执行中';

    // 使用 setTimeout 来确保 UI 有机会更新
    setTimeout(async () => {
      // 定义要执行的命令和目录(尽量使用完整路径减少错误)
      const commands = [
        'sh ' + MODDIR + '/action.sh',
        'sh ' + MODDIR + '/Hide_My_Applist/get_config.sh',
        'rm -f ' + MODDIR + '/Hide_My_Applist/whitelist.mode;sh ' + MODDIR + '/Hide_My_Applist/get_config.sh',
        'touch ' + MODDIR + '/Hide_My_Applist/whitelist.mode;sh ' + MODDIR + '/Hide_My_Applist/get_config.sh',
        'rm -f ' + MODDIR + '/Hide_My_Applist/reload',
        'touch ' + MODDIR + '/Hide_My_Applist/reload',
        'sh ' + MODDIR + '/Tricky_Store/get_config.sh',
        'rm -f gethash.done;sh ' + MODDIR + '/getboothash.sh',
        'sh ' + MODDIR + '/apks/install.sh'
      ];
      const cwd = MODDIR;
      
      // 调用封装好的异步函数执行命令
      try {
        const result = await executeCommand(commands[index], cwd);
        
        // 将命令执行的结果直接设置到 <pre> 元素中
        logEntry.textContent = result;
        
        // 滚动日志区域到最新内容（如果日志区域有滚动条的话）
        logBody.scrollTop = logBody.scrollHeight;
      } catch (error) {
        console.error('执行命令时发生错误:', error);
        // 可以选择将错误信息设置到 <pre> 元素中
        logEntry.textContent = '执行命令时发生错误: ' + error.message;
      }
    }, 100); // 延迟毫秒，即尽可能快地执行，但仍然允许UI更新
  });
});

CustonExecuteButton.addEventListener('click', async () => {
  // 定义要执行的命令和目录
  const command = inputBox.value;
  const cwd = MODDIR;
  
  // 调用封装好的异步函数执行命令
  const result = await executeCommand(command, cwd);
  
  // 将命令执行的结果直接设置到 <pre> 元素中
  logEntry.textContent = result;
  
  // 滚动日志区域到最新内容（如果日志区域有滚动条的话）
  logBody.scrollTop = logBody.scrollHeight;
});

// 最后，将卡片和标题添加到#app容器中
appContainer.appendChild(title);
appContainer.appendChild(serverStatusCard);
appContainer.appendChild(logCard);