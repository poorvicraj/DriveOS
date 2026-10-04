#!/usr/bin/env bash
# ==============================================================================
# DriveOS Automated Installation & Setup Engine for Linux (Native / WSL2)
# ==============================================================================

set -e

echo -e "\033[1;36m============================================================\033[0m"
echo -e "\033[1;32m       DriveOS Automated Installation & Setup Engine        \033[0m"
echo -e "\033[1;36m============================================================\033[0m"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# 1. Install System Dependencies
if command -v apt-get &> /dev/null; then
    echo -e "\n\033[1;33m[1/5] Installing required development dependencies (apt)...\033[0m"
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        cmake \
        ninja-build \
        qt6-base-dev \
        qt6-declarative-dev \
        libqt6svg6-dev \
        qml6-module-qtquick-controls \
        qml6-module-qtquick-layouts \
        qml6-module-qtquick-shapes \
        qml6-module-qtquick-templates \
        can-utils \
        python3 \
        python3-pip
elif command -v pacman &> /dev/null; then
    echo -e "\n\033[1;33m[1/5] Installing dependencies via pacman...\033[0m"
    sudo pacman -S --needed --noconfirm base-devel cmake ninja qt6-base qt6-declarative qt6-svg can-utils python python-pip
else
    echo -e "\n\033[1;33m[1/5] Package manager not recognized. Please ensure Qt 6, CMake, and Ninja are installed.\033[0m"
fi

# 2. Python CAN Tooling
echo -e "\n\033[1;33m[2/5] Ensuring python cantools is installed...\033[0m"
pip3 install --quiet --upgrade cantools || true

# 3. Optional Virtual CAN (vcan0) Setup
echo -e "\n\033[1;33m[3/5] Setting up virtual CAN interface (vcan0)...\033[0m"
if sudo modprobe vcan 2>/dev/null; then
    if ! ip link show vcan0 &>/dev/null; then
        sudo ip link add dev vcan0 type vcan
        sudo ip link set up vcan0
        echo "  -> vcan0 interface active."
    else
        echo "  -> vcan0 interface already exists."
    fi
else
    echo "  -> vcan kernel module not available (WSL2 without custom kernel or non-root). Skipping."
fi

# 4. Configure & Build
echo -e "\n\033[1;33m[4/5] Configuring CMake and compiling DriveOS...\033[0m"
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
cmake --build build --parallel

# 5. Run Automated Tests
echo -e "\n\033[1;33m[5/5] Executing automated test suite...\033[0m"
QT_QPA_PLATFORM=offscreen ctest --test-dir build --output-on-failure

# Create Launch Script
cat << 'EOF' > launch_driveos.sh
#!/usr/bin/env bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$PROJECT_ROOT/build/driveos" "$@"
EOF
chmod +x launch_driveos.sh

echo -e "\n\033[1;32m============================================================\033[0m"
echo -e "\033[1;32m         DriveOS Installation & Setup Completed!            \033[0m"
echo -e "\033[1;32m============================================================\033[0m"
echo -e "Launch DriveOS Cockpit with:"
echo -e "  \033[1;33m./launch_driveos.sh\033[0m"
echo -e "  \033[1;33m./build/driveos --can --interface=vcan0\033[0m"
echo -e "\033[1;32m============================================================\033[0m\n"
