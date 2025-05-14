#!/bin/bash

if ! command -v go &>/dev/null; then
    echo "go is not installed."
    exit 1
fi

if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
    export PATH=$PATH:$HOME/go/bin
fi

# Check if zoekt-git-index is installed
if ! command -v zoekt-git-index &>/dev/null; then
    echo "zoekt binary not found. Installing..."
    go install github.com/sourcegraph/zoekt/cmd/...@latest || {
        echo "Error: Failed to install zoekt"
        exit 1
    }
fi

AOSP_DIR="/tmp/src/android"
BASE_DIR="$(pwd)"
ZOEKT_CTAGS_ENABLED=1  # Enable ctags for symbol indexing

[[ -d "$AOSP_DIR" ]] || { echo "Error: $AOSP_DIR does not exist"; exit 1; }

find "$AOSP_DIR"/* -name ".git" | while read -r git_dir; do
    repo_dir=$(dirname "$git_dir")
    INDEX_DIR="$BASE_DIR/index/$(echo "$repo_dir" | sed 's|/|_|g')"

    mkdir -p "$INDEX_DIR"

    echo "Indexing $repo_dir..."
    zoekt-git-index \
        -index "$INDEX_DIR" \
        -submodules=false \
        -incremental \
        "$repo_dir" || {
            echo "Error: Failed to index $repo_dir"
            continue
        }

    zoekt_index_file_path=("$INDEX_DIR"/*.zoekt)
    if [[ ${#zoekt_index_file_path[@]} -eq 0 ]]; then
        echo "Warning: No .zoekt files found in $INDEX_DIR"
        continue
    fi

    zoekt_index_sym_name="${zoekt_index_file_path[0]//\//_}"
    target_path="$(realpath "${zoekt_index_file_path[0]}")"

    # check if the symlnk already exists
    if [[ -L "$zoekt_index_sym_name" ]]; then
        existing_target="$(readlink -f "$zoekt_index_sym_name")"

        # do nothing if symlnk is correct
        if [[ "$existing_target" == "$target_path" ]]; then
            echo "Symlink $zoekt_index_sym_name already exists and is correct."
        else
            echo "ERROR: Symlink $zoekt_index_sym_name already exists and points to a different file:"
            echo "       Existing: $existing_target"
            echo "       ShouldBe: $target_path"
        fi
    else
        # create symlnk if it doesn't exist
        ln -s "$target_path" "$zoekt_index_sym_name" || {
            echo "Error: Failed to create symlink $zoekt_index_sym_name"
            continue
        }
        echo "Created symlink $zoekt_index_sym_name -> $target_path"
    fi
done

echo "Indexing complete."
