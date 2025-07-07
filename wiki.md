Based on the sources you provided, I can prepare the content available for the listed sections in Markdown format.

However, please note that the provided sources are primarily excerpts from the **"Overview"** page of the DeepWiki, along with a list of the available sub-pages. The detailed content for most of the specific sub-pages you listed (like "Architecture & Design", "Application Structure", "Routing & Navigation", etc.) is **not included** in the sources you provided.

I will provide the content that *is* available in the sources, formatted according to your request, and indicate where the detailed information for a specific sub-page is missing from the provided material.

Here is the content from the sources, structured based on your requested list of sub-pages:

***

# Flutter Bloc Advanced DeepWiki Content

## 1. Overview

This page provides a comprehensive introduction to the **Flutter Bloc Advanced template**. It is described as a production-ready foundation for developing scalable Flutter applications with robust architecture and essential features. For detailed information about specific subsystems, you should refer to their dedicated pages in this wiki.

**Flutter Bloc Advanced** is an open-source template built with Flutter and the BLoC (Business Logic Component) architecture pattern. Its purpose is to provide a structured, maintainable foundation for developing cross-platform applications. It includes features like authentication, user management, role-based access control, and multi-environment support. The template aims to help developers quickly start new Flutter projects by providing best practices for state management, routing, and API integration already implemented.

Relevant source files mentioned include:
*   `README.md`
*   `assets/mock/GET_customer.json`
*   `lib/configuration/environment.dart`
*   `lib/data/repository/customer_repository.dart`
*   `lib/data/repository/login_repository.dart`
*   `lib/main/app.dart`
*   `lib/main/main_local.dart`
*   `lib/main/main_local.mapper.g.dart`
*   `lib/main/main_prod.dart`
*   `lib/main/main_prod.mapper.g.dart`
*   `lib/presentation/screen/customer/bloc/customer.dart`
*   `lib/presentation/screen/customer/bloc/customer_bloc.dart`
*   `lib/presentation/screen/customer/bloc/customer_event.dart`
*   `lib/presentation/screen/customer/bloc/customer_state.dart`
*   `lib/presentation/screen/customer/create/create_customer_screen.dart`
*   `lib/presentation/screen/customer/edit/edit_customer_screen.dart`
*   `lib/presentation/screen/customer/edit/edit_form_customer_widget.dart`
*   `lib/presentation/screen/customer/list/list_customer_screen.dart`
*   `pubspec.lock`
*   `pubspec.yaml`

Source for Overview section.

## 2. Architecture & Design

The provided sources list "Architecture & Design" as a sub-page, and the Overview section includes a "System Architecture Overview". However, the detailed content specifically under a dedicated "Architecture & Design" page is **not present** in the provided excerpts.

Based on the "System Architecture Overview" in the provided sources:

### High-Level Architecture

The system follows a **layered architecture** with clear separation of concerns between UI, business logic, and data access layers. The template leverages the **BLoC pattern for state management**, providing a predictable state flow throughout the application.

Sources for High-Level Architecture.

### Environment Configuration

Flutter Bloc Advanced supports **multiple environments** (development, testing, and production) with environment-specific configurations. The template uses different entry points (`main_local.dart` and `main_prod.dart`) to initialize the appropriate environment. In development mode, the application uses mock data, while in production mode, it connects to real API endpoints.

Sources for Environment Configuration.

## 2.1 Application Structure

"Application Structure" is listed as a sub-page. However, the detailed content specifically under a dedicated "Application Structure" page is **not present** in the provided excerpts.

## 2.2 State Management with BLoC Pattern

"State Management with BLoC Pattern" is listed as a sub-page, and the Overview mentions BLoC implementation.

Based on the "BLoC Pattern Implementation" in the provided sources:

The template implements the **BLoC (Business Logic Component) pattern** for state management. This pattern provides a clean separation between UI components and business logic. UI components **dispatch events to BLoCs**, which process these events, **interact with repositories** to fetch or modify data, and **emit states** that the UI reacts to.

Sources for State Management with BLoC Pattern (based on BLoC Pattern Implementation in Overview).

## 2.3 Routing & Navigation

"Routing & Navigation" is listed as a sub-page. However, the detailed content specifically under a dedicated "Routing & Navigation" page is **not present** in the provided excerpts.

## 2.4 API Communication

"API Communication" is listed as a sub-page. However, the detailed content specifically under a dedicated "API Communication" page is **not present** in the provided excerpts. The sources do mention that the template connects to real API endpoints in production.

## 2.5 Internationalization & Localization

"Internationalization & Localization" is listed as a sub-page. The sources also mention "Internationalization" as a Key Feature.

Based on the "Internationalization" section in the provided sources:

The template includes built-in support for **internationalization**, allowing applications to be localized for different languages and regions.

Sources for Internationalization & Localization (based on Internationalization in Key Features).

## 3. Core Features

"Core Features" is listed as a sub-page. The sources also have a section titled "Key Features".

Based on the "Key Features" section in the provided sources:

The template includes several key features:
*   Authentication System
*   Role-Based Access Control
*   Multi-Environment Support
*   Internationalization
*   Theming

Sources for Core Features (based on Key Features).

## 3.1 Authentication & Authorization

"Authentication & Authorization" is listed as a sub-page. The sources also have a section titled "Authentication System" under Key Features and mention "Role-Based Access Control".

Based on the "Authentication System" and "Role-Based Access Control" sections in the provided sources:

### Authentication System

The template includes a comprehensive **authentication system** with:
*   Username/password login
*   One-Time Password (OTP) verification
*   JWT token-based authentication
*   Secure storage of authentication tokens
*   User registration and account management

Sources for Authentication System.

### Role-Based Access Control

The template implements **role-based access control** to secure routes and features. This includes:
*   User roles (admin, user)
*   Authority-based permissions
*   Protected routes accessible only to authorized users
*   Role-specific UI elements and navigation

Sources for Role-Based Access Control.

## 3.2 User Management

"User Management" is listed as a sub-page. The sources briefly mention "User registration and account management" as part of the Authentication System and "User roles (admin, user)" as part of Role-Based Access Control. However, the detailed content specifically under a dedicated "User Management" page is **not present** in the provided excerpts.

## 3.3 Account Management

"Account Management" is listed as a sub-page. The sources briefly mention "User registration and account management" as part of the Authentication System. However, the detailed content specifically under a dedicated "Account Management" page is **not present** in the provided excerpts.

## 3.4 Customer Management

"Customer Management" is listed as a sub-page. The provided sources list several source files related to customer management, including:
*   `assets/mock/GET_customer.json`
*   `lib/data/repository/customer_repository.dart`
*   `lib/presentation/screen/customer/bloc/customer.dart`
*   `lib/presentation/screen/customer/bloc/customer_bloc.dart`
*   `lib/presentation/screen/customer/bloc/customer_event.dart`
*   `lib/presentation/screen/customer/bloc/customer_state.dart`
*   `lib/presentation/screen/customer/create/create_customer_screen.dart`
*   `lib/presentation/screen/customer/edit/edit_customer_screen.dart`
*   `lib/presentation/screen/customer/edit/edit_form_customer_widget.dart`
*   `lib/presentation/screen/customer/list/list_customer_screen.dart`

However, the detailed explanatory content specifically under a dedicated "Customer Management" page is **not present** in the provided excerpts.

## 4. UI Components

"UI Components" is listed as a sub-page. However, the detailed content specifically under a dedicated "UI Components" page is **not present** in the provided excerpts.

## 4.1 Common Widgets

"Common Widgets" is listed as a sub-page. However, the detailed content specifically under a dedicated "Common Widgets" page is **not present** in the provided excerpts.

## 4.2 Forms & Input Handling

"Forms & Input Handling" is listed as a sub-page. The sources list files related to customer forms (`edit_form_customer_widget.dart`). However, the detailed explanatory content specifically under a dedicated "Forms & Input Handling" page is **not present** in the provided excerpts.

## 5. Development & Testing

"Development & Testing" is listed as a sub-page. The sources also have a "Getting Started" section with sub-sections related to environments and testing.

Based on the "Getting Started" section in the provided sources:

### Getting Started

The "Getting Started" section outlines how to run the application in different environments and provides test user details.

#### Development Environment

To run the application in the development environment with mock data:
*(Specific instructions were not provided in the excerpt, only the heading)*

#### Production Environment

To run the application in the production environment with real API:
*(Specific instructions were not provided in the excerpt, only the heading)*

#### Test Users

For testing in the development environment, the following accounts are available:

| Username   | Password   | Role   | Description                      |
| :--------- | :--------- | :----- | :------------------------------- |
| admin      | admin      | Admin  | Access to all features and admin pages |
| user       | user       | User   | Access to user-specific features only |

Sources for Getting Started.

## 5.1 Environment Setup

"Environment Setup" is listed as a sub-page. The sources discuss "Environment Configuration" and "Application Entry Points" in the Overview.

Based on these sections:

### Environment Configuration

Flutter Bloc Advanced supports **multiple environments** (development, testing, and production) with environment-specific configurations.

Sources for Environment Configuration.

### Application Entry Points

The template has **two main entry points**:
*   **Development Environment** (`main_local.dart`): Uses mock API responses, configures development logging, sets up development environment variables.
*   **Production Environment** (`main_prod.dart`): Connects to real API endpoints, configures production logging, sets up production environment variables.

Both entry points follow a similar initialization pattern.

Sources for Application Entry Points.

## 5.2 CI/CD Pipeline

"CI/CD Pipeline" is listed as a sub-page. However, the detailed content specifically under a dedicated "CI/CD Pipeline" page is **not present** in the provided excerpts.

## 5.3 Mock Data & Testing

"Mock Data & Testing" is listed as a sub-page. The sources mention the use of **mock data** in the development and test environments. The source file `assets/mock/GET_customer.json` is also listed.

Based on the provided information regarding mock data:

In development mode, the application uses **mock data**. The Development Environment entry point (`main_local.dart`) is configured to use mock API responses. The multi-environment support table indicates that both Development and Test environments use **Mock Data**, specifically local JSON files for API responses.

Sources for Mock Data & Testing (based on environment descriptions).

***

In summary, the provided sources offer a good overview of the project, its architecture, core components (especially BLoC), key features, and initial setup instructions. However, they do not contain the detailed content that would typically be found on dedicated pages for many of the listed sub-sections like Architecture & Design specifics, Routing, API Communication details, User/Account/Customer Management intricacies, UI Component details, Forms handling, or CI/CD pipeline specifics. You would likely need access to the full DeepWiki or the project codebase itself for that detailed information.