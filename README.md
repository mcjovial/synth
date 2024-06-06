# Synth

Synth is a command-line tool designed to gather all related files for a specified React component, providing context for debugging and refactoring. It resolves path aliases from `tsconfig.json` or `jsconfig.json` and appends the content of the related files to an output file. 

## Features

- Automatically searches for `tsconfig.json` or `jsconfig.json` to resolve path aliases.
- Collects and appends the content of related files to a single output file.
- Allows for an optional prompt to be included in the output file.
- Provides a clear structure in the output file for easy understanding.

## Requirements

- `jq` must be installed on your system to parse JSON files.

## Installation

1. Clone the repository or download `synth.sh`.

2. Make the script executable:

   ```sh
   chmod +x synth.sh
   ```

## Usage

```sh
./synth.sh --file=<path-to-component-file> [--prompt=<optional-prompt>]
```

### Example

```sh
./synth.sh --file=src/app/blog/page.tsx --prompt="Please help me debug and refactor the main file below for optimal performance."
```

### Options

- `--file`: (Required) Path to the main React component file.
- `--prompt`: (Optional) A prompt to be included at the beginning of the output file.

## Output

The output will be written to `synth-out.txt` by default. The structure of the output file is as follows:

- **Prompt** (if provided): A user-specified prompt to guide the debugging or refactoring process.
- **Main File**: The content of the main React component file, clearly marked.
- **Related Files**: The content of each related file, clearly marked with its path for context.

## Example Output

```
Please help me debug and refactor the main file below for optimal performance.

===== Main File: src/app/blog/page.tsx =====
<content of page.tsx>

===== Related Files =====
===== Related File: src/components/Blog/SingleBlog.tsx =====
<content of SingleBlog.tsx>

===== Related File: src/components/Blog/blogData.tsx =====
<content of blogData.tsx>

===== Related File: src/components/Common/Breadcrumb.tsx =====
<content of Breadcrumb.tsx>
```

## License

This project is licensed under the MIT License.
