#!/bin/bash

set -e

# Local paths
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/pixospritz-rg35xx-knulli/output"
WORKSPACE_DIR="$PROJECT_DIR/pixospritz-rg35xx-knulli"

# Create output directory
mkdir -p "$BUILD_DIR/compiled/pixospritz"

# Build Pixospritz game engine
echo "Building Pixospritz game engine..."
cd "$WORKSPACE_DIR"
mkdir -p build
cd build
cmake -DCMAKE_TOOLCHAIN_FILE="$PROJECT_DIR/toolchain-rg353v.cmake" -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE ..
make -j$(nproc)
if [ $? -ne 0 ]; then
  echo "Pixospritz build failed"
  exit 1
fi

# Copy Pixospritz executable
if [ -f "$WORKSPACE_DIR/build/pixospritz" ]; then
  cp -v "$WORKSPACE_DIR/build/pixospritz" "$BUILD_DIR/compiled/pixospritz/"
  echo "Copied Pixospritz executable"
else
  echo "Error: Pixospritz executable not found at $WORKSPACE_DIR/build/pixospritz"
  exit 1
fi

# Create pixospritz.sh script (simplified for local)
cat <<'EOF' > "$BUILD_DIR/compiled/pixospritz.sh"
#!/bin/sh

export HOME=$(dirname $(realpath $0))/pixospritz
cd $HOME

# Ensure pixospritz is executable
chmod +x ./pixospritz

# Add any necessary setup for Pixospritz, e.g., SDL_GAMECONTROLLERCONFIG for RG353V

./pixospritz

kill $(jobs -p)
EOF

chmod +x "$BUILD_DIR/compiled/pixospritz.sh"

#
# Final checks and summary
#
check_build_output() {
    local error_count=0
    local warning_count=0

    # Check Pixospritz executable
    if [ -f "$BUILD_DIR/compiled/pixospritz/pixospritz" ]; then
        file_type=$(file "$BUILD_DIR/compiled/pixospritz/pixospritz")
        if [[ $file_type == *"ARM aarch64"* && $file_type == *"LSB"* && $file_type == *"executable"* ]]; then
            echo "✓ Pixospritz executable present and valid ($(basename "$file_type"))"
        else
            echo "✗ Pixospritz executable present but may be invalid: $file_type"
            ((error_count++))
        fi
    else
        echo "✗ Pixospritz executable missing"
        ((error_count++))
    fi

    # Check pixospritz.sh script
    if [ -f "$BUILD_DIR/compiled/pixospritz.sh" ]; then
        if grep -q "pixospritz" "$BUILD_DIR/compiled/pixospritz.sh"; then
            echo "✓ pixospritz.sh script present and contains expected content"
        else
            echo "✗ pixospritz.sh script present but may be invalid"
            ((warning_count++))
        fi
    else
        echo "✗ pixospritz.sh script missing"
        ((error_count++))
    fi

    # Print summary
    echo "-------------------"
    echo "Build Check Summary"
    echo "-------------------"
    echo "Errors: $error_count"
    echo "Warnings: $warning_count"

    if [ $error_count -eq 0 ] && [ $warning_count -eq 0 ]; then
        echo "Build completed successfully with no issues."
    elif [ $error_count -eq 0 ]; then
        echo "Build completed with warnings. Please review the output."
    else
        echo "Build completed with errors. Please review the output and correct the issues."
        exit 1
    fi
}

# Run the checks
check_build_output

echo "Build and check process complete. All compiled files are in $BUILD_DIR/compiled/pixospritz"
