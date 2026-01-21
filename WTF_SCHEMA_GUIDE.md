# WTF-Schema Codegen Pipeline

This document explains the fully declarative and OCI-based pipeline for managing and generating code from Protobuf schemas using Buf, Infisical, Nix/devenv, and Copier.

The pipeline is managed by the `wtf-schema` devenv profile.

## 1. Overview

This pipeline is designed to:
- **Build** the `protoc-gen-turbolink` plugin into a minimal OCI container (`worlds/wtf-schema-gen`).
- **Push** the schema to the Buf Schema Registry (BSR).
- **Generate** code for multiple targets (Unreal C++, Python/Pydantic, Postgres SQL).
- **Scaffold** configuration files and project structures using `copier`.

## 2. Setup and Initialization

Before running the full CI pipeline, you must initialize the project structure. This task uses the `copier` template in `_devenv-profiles/copier_templates/wtf-schema/` to create `buf.yaml`, `buf.gen.yaml`, and the GitHub CI workflow.

To initialize your project:

```bash
# Enter the devenv shell for the wtf-schema profile
devenv shell wtf-schema 

# Run the initialization task
wtf-schema-init
```

## 3. CI/CD Pipeline Execution

The `wtf-schema-ci` script is the core pipeline that runs all required steps sequentially. It ensures the environment is hydrated by Nix and uses Infisical for securely handling `BUF_TOKEN` and other secrets (via environment variable injection).

This single command performs:
1.  Build the TurboLink OCI container.
2.  Push the schema to `buf.build/worlds/wtf-schema`.
3.  Execute `buf generate` against local and BSR remote plugins.
4.  Trigger `copier` to scaffold a boilerplate project (`cfreqtion-output`) based on the `c99` template.

To run the complete pipeline:

```bash
# Ensure you are inside the wtf-schema devenv environment
devenv shell wtf-schema

# Execute the full CI pipeline script
wtf-schema-ci
```

## 4. Generated Targets

The `buf.gen.yaml` configures the following code generation outputs:

| Target | Generator | Location | Notes |
| :--- | :--- | :--- | :--- |
| **Unreal Engine C++** | Local OCI Container (`worlds/wtf-schema-gen`) | `Plugins/TurboLink/Source/TurboLinkGrpc` | Uses the OCI container defined in `wtf-schema.nix`. |
| **Python & Pydantic V2** | Remote BSR Plugin (`neoeul-pydanticv2`) | `gen/python` | Uses a remote BSR plugin for a light local environment. |
| **Postgres SQL Schema** | Remote BSR Plugin (`chrusty-protoc-gen-sql`) | `gen/postgres` | Generates SQL DDL directly from the Protobuf schema. |
