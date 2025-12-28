# Pixospritz for the H700 SoC (RG35XX* & RG40XX* devices)

This repository contains a Dockerfile and build script for compiling the Pixospritz game engine for the RG35XX* & RG40XX* devices using the Knulli CFW toolchain.

## Prerequisites

- Docker
- Docker Compose

## Building

### ARM64 Build (Recommended for RG35XX devices)

```bash
docker-compose up --build
```

This will build the Pixospritz game engine and kernel modules for ARM64 architecture.

### x86_64 Build (For testing on x86 systems)

```bash
./pixospritz-rg35xx-knulli/build.sh
```

## Output

Compiled files will be placed in `pixospritz-rg35xx-knulli/output/`.

## Usage

After building, copy the contents of the output directory to your RG35XX device and run the `pixospritz.sh` script.

## Acknowledgments

This build system is based on the [original build system](https://github.com/jamesMcMeex/m8c-rg35xx-knulli) by James McMeex, adapted for building the Pixospritz game engine.
