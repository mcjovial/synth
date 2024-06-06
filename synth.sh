#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 --file=<path-to-component-file> [--prompt=<optional-prompt>]"
    exit 1
}

# Function to find the config file (tsconfig.json or jsconfig.json)
find_config_file() {
    if [ -f "tsconfig.json" ]; then
        echo "tsconfig.json"
    elif [ -f "jsconfig.json" ]; then
        echo "jsconfig.json"
    else
        echo ""
    fi
}

# Parse arguments
for arg in "$@"; do
    case $arg in
    --file=*)
        component_file="${arg#*=}"
        shift
        ;;
    --prompt=*)
        prompt="${arg#*=}"
        shift
        ;;
    *)
        usage
        ;;
    esac
done

# Check if component_file is set
if [ -z "$component_file" ]; then
    usage
fi

# Set default values
output_file="synth-out.txt"
config_file=$(find_config_file)
alias_map_file=$(mktemp)

# Check if jq is installed
if ! command -v jq &>/dev/null; then
    echo "jq could not be found, please install it."
    exit 1
fi

# Function to parse the config file and get path aliases
parse_config() {
    local config_file=$1
    local alias_map_file=$2
    jq -r '.compilerOptions.paths | to_entries[] | "\(.key) \(.value[])"' "$config_file" | while read -r line; do
        alias=$(echo "$line" | cut -d' ' -f1 | tr -d '"')
        path=$(echo "$line" | cut -d' ' -f2 | tr -d '"')
        alias="${alias/\/\*/}"
        path="${path/\/\*/}"
        echo "$alias $path" >>"$alias_map_file"
    done
}

# Function to resolve path aliases
resolve_path_alias() {
    local import_path=$1
    local alias_map_file=$2
    while read -r alias path; do
        if [[ "$import_path" == "$alias"* ]]; then
            resolved_path="${import_path/$alias/$path}"
            echo "$resolved_path"
            return
        fi
    done <"$alias_map_file"
    echo "$import_path"
}

# Function to check for the existence of a file with various extensions
find_file_with_extensions() {
    local base_path=$1
    local dir_path=$(dirname "$base_path")
    local file_name=$(basename "$base_path")
    local extensions=(".js" ".jsx" ".ts" ".tsx")
    for ext in "${extensions[@]}"; do
        if [ -f "${dir_path}/${file_name}${ext}" ]; then
            echo "${dir_path}/${file_name}${ext}"
            return
        fi
    done
    echo ""
}

# Function to recursively gather all related files and append their content
gather_related_files() {
    local file=$1
    local output_file=$2
    local alias_map_file=$3
    local dir=$(dirname "$file")

    # Read the file and find all import statements
    grep -Eo "import.*from\s+['\"][^'\"]+['\"]" "$file" | while read -r line; do
        # Extract the path from the import statement
        import_path=$(echo "$line" | grep -Eo "['\"][^'\"]+['\"]" | tr -d "'\"")

        # Resolve path aliases
        resolved_import_path=$(resolve_path_alias "$import_path" "$alias_map_file")

        # Resolve the full path
        full_path=$(find_file_with_extensions "$resolved_import_path")

        echo "Processing import: $resolved_import_path -> $full_path"

        # If the path is a directory, check for index.js or index.tsx
        if [ -d "$full_path" ]; then
            if [ -f "$full_path/index.js" ]; then
                full_path="$full_path/index.js"
            elif [ -f "$full_path/index.tsx" ]; then
                full_path="$full_path/index.tsx"
            else
                continue
            fi
        elif [ -z "$full_path" ]; then
            continue
        fi

        echo "Adding file to output: $full_path"

        # Append the full path and its content to the output file
        echo "===== Related File: $full_path =====" >>"$output_file"
        cat "$full_path" >>"$output_file"
        echo "" >>"$output_file"

        # Recursively gather files for the imported file
        gather_related_files "$full_path" "$output_file" "$alias_map_file"
    done
}

# Parse the config file for path aliases if it exists
if [ -n "$config_file" ]; then
    parse_config "$config_file" "$alias_map_file"
fi

# Clear the output file
>"$output_file"

# Add a prompt to the output file if provided
if [ -n "$prompt" ]; then
    echo "$prompt" >>"$output_file"
    echo "" >>"$output_file"
fi

# Add a header and the initial component file content to the output file
echo "===== Main File: $component_file =====" >>"$output_file"
cat "$component_file" >>"$output_file"
echo "" >>"$output_file"
echo "Adding initial file to output: $component_file"

# Add a header for related files
echo "===== Related Files =====" >>"$output_file"

# Start gathering related files
gather_related_files "$component_file" "$output_file" "$alias_map_file"

# Clean up temporary file
rm "$alias_map_file"

echo "Related files gathered in $output_file"
