cmake_minimum_required(VERSION 3.22)
project(DriveOS VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Enable automatic MOC and RCC for Qt Quick / QML
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Compiler Warnings
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(-Wall -Wextra -Wpedantic -Wno-unused-parameter)
elseif(MSVC)
    add_compile_options(/W4 /permissive-)
endif()

# Global Include Directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/app)

# --- Find Qt 6 Framework ---
find_package(Qt6 COMPONENTS Core Gui Quick Qml QUIET)

if(Qt6_FOUND)
    message(STATUS "Found Qt 6: ${Qt6_DIR}")

    set(APP_SOURCES
        app/main.cpp
        app/presentation/NavigationController.cpp
        app/presentation/NavigationController.hpp
        app/presentation/BaseViewModel.cpp
        app/presentation/BaseViewModel.hpp
        app/presentation/HomeViewModel.cpp
        app/presentation/HomeViewModel.hpp
        app/presentation/ShellViewModel.cpp
        app/presentation/ShellViewModel.hpp
        app/presentation/MediaViewModel.cpp
        app/presentation/MediaViewModel.hpp
        app/presentation/ClimateViewModel.cpp
        app/presentation/ClimateViewModel.hpp
        app/presentation/VehicleViewModel.cpp
        app/presentation/VehicleViewModel.hpp
        app/presentation/NavigationViewModel.cpp
        app/presentation/NavigationViewModel.hpp
        app/domain/VehicleState.hpp
        app/domain/VehicleStateManager.hpp
        app/domain/SafetyPolicy.hpp
        app/domain/FaultModel.hpp
        app/domain/VehicleService.hpp
        app/domain/ClimateService.hpp
        app/domain/MediaService.hpp
        app/domain/NavigationService.hpp
        app/vehicle/VehicleDataInterface.hpp
        app/vehicle/SimulatedVehicleBackend.cpp
        app/vehicle/SimulatedVehicleBackend.hpp
        app/vehicle/CANVehicleBackend.cpp
        app/vehicle/CANVehicleBackend.hpp
        app/can/CanTypes.hpp
        app/can/CanFrameCodec.cpp
        app/can/CanFrameCodec.hpp
        app/can/ICanTransport.hpp
        app/can/SocketCanTransport.cpp
        app/can/SocketCanTransport.hpp
        app/can/MockCanTransport.cpp
        app/can/MockCanTransport.hpp
        app/diagnostics/DiagnosticService.hpp
        app/diagnostics/DiagnosticService.cpp
        app/qml/qml.qrc
    )

    add_executable(driveos ${APP_SOURCES})
    target_link_libraries(driveos PRIVATE Qt6::Core Qt6::Gui Qt6::Quick Qt6::Qml)
    target_include_directories(driveos PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/app)
else()
    message(STATUS "Qt 6 not found on host system. Application target will be built once Qt toolchain is configured.")
endif()

# --- Unit Tests ---
option(BUILD_TESTS "Build DriveOS unit test suite" ON)

if(BUILD_TESTS)
    enable_testing()
    add_executable(driveos_foundation_tests
        tests/unit/main.cpp
        tests/unit/test_foundation.cpp
        tests/unit/test_can.cpp
        tests/unit/test_diagnostics.cpp
        tests/unit/test_viewmodels.cpp
        tests/unit/test_qml_navigation.cpp
        app/presentation/BaseViewModel.cpp
        app/presentation/NavigationController.cpp
        app/presentation/ClimateViewModel.cpp
        app/presentation/VehicleViewModel.cpp
        app/presentation/MediaViewModel.cpp
        app/presentation/HomeViewModel.cpp
        app/presentation/ShellViewModel.cpp
        app/presentation/NavigationViewModel.cpp
        app/vehicle/SimulatedVehicleBackend.cpp
        app/vehicle/CANVehicleBackend.cpp
        app/can/CanFrameCodec.cpp
        app/can/SocketCanTransport.cpp
        app/can/MockCanTransport.cpp
        app/diagnostics/DiagnosticService.cpp
        app/qml/qml.qrc
    )
    target_include_directories(driveos_foundation_tests PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/app
    )

    if(Qt6_FOUND)
        target_link_libraries(driveos_foundation_tests PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick)
    endif()

    find_package(GTest QUIET)
    if(GTest_FOUND)
        target_link_libraries(driveos_foundation_tests PRIVATE GTest::gtest GTest::gtest_main)
    else()
        target_include_directories(driveos_foundation_tests PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/tests/mocks)
    endif()

    add_test(NAME DriveOSFoundationTests COMMAND driveos_foundation_tests)
endif()
