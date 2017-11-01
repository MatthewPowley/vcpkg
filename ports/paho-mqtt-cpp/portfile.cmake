if (VCPKG_CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
    message(FATAL_ERROR "paho-mqtt-cpp does not currently support UWP")
endif()

# There is currently a problem with the upstream project that prevents
# the library from being built correctly as using dynamic linkage (DLL).
# https://github.com/eclipse/paho.mqtt.cpp/issues/117
if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    message(FATAL_ERROR "paho-mqtt-cpp does not currently support being built using dynamic linking")
endif()

include(vcpkg_common_functions)

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO eclipse/paho.mqtt.cpp
  REF v1.0.0
  SHA512 620bbe9dfe7d278aec1bdcafe6408bc4de0b1043509d5e8ceab9ab672543603c9c0dc2adad8a9078623a36c94cb7586e1ffa6bcf40067f965fb102a771eae17e
  HEAD_REF master
)

# Set flags for building static or shared libraries
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" PAHO_BUILD_STATIC)
if(PAHO_BUILD_STATIC)
  set(PAHO_BUILD_SHARED 0)
else()
  set(PAHO_BUILD_SHARED 1)
endif()


# Paho-mqtt-cpp does not have an elegent CMake system and struggles to create
# a Visual Studio solution for both Debug and Release for Visual Studio.
# However as vcpkg creates each configuration seperately we can work around this.
get_filename_component(PAHO_VCPKG_PACKAGE_DIR
  "${CURRENT_PACKAGES_DIR}/../paho-mqtt_${TARGET_TRIPLET}"
  REALPATH
  BASE_DIR "${CURRENT_PACKAGES_DIR}")

set(PAHO_MQTT_LIBRARY_DEBUG "${PAHO_VCPKG_PACKAGE_DIR}/debug/lib/paho-mqtt3as.lib")
set(PAHO_MQTT_LIBRARY_RELEASE "${PAHO_VCPKG_PACKAGE_DIR}/lib/paho-mqtt3as.lib")

if (CMAKE_BUILD_TYPE EQUAL Debug)
	set(PAHO_MQTT_C_LIB "${PAHO_MQTT_LIBRARY_DEBUG}")
else()
	set(PAHO_MQTT_C_LIB "${PAHO_MQTT_LIBRARY_RELEASE}")
endif()

vcpkg_configure_cmake(
  SOURCE_PATH ${SOURCE_PATH}
  PREFER_NINJA
  OPTIONS
    -DPAHO_BUILD_DOCUMENTATION=FALSE
    -DPAHO_BUILD_SAMPLES=FALSE
    -DPAHO_WITH_SSL=TRUE
    -DPAHO_BUILD_STATIC=${PAHO_BUILD_STATIC}
    -DPAHO_BUILD_SHARED=${PAHO_BUILD_SHARED}
    -DPAHO_MQTT_C_PATH=${PAHO_VCPKG_PACKAGE_DIR}
    -DPAHO_MQTT_C_LIB=${PAHO_MQTT_C_LIB}
)

vcpkg_install_cmake()

# Remove duplicate header files
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

vcpkg_copy_pdbs()

# Handle copyright
file(INSTALL ${SOURCE_PATH}/about.html DESTINATION ${CURRENT_PACKAGES_DIR}/share/paho-mqtt-cpp RENAME copyright)
