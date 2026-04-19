# Free Health (自由健康) - 个人健康管理与运动追踪系统

本项目是一个全栈健康管理平台，包含移动端 App 和后端服务。旨在帮助用户记录饮食、追踪运动（步数/GPS轨迹）、管理训练计划及记录健康日记。

## 项目预览

- **移动端 (Flutter)**: 提供流畅的 UI 交互，支持训练倒计时、图表分析、GPS 运动追踪等。
- **后端 (Spring Boot)**: 基于 RESTful 架构，提供用户认证 (JWT)、数据加密 (AES)、多媒体存储及业务逻辑处理。
- **数据库 (MySQL)**: 结构化存储用户信息、健康指标及训练日志。

---

## 技术栈

### 前端 (Frontend)
- **Framework**: Flutter (Dart)
- **状态管理/数据请求**: Dio, GetStorage
- **数据库**: sqflite (本地离线缓存)
- **UI/图表**: flex_color_scheme, fl_chart, bot_toast
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
3.  导入项目中的 SQL 脚本（推荐使用最新的 `free_fitness_backend/sql/schema_v2.sql`）到 `free_fitness` 数据库。

### 2. 后端部署 (Spring Boot)
1.  **环境要求**: JDK 17+, Maven 3.6+。
2.  **配置修改**:
    修改 `free_fitness_backend/src/main/resources/application.yml` 中的数据库配置。
3.  **运行**:
    在后端目录下执行 `mvn spring-boot:run`。
4.  **接口文档**: 访问 `http://localhost:8080/swagger-ui.html` 查看。

### 3. 前端部署 (Flutter)
1.  **环境要求**: Flutter SDK 3.x+。
2.  **安装依赖**:
    在 `free_fitness` 目录下执行 `flutter pub get`。
3.  **运行**:
    执行 `flutter run`。

---

## 核心功能说明
- **智慧训练排程**: 支持“时长+组数”维度的训练排程。系统可自动根据训练总时间平均分配每组的训练时长，实现科学训练规划。
- **实时健康仪表盘**: 首页动态展示今日步数、卡路里消耗及睡眠情况。训练计划状态会根据实际运动记录实时更新（完成即打钩）。
- **专业运动报告**: 提供周/月维度的运动洞察报表，支持每日卡路里消耗的自动聚合分析及日历视图回溯。
- **运动追踪**: 支持手机传感器自动计步，并可通过 GPS 记录实时运动轨迹。
- **饮食与营养**: 提供全方位的饮食分析，支持蛋白质、脂肪、碳水、水的摄入追踪。
- **隐私与安全**: 用户的体重、BMI 等敏感生理指标在数据库中通过 AES-256 算法加密存储。

---

## 许可证
本项目采用 [MIT License](LICENSE) 授权。
