{
  pkgs,
  lib,
  config,
  ...
}:
{
  profiles.py = {
    module = {
      enterShell = ''
        export DEVENV_ACTIVE_PROFILES="''${DEVENV_ACTIVE_PROFILES} 🐍 py"
      '';

      # 1. Configure UV environment variables for system Python preference.
      env.UV_PYTHON_DOWNLOADS = "never";
      env.UV_PYTHON_PREFERENCE = "only-system";
      env.UV_PROJECT_ENVIRONMENT = "${config.env.DEVENV_STATE}/venv";

      # 2. Enable devenv's core Python language support with UV.
      languages.python = {
        enable = true;
        uv = {
          enable = true;
          sync = {
            enable = true;
            groups = [ "base" ];
            # Force uv to use the devenv-managed venv path
            arguments = [
              "--active"
              "--project"
              "${config.env.DEVENV_ROOT}"
            ];
          };
        };
      };

      # 3. Define the package set for the Python stack.
      packages = with pkgs; [
        # Type checking
        # basedpyright
        # Formatter and linter
        ruff
        # ty
      ];

      # 4. Git hooks for dependency management.
      git-hooks.hooks = {
        uv-check.enable = true;
        uv-lock.enable = true;
        uv-export = {
          enable = false;
          settings.locked = true;
        };
      };

      # 5. Centralized formatting, linting, and type checking via treefmt.
      treefmt.config.programs = {
        ruff-format.enable = true;
        ruff-check.enable = true;
        #basedpyright.enable = true;
      };
    };
  };

  # Extended profiles that inherit from the base 'py' profile.
  profiles.marimo = {
    extends = [ "py" ];
    module = {
      languages.python.uv.sync.groups = [
        "base"
        "marimo"
      ];
      packages = with pkgs; [ duckdb ];
    };
  };

  profiles.dagster = {
    extends = [ "py" ];
    module = {
      languages.python.uv.sync.groups = [
        "base"
        "marimo"
        "dagster"
      ];
      packages = with pkgs; [ ];
    };
  };

  profiles.fastapi = {
    extends = [ "py" ];
    module = {
      languages.python.uv.sync.groups = [
        "base"
        "fastapi"
      ];
      packages = with pkgs; [
        sqlc
        atlas
      ];
    };
  };

  # --- NEW: Scaffolding Profiles ---

  profiles.analytics-workbench = {
    extends = [ "dagster" ];
    module = {
      # Minimal scaffolding for production-grade DuckDB analytics stack
      scripts.setup-analytics-workbench = {
        description = "Create analytics-workbench structure (Dagster + dlt + SQLMesh)";
        exec = ''
                    if [ ! -d "pipelines" ]; then
                      echo "Creating analytics-workbench structure..."

                      # Create directories
                      mkdir -p pipelines/{ingest,transform}
                      mkdir -p data/{lake,sqlmesh_state}
                      mkdir -p marimo tests

                      # Create __init__.py files to make it a package
                      touch pipelines/__init__.py
                      touch pipelines/ingest/__init__.py
                      touch pipelines/transform/__init__.py
                      touch tests/__init__.py

                      # Create resources.py with DuckDB config
                      cat > pipelines/resources.py << 'PYEOF'
          """
          Central DuckDB configuration for production pipelines.
          One-line change to use MotherDuck or switch environments.
          """
          from dagster import ConfigurableResource
          from typing import Dict, Any

          class DuckDBStackResource(ConfigurableResource):
              """Configure once, use everywhere (dlt, SQLMesh, DuckDB)"""

              warehouse_path: str = "data/warehouse.db"
              state_path: str = "data/sqlmesh_state.db"
              lake_path: str = "data/lake"

              # dlt config: incremental loads, Parquet format
              def get_dlt_config(self) -> Dict[str, Any]:
                  return {
                      "destination.duckdb.credentials": self.warehouse_path,
                      "normalize.parquet_normalizer.add_dlt_load_id": True,
                      "loader_file_format": "parquet",
                  }

              # SQLMesh config: separate state DB (CRITICAL), DuckDB dialect
              def get_sqlmesh_config(self) -> Dict[str, Any]:
                  return {
                      "model_defaults": {"dialect": "duckdb"},
                      "gateways": {
                          "prod": {
                              "connection": {
                                  "type": "duckdb",
                                  "database": self.warehouse_path,
                              }
                          }
                      },
                      # CRITICAL: Separate state DB prevents accidental full-warehouse wipes
                      "state_connection": {
                          "type": "duckdb",
                          "database": self.state_path,
                      },
                  }

              # Direct connection for maintenance and ad-hoc queries
              def get_connection(self):
                  """Get raw DuckDB connection"""
                  import duckdb
                  conn = duckdb.connect(self.warehouse_path)
                  conn.sql("INSTALL httpfs; LOAD httpfs;")
                  conn.sql("SET threads=0")  # Use all cores
                  return conn
          PYEOF

                      # Create definitions.py with Dagster boilerplate
                      cat > pipelines/definitions.py << 'PYEOF'
          """
          Dagster definitions. Uncomment sections as you add pipelines.
          """
          from dagster import Definitions, asset, AssetExecutionContext, ScheduleDefinition
          from .resources import DuckDBStackResource

          # --- Ingestion (dlt) ---
          # 1. Create pipelines/ingest/your_source.py
          # 2. Import here: from .ingest.your_source import pipeline, resource
          # 3. Uncomment:
          # from dagster_dlt import dlt_assets
          # @dlt_assets(dlt_source=resource(), dlt_pipeline=pipeline())
          # def ingestion_assets(context, stack: DuckDBStackResource): ...

          # --- Transformation (SQLMesh) ---
          # 1. Create pipelines/transform/ folder with models
          # 2. Uncomment:
          # from dagster_sqlmesh import sqlmesh_assets
          # @sqlmesh_assets(connection_id="prod")
          # def transform_assets(): ...

          # --- Maintenance ---
          @asset
          def maintenance_ops(context: AssetExecutionContext, stack: DuckDBStackResource):
              """Weekly: checkpoint WAL, compact files"""
              import duckdb
              conn = duckdb.connect(stack.warehouse_path)
              conn.sql("CHECKPOINT")
              context.log.info("Maintenance complete")

          # --- Schedule ---
          # daily_schedule = ScheduleDefinition(
          #     job=ingestion_assets + transform_assets,
          #     cron_schedule="0 6 * * *",
          # )

          defs = Definitions(
              assets=[
                  maintenance_ops,
                  # ingestion_assets,  # Uncomment when ready
                  # transform_assets,  # Uncomment when ready
              ],
              resources={"stack": DuckDBStackResource()},
              # schedules=[daily_schedule],  # Uncomment when ready
          )
          PYEOF

                      # Create .gitignore
                      cat > .gitignore << 'GITEOF'
          # Devenv
          .devenv/
          .direnv/

          # Python
          __pycache__/
          *.pyc

          # DuckDB (CRITICAL: separate state DB prevents data loss)
          data/warehouse.db
          data/warehouse.db.wal
          data/sqlmesh_state.db
          data/sqlmesh_state.db.wal
          data/lake/*.parquet

          # Marimo
          marimo/*.db
          GITEOF

                      echo "Analytics workbench created! Next steps:"
                      echo "1. Add your dlt pipelines to pipelines/ingest/"
                      echo "2. Add SQLMesh models to pipelines/transform/"
                      echo "3. Run: dagster dev -f pipelines/definitions.py"
                    fi
        '';
      };

      # Auto-run setup on shell entry
      tasks."analytics:init".exec = "setup-analytics-workbench";
      tasks."analytics:init".before = [ "devenv:enterShell" ];
    };
  };

  profiles.analysis-workbench = {
    extends = [ "py" ];
    module = {
      # Ultra-minimal scaffolding for DuckDB + Marimo analysis
      scripts.setup-analysis-workbench = {
        description = "Create analysis-workbench structure (DuckDB + Marimo)";
        exec = ''
                    if [ ! -d "analysis" ]; then
                      echo "Creating analysis-workbench structure..."

                      mkdir -p analysis data marimo

                      # Create utils.py with DuckDB helpers
                      cat > analysis/utils.py << 'PYEOF'
          """
          DuckDB utilities for analysis workbench.
          Lazy evaluation: all functions return connections, not data.
          """
          import duckdb

          def get_connection(db_path: str = "data/warehouse.db"):
              """
              Get DuckDB connection optimized for powerful machines.
              httpfs: Query Parquet from S3/HTTP without copying locally.
              """
              conn = duckdb.connect(db_path)
              conn.sql("INSTALL httpfs; LOAD httpfs;")
              conn.sql("SET threads=0")  # Use all cores
              return conn
          PYEOF

                      # Create .gitignore
                      cat > .gitignore << 'GITEOF'
          .devenv/ .direnv/
          __pycache__/
          data/*.db
          marimo/*.db
          GITEOF

                      echo "Analysis workbench created! Next steps:"
                      echo "1. Create notebooks in marimo/"
                      echo "2. Use: conn = analysis.utils.get_connection()"
                    fi
        '';
      };

      # Auto-run setup on shell entry
      tasks."analysis:init".exec = "setup-analysis-workbench";
      tasks."analysis:init".before = [ "devenv:enterShell" ];
    };
  };
}
