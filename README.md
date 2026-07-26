# EdgeNest Router — Releases

EdgeNest Router（iStoreOS / OpenWrt 软路由面板）的下载与自升级源。最新安装包见 [Releases](../../releases/latest)。

This repository hosts the EdgeNest Router (iStoreOS / OpenWrt panel) downloads and its self-upgrade feed (`router-version.json`). Get the latest package from [Releases](../../releases/latest).

## 安装 / Install

1. 下载对应架构的 `edgenest-router_<版本>_<架构>.ipk`（首次安装还需 `edgenest-router-core` 包），传到路由器后执行 `opkg install`。
2. 安装后访问 `http://<路由器地址>:1123` 打开面板；面板内 关于 → 检查更新 可在线升级。

1. Download the `edgenest-router_<version>_<arch>.ipk` for your architecture (a fresh install also needs the `edgenest-router-core` package), copy it to the router, and run `opkg install`.
2. After installing, open the panel at `http://<router-address>:1123`; upgrade in place any time from About → Check for updates.

## 配合使用 / Works with

路由器版负责整个局域网的分流，也可以作为「组网」的远程接入点与跨设备同步的常驻中转。它与下面两个项目各自独立，也各自可用，版本号互不相同：

- **[EdgeNest 服务端](https://github.com/aipo-lenshow/EdgeNest)** —— 在自己的服务器上部署，生成节点与订阅。
- **[EdgeNest 客户端（macOS / Windows / Android / iOS）](https://github.com/aipo-lenshow/EdgeNest-App)** —— 在外的设备拨入组网后如同在家，并可一键加入本机的同步中转。

---

The router build routes a whole LAN, and can also act as the mesh's remote
access point and the always-on relay for cross-device sync. It stands on its
own alongside these two, each versioned independently:

- **[EdgeNest server](https://github.com/aipo-lenshow/EdgeNest)** — deploy on your own server; it issues the nodes and subscriptions.
- **[EdgeNest clients (macOS / Windows / Android / iOS)](https://github.com/aipo-lenshow/EdgeNest-App)** — devices away from home dial into the mesh and behave as if on-site, and can join this router's sync relay in one tap.
