include(FetchContent)

set(ANTLR4_VERSION "4.12.0")

# -----------------------------------------------------------------------------
# ANTLR4 C++ runtime
# -----------------------------------------------------------------------------

# We only need the static runtime.
set(ANTLR_BUILD_CPP_TESTS OFF CACHE BOOL "" FORCE)
set(ANTLR_BUILD_SHARED    OFF CACHE BOOL "" FORCE)
set(ANTLR_BUILD_STATIC    ON  CACHE BOOL "" FORCE)
set(WITH_DEMO             OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
    antlr4
    URL
        "https://github.com/antlr/antlr4/archive/refs/tags/${ANTLR4_VERSION}.tar.gz"
    SOURCE_SUBDIR
        runtime/Cpp
)

FetchContent_MakeAvailable(antlr4)

# ANTLR 4.12 does not expose its runtime headers as usage requirements on
# antlr4_static. Add them so consumers only need to link against the target.
target_include_directories(antlr4_static
    SYSTEM PUBLIC
        "${antlr4_SOURCE_DIR}/runtime/Cpp/runtime/src"
)

# The downloaded ANTLR source tree contains the official FindANTLR.cmake.
list(PREPEND CMAKE_MODULE_PATH
    "${antlr4_SOURCE_DIR}/runtime/Cpp/cmake"
)

# -----------------------------------------------------------------------------
# ANTLR4 parser generator
# -----------------------------------------------------------------------------

# Allow users/distributions to override this:
#
#   cmake ... -DANTLR_EXECUTABLE=/path/to/antlr-4.12.0-complete.jar
#
set(ANTLR_EXECUTABLE
    ""
    CACHE FILEPATH
    "Path to the ANTLR4 complete JAR"
)

if(NOT ANTLR_EXECUTABLE)
    set(
        ANTLR_EXECUTABLE
        "${CMAKE_CURRENT_BINARY_DIR}/antlr-${ANTLR4_VERSION}-complete.jar"
    )

    if(NOT EXISTS "${ANTLR_EXECUTABLE}")
        message(STATUS "Downloading ANTLR ${ANTLR4_VERSION}")

        file(
            DOWNLOAD
            "https://www.antlr.org/download/antlr-${ANTLR4_VERSION}-complete.jar"
            "${ANTLR_EXECUTABLE}"
            TLS_VERIFY ON
            SHOW_PROGRESS
            STATUS ANTLR_DOWNLOAD_STATUS
        )

        list(GET ANTLR_DOWNLOAD_STATUS 0 ANTLR_DOWNLOAD_RESULT)

        if(NOT ANTLR_DOWNLOAD_RESULT EQUAL 0)
            list(GET ANTLR_DOWNLOAD_STATUS 1 ANTLR_DOWNLOAD_ERROR)
            message(
                FATAL_ERROR
                "Could not download ANTLR ${ANTLR4_VERSION}: "
                "${ANTLR_DOWNLOAD_ERROR}"
            )
        endif()
    endif()
endif()

# Provides antlr_target().
find_package(ANTLR ${ANTLR4_VERSION} EXACT REQUIRED)

if(FRONTEND_QASM)
    add_subdirectory(qasm)
endif()
