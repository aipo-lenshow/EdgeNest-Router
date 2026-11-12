# EdgeNest Router — Releases

EdgeNest Router 是装在软路由（iStoreOS / OpenWrt）或普通 Linux 机器（Debian / Ubuntu）上的面板：让家里的设备按规则走代理，在外的手机电脑能连回家，还能把家里的服务发布到外网。这里放安装包和自升级用的 `router-version.json`，最新版本见 [Releases](../../releases/latest)。

EdgeNest Router is a panel for soft routers (iStoreOS / OpenWrt) and ordinary Linux machines (Debian / Ubuntu): it routes the devices at home through proxies by rule, lets phones and computers reach home while away, and publishes home services to the internet. This repository hosts the packages and the self-upgrade feed (`router-version.json`); see [Releases](../../releases/latest) for the latest version.

## 安装（按你的机器选一种）

**已经有 iStoreOS / OpenWrt：**

- 一键安装包：下载 `edgenest-router_<版本>_<架构>.run`，在 iStore「手动安装」里上传；或者传到路由器上运行 `sh edgenest-router_<版本>_<架构>.run`。
- ipk 包：下载 `edgenest-router-core_<内核版本>_<架构>.ipk` 和 `edgenest-router_<版本>_<架构>.ipk`，传到路由器上运行 `opkg install` 先装 core 再装另一个。

**普通的 Debian / Ubuntu 机器或虚拟机（64 位的 x86 或 ARM）：**

- 一行命令安装：

  ```
  curl -fsSL https://raw.githubusercontent.com/aipo-lenshow/EdgeNest-router/main/get.sh | sudo bash
  ```

- 安装时只问两件事：语言，以及用 Docker 运行还是直接装进系统。
- 以后再跑一次同一条命令，可以更新、换运行方式或卸载，设置都保留。
- 这样装出来的是旁路由：把要走它的设备的网关和 DNS 指到这台机器。
- 这种装法暂不支持「局域网共享挂载」。
- x86 在 Debian 12 和 Ubuntu 24.04 上测过；ARM 64 位只在模拟环境里测过，还没在真机上实测。

**装好之后：** 浏览器打开 `http://<路由器地址>:1123`。第一次登录用户名和密码都是 `EdgeNest`，登录后会要求改密码。以后在面板「关于 → 检查更新」就能在线升级。

## Install (pick the one for your machine)

**Already running iStoreOS / OpenWrt:**

- One-file installer: download `edgenest-router_<version>_<arch>.run` and upload it under iStore "Manual install", or copy it to the router and run `sh edgenest-router_<version>_<arch>.run`.
- ipk packages: download `edgenest-router-core_<core version>_<arch>.ipk` and `edgenest-router_<version>_<arch>.ipk`, copy them to the router and `opkg install` the core first, then the other one.

**An ordinary Debian / Ubuntu machine or virtual machine (64-bit x86 or ARM):**

- Install with one command:

  ```
  curl -fsSL https://raw.githubusercontent.com/aipo-lenshow/EdgeNest-router/main/get.sh | sudo bash
  ```

- It asks two things: the language, and whether to run in Docker or directly on the system.
- Run the same command again later to update, switch between the two, or remove; settings are kept.
- Installed this way it is a side router: point the gateway and DNS of the devices that should go through it at this machine.
- "LAN share mounting" is not available with this way of installing yet.
- x86 is tested on Debian 12 and Ubuntu 24.04; 64-bit ARM has only been tested under emulation, not on real hardware yet.

**After installing:** open `http://<router-address>:1123` in a browser. The first sign-in is `EdgeNest` / `EdgeNest`, and you will be asked to set a new password. Later, upgrade in place from About → Check for updates.

## 能做什么

- **分流**：订阅、节点、规则、按设备分流，整个局域网一起用。
- **组网**：手机电脑在外经一层伪装连回家，能访问家里的设备。家里连不上时，可以经自己的 EdgeNest 服务器绕一下。
- **网关**：动态域名、反向代理、自动证书、登录保护、局域网共享发布、服务监测和手机推送。
- **跨设备同步**：常驻的剪贴板和文件中转。

## What it does

- **Routing**: subscriptions, nodes, rules and per-device routing for the whole LAN.
- **Mesh**: phones and computers reach home from outside through a disguised entry and can use the devices there. When home can't be reached directly, they can go through one of your own EdgeNest servers.
- **Gateway**: dynamic DNS, reverse proxy, automatic certificates, sign-in protection, publishing LAN shares, service monitoring with phone alerts.
- **Cross-device sync**: an always-on relay for clipboard and files.

## 配合使用 / Works with

路由器版和下面两个项目各自独立、各自可用，版本号互不相同：

- **[EdgeNest 服务端](https://github.com/aipo-lenshow/EdgeNest)**：在自己的服务器上部署，生成节点和订阅，也可以做组网的兜底服务器。
- **[EdgeNest 客户端（macOS / Windows / Android / iOS）](https://github.com/aipo-lenshow/EdgeNest-App)**：在外的设备拨入组网后如同在家，并可一键加入本机的同步中转。

The router build stands on its own alongside these two, each versioned independently:

- **[EdgeNest server](https://github.com/aipo-lenshow/EdgeNest)**: deploy on your own server; it issues the nodes and subscriptions and can serve as a mesh fallback.
- **[EdgeNest clients (macOS / Windows / Android / iOS)](https://github.com/aipo-lenshow/EdgeNest-App)**: devices away from home dial into the mesh and behave as if on-site, and can join this router's sync relay in one tap.
