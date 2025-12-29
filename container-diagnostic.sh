#!/bin/bash
# This MUST run inside the container to see what Docker actually mounted

echo "=========================================="
echo "Container Mount Diagnostic"
echo "=========================================="
echo ""

echo "1. Where am I?"
pwd
echo ""

echo "2. What's in /home/builder/work?"
ls -la /home/builder/work/ 2>&1
echo ""

echo "3. Does rg353v-custom exist in the container?"
if [ -d "/home/builder/work/rg353v-custom" ]; then
    echo "✓ YES - /home/builder/work/rg353v-custom EXISTS"
    ls -la /home/builder/work/rg353v-custom/
else
    echo "✗ NO - /home/builder/work/rg353v-custom DOES NOT EXIST"
fi
echo ""

echo "4. Does buildroot exist?"
if [ -d "/home/builder/work/rg353v-custom/buildroot" ]; then
    echo "✓ YES - buildroot directory exists"
    ls -la /home/builder/work/rg353v-custom/buildroot/
else
    echo "✗ NO - buildroot directory missing"
fi
echo ""

echo "5. Does buildroot-2024.02.1 exist?"
if [ -d "/home/builder/work/rg353v-custom/buildroot/buildroot-2024.02.1" ]; then
    echo "✓ YES - buildroot-2024.02.1 exists"
    ls /home/builder/work/rg353v-custom/buildroot/buildroot-2024.02.1/ | head -20
else
    echo "✗ NO - buildroot-2024.02.1 missing"
    echo "Contents of buildroot directory:"
    ls -la /home/builder/work/rg353v-custom/buildroot/ 2>&1
fi
echo ""

echo "6. Does the Makefile exist?"
if [ -f "/home/builder/work/rg353v-custom/buildroot/buildroot-2024.02.1/Makefile" ]; then
    echo "✓ YES - Buildroot Makefile found"
else
    echo "✗ NO - Buildroot Makefile missing"
fi
echo ""

echo "7. Does configs/rg353v_defconfig exist?"
if [ -f "/home/builder/work/rg353v-custom/configs/rg353v_defconfig" ]; then
    echo "✓ YES - defconfig found"
    echo "Content:"
    head -10 /home/builder/work/rg353v-custom/configs/rg353v_defconfig
else
    echo "✗ NO - defconfig missing"
fi
echo ""

echo "=========================================="
echo "Diagnostic Complete"
echo "=========================================="