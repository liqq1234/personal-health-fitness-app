# Free Fitness - 个人健康管理与运动追踪系统

本项目是一个全栈健康管理平台，包含移动端 App 和后端服务。旨在帮助用户记录饮食、追踪运动（步数/GPS轨迹）、管理训练计划及记录健康日记。

## 项目预览

- **移动端 (Flutter)**: 提供流畅的 UI 交互，支持训练倒计时、图表分析、GPS 运动追踪等。
- **后端 (Spring Boot)**: 基于 RESTful 架构，提供用户认证 (JWT)、数据加密 (AES)、多媒体存储及业务逻辑处理。
- **数据库 (MySQL)**: 结构化存储用户信息、健康指标及训练日志。

---

## 技术栈

### 前端 (Frontend)
- **Framework**: Flutter 3.41.4 (Dart 3.11.1)
- **状态管理/数据请求**: Dio, GetStorage
- **数据库**: sqflite (本地离线缓存)
- **美化**: flex_color_scheme, fl_chart, bot_toast
- **核心功能**: 地图 (google_maps_flutter), 步数 (pedometer), 权限处理 (permission_handler)

### 后端 (Backend)
- **Framework**: Spring Boot 3
- **安全/认证**: Spring Security, JWT (JsonObject Web Token)
- **ORM/数据库**: Spring Data JPA, MySQL 8
- **加密**: AES-256 (用于敏感数据如体重/BMI)
- **文档**: SpringDoc OpenAPI (Swagger UI)

---

## 快速开始 (快速部署)

### 1. 数据库部署 (MySQL)
1.  确保你已安装 MySQL 8.0+。
2.  创建数据库 `free_fitness`:
    ```sql
    CREATE DATABASE free_fitness DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    ```
3.  导入位于 `backend/sql/schema.sql` 的脚本到 `free_fitness` 数据库。

### 2. 后端部署 (Spring Boot)
1.  **环境要求**: JDK 17+, Maven 3.6+。
2.  **配置修改**:
    修改 `backend/src/main/resources/application.yml` 中的数据库配置:
    ```yaml
    spring:
      datasource:
        url: jdbc:mysql://localhost:3306/free_fitness
        username: your_username
        password: your_password
    ```
3.  **运行**:
    在 `backend` 目录下执行:
    ```bash
    mvn spring-boot:run
    ```
    或者使用 IDE (IntelliJ IDEA) 直接运行 `FreeFitnessBackendApplication`。
4.  **接口文档**: 访问 `http://localhost:8080/swagger-ui.html` 查看。

### 3. 前端部署 (Flutter)
1.  **环境要求**: Flutter SDK 3.x+。
2.  **安装依赖**:
    在 `frontend` 目录下执行:
    ```bash
    flutter pub get
    ```
3.  **API 地址配置**:
    确保前端代码中的 API Base URL 指向你的后端服务器地址 (默认为 `http://localhost:8080`)。
4.  **运行**:
    ```bash
    flutter run
    ```
    *注: iOS/Android 真机调试需确保手机与电脑在同一局域网，并将 localhost 改为电脑 IP。*

---

## 核心功能说明
- **运动追踪**: 支持手机传感器自动计步，并可通过 GPS 记录跑步轨迹（Json 格式存储）。
- **饮食管理**: 提供食物能量、蛋白质、脂肪及碳水化合物的每日摄入分析。
- **训练计划**: 自定义训练动作与组合，带间歇倒计时提醒。
- **隐私保护**: 用户的体重、BMI 等敏感生理指标在数据库中通过 AES-256 算法加密存储。

## 许可证
[MIT License](LICENSE)
