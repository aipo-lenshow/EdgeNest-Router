# EdgeNest Router — Releases

EdgeNest Router（iStoreOS / OpenWrt 软路由面板）的下载与自升级源。最新安装包见 [Releases](../../releases/latest)。

This repository hosts the EdgeNest Router (iStoreOS / OpenWrt panel) downloads and its self-upgrade feed (`router-version.json`). Get the latest package from [Releases](../../releases/latest).

## 安装 / Install

1. 下载对应架构的 `edgenest-router_<版本>_<架构>.ipk`（首次安装还需 `edgenest-router-core` 包），传到路由器后执行 `opkg install`。
2. 安装后访问 `http://<路由器地址>:1123` 打开面板；面板内 关于 → 检查更新 可在线升级。

1. Download the `edgenest-router_<version>_<arch>.ipk` for your architecture (a fresh install also needs the `edgenest-router-core` package), copy it to the router, and run `opkg install`.
2. After installing, open the panel at `http://<router-address>:1123`; upgrade in place any time from About → Check for updates.
