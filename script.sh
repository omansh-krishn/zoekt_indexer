#!/bin/bash
export PATH=$PATH:$HOME/go/bin
   AOSP_DIR="/tmp/src/android"
   BASE_DIR="$(pwd)"
   ZOEKT_CTAGS_ENABLED=1  # Enable ctags for symbol indexing

   # Find all .git directories and index them
   cat $AOSP_DIR/zoekt/list1 | while read -r git_dir; do
       repo_dir=$AOSP_DIR/$(dirname "$git_dir")
       INDEX_DIR="$BASE_DIR/index/$(echo "$repo_dir" | sed 's|/|_|g' | sed 's|^/tmp||')"
       mkdir -p $INDEX_DIR
       echo "Indexing $repo_dir..."
       zoekt-git-index \
           -index "$INDEX_DIR" \
           -submodules=false \
           -incremental \
           "$repo_dir"
       zoekt_index_file_path=($INDEX_DIR/*.zoekt)
       zoekt_index_sym_name="${zoekt_index_file[0]//\//}"
       ln -s "$(realpath "$zoekt_index_file_path")" ${zoekt_index_sym_name}

   done

   echo "Indexing complete."
