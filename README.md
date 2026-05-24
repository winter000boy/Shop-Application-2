# FixManager — Mobile Repair Shop Management App

FixManager is a lightweight, high-performance, mobile-first shop management application targeted at mobile, laptop, computer, and electronics repair businesses. This repository contains the Phase 1 implementation, featuring:
* **Authentication & Shop Onboarding**: Multi-tenant email login/signup and profile configurations.
* **Repair Order Management**: Multi-section diagnostics, accessories checklist, notifications, and visual pattern drawers.
* **Offline-First Synchronization**: A resilient repository structure that saves data instantly in a local SQLite cache and merges it with the cloud when internet access is restored.

---

## 🛠️ Project Architecture

```mermaid
graph TD
    subgraph Mobile App (Flutter)
        UI[Responsive Presentation Layer] --> |Riverpod State| State[Notifier/Controllers]
        State --> |Offline Writes| SQLite[(Drift SQLite Cache)]
        State --> |Reads| SQLite
        State --> |Key-Value Prefs| Hive[(Hive Key-Value Box)]
        State --> |Resilient Requests| Client[Resilient HTTP ApiClient]
        Client --> |Intercept 401 & Auth Headers| ServerSync[Background SyncManager]
    end
    
    subgraph Cloud Backend (Spring Boot)
        Client -.-> |JWT Auth Requests| Security[Spring Security & JWT Filter]
        ServerSync -.-> |Push/Pull Packets| SyncCtrl[Sync/Order Controllers]
        Security --> SyncCtrl
        SyncCtrl --> Services[Auth / Order Services]
        Services --> JPA[Spring Data JPA Repositories]
        JPA --> Postgres[(PostgreSQL Production DB)]
        JPA --> H2[(H2 In-Memory Testing DB)]
    end
    
    classDef mobile fill:#818cf8,stroke:#4f46e5,stroke-width:2px,color:#fff;
    classDef backend fill:#34d399,stroke:#059669,stroke-width:2px,color:#fff;
    class UI,State,SQLite,Hive,Client,ServerSync mobile;
    class Security,SyncCtrl,Services,JPA,Postgres,H2 backend;
```

---

## 🚀 Part 1: Local Development Setup

### Prerequisites
Ensure you have the following installed on your machine:
* **Java 17 Development Kit (JDK)**
* **Apache Maven** (for building the backend)
* **Flutter SDK (3.x.x+)** & **Dart**
* **Android Emulator** or a physical device with USB Debugging enabled

---

### 1. Running the Spring Boot Backend

The backend is located in [`/backend`](file:///Users/sharmajidurgesh/Shop%20Application/backend). By default, it is configured with an **in-memory H2 database** to enable zero-setup execution immediately.

1. Navigate to the backend directory:
   ```bash
   cd "/Users/sharmajidurgesh/Shop Application/backend"
   ```
2. Build and compile the codebase:
   ```bash
   mvn clean compile
   ```
3. Start the application:
   ```bash
   mvn spring-boot:run
   ```
4. The API will boot up at `http://localhost:8080`.
   * **H2 Database Console**: You can view the tables in real time at `http://localhost:8080/h2-console`
     * **JDBC URL**: `jdbc:h2:mem:repairshopdb`
     * **Username**: `sa`
     * **Password**: `sa`

---

### 2. Running the Flutter Mobile App

The frontend is located in [`/mobile`](file:///Users/sharmajidurgesh/Shop%20Application/mobile).

1. Navigate to the mobile directory:
   ```bash
   cd "/Users/sharmajidurgesh/Shop Application/mobile"
   ```
2. Run our **Code-Gen Assistant** to fetch packages and compile the SQLite schema code:
   ```bash
   ./run_codegen.sh
   ```
   *If your shell doesn't have the global `flutter` PATH defined, this script will search common locations or display precise instructions on how to click "Run build_runner" inside VS Code/Android Studio.*
3. Open your Android Emulator or connect a device.
4. Launch the application:
   ```bash
   flutter run
   ```
5. **Connection Note**: By default, the app is configured to connect to `http://10.0.2.2:8080/api/v1` inside [`api_client.dart`](file:///Users/sharmajidurgesh/Shop%20Application/mobile/lib/core/network/api_client.dart). The IP `10.0.2.2` maps to your host machine's localhost from the standard Android Emulator. If you are using a physical USB device or a custom iOS simulator, modify `baseUrl` in that file to match your machine's local IP address.

---

## 🗄️ Part 2: Database Setup & Migration

We have created a dedicated, production-ready schema DDL file in [`/database/schema.sql`](file:///Users/sharmajidurgesh/Shop%20Application/database/schema.sql). 

### How to Switch from H2 to PostgreSQL
To shift from H2 in-memory storage to a persistent PostgreSQL database:
1. Open [`backend/src/main/resources/application.yml`](file:///Users/sharmajidurgesh/Shop%20Application/backend/src/main/resources/application.yml).
2. Comment out the default **H2 In-Memory Config** block.
3. Uncomment the **PostgreSQL Config** block and insert your database connection URI:
   ```yaml
   spring:
     datasource:
       url: jdbc:postgresql://localhost:5432/repairshop
       username: postgres
       password: yourpassword
       driver-class-name: org.postgresql.Driver
     jpa:
       database-platform: org.hibernate.dialect.PostgreSQLDialect
       hibernate:
         ddl-auto: update
   ```
4. If you have an empty postgres database, Spring Boot's Hibernate will automatically run DDL matching the schema on startup. If you prefer to populate the tables manually or verify constraints, you can execute the raw queries in [`database/schema.sql`](file:///Users/sharmajidurgesh/Shop%20Application/database/schema.sql) directly inside your database client (e.g., pgAdmin, DBeaver, or psql cli).

---

## ☁️ Part 3: Production & Cloud Deployment

### 1. Deploying the Spring Boot Backend

To host the backend API on the cloud (e.g., AWS, Railway, Render, or Heroku):

#### A. PostgreSQL Hosting
Set up a hosted PostgreSQL database:
* **Option A**: Provision an **AWS RDS PostgreSQL** instance.
* **Option B**: Spin up a database using cloud providers like **Render** or **Supabase**.
* Once created, obtain the connection endpoint, username, password, and port.

#### B. Packaging & Hosting
1. Package the Spring Boot app into a lightweight, optimized executable JAR:
   ```bash
   cd "/Users/sharmajidurgesh/Shop Application/backend"
   mvn clean package -DskipTests
   ```
   *This outputs a compiled JAR under `target/backend-1.0.0.jar`.*
2. **Deploying to Railway / Render**:
   * Create a new web service and link it to your repository.
   * Add the following environment variables (which Spring Boot will automatically overlay on top of `application.yml` configurations):
     * `SPRING_DATASOURCE_URL` = `jdbc:postgresql://your-db-host:5432/your-db-name`
     * `SPRING_DATASOURCE_USERNAME` = `your-db-username`
     * `SPRING_DATASOURCE_PASSWORD` = `your-db-password`
     * `APP_JWT_SECRET` = `[Generates a high-strength Base64 256-bit key]`
3. **Deploying to AWS Elastic Beanstalk**:
   * Go to AWS Console ➔ Elastic Beanstalk ➔ Create Application.
   * Select platform **Java** (Corretto 17).
   * Upload the `backend-1.0.0.jar` file.
   * Under configuration settings, add system environment variables for your RDS datasource properties and JWT secret keys.

---

### 2. Distributing the Flutter Android App

To generate a lightweight APK to install on your shop's low-end Android devices:

1. **Configure Release Mode Endpoint**:
   * Open [`mobile/lib/core/network/api_client.dart`](file:///Users/sharmajidurgesh/Shop%20Application/mobile/lib/core/network/api_client.dart).
   * Change `baseUrl` to point to your secure cloud server:
     ```dart
     static const String _productionUrl = 'https://your-cloud-api.com/api/v1';
     ```
2. **Generate Release APK**:
   * In your terminal, run the flutter compiler:
     ```bash
     flutter build apk --split-per-abi
     ```
   * *The `--split-per-abi` flag splits the bundle into individual CPU architectures (ARM 64-bit, ARM 32-bit, x86). This reduces the download size on low-end Android devices to **under 15 MB**, exceeding our Phase 1 performance targets!*
3. **Distribution**:
   * You can distribute the compiled APK directly to your shop managers, upload it to a private company portal (Firebase App Distribution), or publish it on the Google Play Store!
