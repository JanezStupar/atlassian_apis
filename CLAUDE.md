# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dart client library for Atlassian REST APIs including Jira Cloud, Jira Software, Jira Service Management, Confluence, and Cloud Admin APIs. All client code is **generated** from OpenAPI specifications provided by Atlassian.

## Common Development Commands

### Testing
```bash
dart test
```

### Code Generation
```bash
# Update API specifications from Atlassian
dart run tool/update_swagger_files.dart

# Generate client code from updated specs
dart run tool/generate_client.dart

# Generate README from template
dart run tool/generate_readme.dart
```

### Linting and Analysis
```bash
dart analyze
dart fix --dry-run  # Preview fixes
dart fix --apply    # Apply fixes
```

### Package Management
```bash
dart pub get        # Install dependencies
dart pub upgrade    # Upgrade dependencies
dart pub deps       # Show dependency tree
```

## Architecture

### Generated Code Structure
- **`lib/src/generated/`**: All API client code is auto-generated from OpenAPI specs
- **`lib/src/api_utils.dart`**: Core utilities including `ApiClient`, authentication helpers, and exception handling
- **`lib/*.dart`**: Public API exports for each service (jira_platform, confluence, etc.)

### Key Components
- **`ApiClient`**: Central HTTP client with authentication support (Basic Auth and Bearer)
- **Authentication**: Supports API tokens and OAuth via `BasicAuthenticationClient` and `BearerAuthenticationClient`
- **API Fixes**: Manual patches in `tool/generate_client.dart` for known OpenAPI spec issues

### Code Generation Pipeline
1. `tool/update_swagger_files.dart` downloads latest OpenAPI specs from Atlassian
2. `tool/generate_client.dart` processes specs and applies fixes for known issues
3. Generated code is written to `lib/src/generated/` with proper Dart formatting

## Important Notes

### Generated Code Warning
- **NEVER** manually edit files in `lib/src/generated/` - they will be overwritten
- All API client modifications must be done through the generation tools
- For API spec fixes, modify `fixApi()` function in `tool/generate_client.dart`

### API Specification Sources
The project tracks multiple Atlassian APIs defined in `tool/update_swagger_files.dart`:
- Jira Platform: `cloud/jira/platform/swagger-v3.v3.json`
- Jira Software: `cloud/jira/software/swagger.v3.json`
- Service Management: `cloud/jira/service-desk/swagger.v3.json`
- Confluence: `cloud/confluence/swagger-v3.v3.json`
- Admin APIs: Various admin endpoints

### Development Workflow
1. When updating APIs: Run update script → generate client → test
2. When fixing generated code issues: Modify generation logic, not generated files
3. Changes to authentication or core utilities go in `lib/src/api_utils.dart`

### Linting Configuration
The project uses strict linting rules via `analysis_options.yaml` including:
- Strict casts enabled
- Comprehensive linter rules from `package:lints/recommended.yaml`
- Additional rules for null safety, futures handling, and code style