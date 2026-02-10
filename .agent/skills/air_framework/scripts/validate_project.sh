#!/bin/bash
# Validate Air project structure

echo "Validating Air project..."

# Check required directories
REQUIRED_DIRS=("lib/modules")
for dir in "${REQUIRED_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "✓ Found $dir"
  else
    echo "✗ Missing $dir"
  fi
done

# Check required files
REQUIRED_FILES=("pubspec.yaml" "lib/main.dart")
for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "✓ Found $file"
  else
    echo "✗ Missing $file"
  fi
done

# List modules
echo ""
echo "Modules found:"
count=0
for dir in lib/modules/*/; do
  if [ -d "$dir" ]; then
    module_name=$(basename "$dir")
    echo "  • $module_name"
    ((count++))
  fi
done

if [ $count -eq 0 ]; then
  echo "  (No modules found)"
fi
