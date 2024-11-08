# 构建方法

### 1.安装node js然后安装yarn,parcel和kernelsu的库
```
npm install --global yarn
yarn add kernelsu
yarn global add parcel
```

### 2.使用parcel进行网页构建

GUN/Linux
```
rm -f dist
```
Windows
```
del /q dist
```

##### 临时调试模式(发生文件变动会立即生成)
```
yarn parcel
```
##### 在chrome内核的浏览器地址栏输入以下地址打开调试工具(请提前打开webview调试链接手机并复制文件到手机对应目录内)
```
chrome://inspect/#devices
```

##### 构建生产环境的正式网页
```
yarn parcel build
```

##### 相关网址

[KernelSU Webui](https://kernelsu.org/zh_CN/guide/module-webui.html)

[KernelSU Webui NPM](https://www.npmjs.com/package/kernelsu)

[parceljs](https://parceljs.org/)

[parceljs_CN](https://parceljs.cn/)<sup>*不推荐</sup>

[调试WebView的教程](https://www.jianshu.com/p/2c3523d19ef4)