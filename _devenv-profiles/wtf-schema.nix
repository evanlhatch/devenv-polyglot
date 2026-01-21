{
  pkgs,
  config,
  ...
}: {
  # Use a type annotation for clarity as per user preference
  profiles.wtf-schema.module = (
    {config, ...}: {
      # 1. Environment requirements
      languages.dotnet.enable = true;
      packages = [pkgs.buf pkgs.infisical pkgs.copier pkgs.git];

      # Infisical secret for Buf Schema Registry token
      infisical.secrets = {
        BUF_TOKEN = {
          secret = "buf";
          environment = "default";
        };
      };

      # 2. Distroless-style OCI container (Kept for the TurboLink generator)
      containers.wtf-schema = {
        name = "worlds/wtf-schema-gen";
        copyToRoot = [./dist/turbolink];
        startupCommand = "/turbolink/protoc-gen-turbolink";
      };

      # 3. Automation Scripts
      scripts.wtf-schema-init = {
        description = "Scaffolds project root with buf config and CI workflow";
        exec = ''
          echo "Scaffolding wtf-schema project infrastructure..."
          # The template path is resolved declaratively relative to this Nix file.
          ${pkgs.copier}/bin/copier copy \
            ${./copier_templates/wtf-schema} \
            . \
            --overwrite \
            --data project_name=wtf-schema
          echo "Scaffolding complete. Run 'devenv shell' for environment setup."
        '';
      };

      scripts.wtf-schema-build-plugin = {
        description = "Build the TurboLink plugin binary locally for wtf-schema";
        exec = ''
          if [ ! -d "tools/protoc-gen-turbolink" ]; then
            git clone https://github.com/thejinchao/protoc-gen-turbolink tools/protoc-gen-turbolink
          fi
          dotnet publish tools/protoc-gen-turbolink/protoc-gen-turbolink.csproj \
            -c Release -r linux-x64 --self-contained true \
            -p:PublishSingleFile=true -o dist/turbolink
        '';
      };

      # The key CI pipeline that now includes copier scaffolding
      scripts.wtf-schema-ci = {
        description = "Complete CI pipeline: Build, Push, Generate, and Scaffold";
        exec = ''
          wtf-schema-build-plugin
          devenv container wtf-schema build

          # 1. Push schema to Buf Schema Registry (BSR)
          infisical run --env=production -- buf push

          # 2. Generate code: Unreal C++, Pydantic, Postgres SQL
          infisical run --env=production -- buf generate

          # 3. Trigger Copier Scaffolding for 'cfreqtion'
          echo "Triggering copier scaffolding for 'cfreqtion' based on c99 template example..."
          # The template path is resolved declaratively relative to this Nix file.
          ${pkgs.copier}/bin/copier copy \
            ${./copier_templates/c99} \
            ./cfreqtion-output \
            --overwrite \
            --data project_name=cfreqtion
          echo "Scaffolding complete."
        '';
      };
    }
  );
}
