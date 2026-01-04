### SCRIPTS

# Show all commands
default:
    @just --list

### BOILERPLATE ###

set shell := ["bash", "-uc"]

scripts_dir := justfile_directory() / "scripts"

# The Universal Runner
run name *args:
    #!/usr/bin/env bash
    if [ -x "{{ scripts_dir }}/{{ name }}" ]; then
        "{{ scripts_dir }}/{{ name }}" {{ args }}
    elif [ -f "{{ scripts_dir }}/{{ name }}.sh" ]; then
        bash "{{ scripts_dir }}/{{ name }}.sh" {{ args }}
    elif [ -f "{{ scripts_dir }}/{{ name }}.nu" ]; then
        nu "{{ scripts_dir }}/{{ name }}.nu" {{ args }}
    else
        echo "Error: '{{ name }}' not found in {{ scripts_dir }}" && exit 1
    fi

# Ergonomic shorthand for testing
test-all:
    just run test-bash "arg1" "arg2"
    just run test-nu "arg1" "arg2"

# Utility: Ensure all scripts are executable
fix-perms:
    chmod +x {{ scripts_dir }}/*
