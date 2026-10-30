################################################################################
# QPUIncGen
#
# MLIR QPU dialect generated includes.
################################################################################

add_custom_target(QPUIncGen)

# Attributes, Dialect, Operations and Types.
add_subdirectory(IR)
# Passes
add_subdirectory(Transforms)

add_subdirectory(Interfaces)
