# Copyright (c) 2017-2024, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level LICENSE file for details
# 
# SPDX-License-Identifier: (BSD-3-Clause)
#------------------------------------------------------------------------------
# Sets up targets and macros associated with documentation
#------------------------------------------------------------------------------

add_custom_target(${BLT_DOCS_TARGET_NAME})

if(DOXYGEN_FOUND)
    add_custom_target(doxygen_docs)
    add_dependencies(${BLT_DOCS_TARGET_NAME} doxygen_docs)
endif()

if(SPHINX_FOUND)
    add_custom_target(sphinx_docs)
    add_dependencies(${BLT_DOCS_TARGET_NAME} sphinx_docs)
endif()


##------------------------------------------------------------------------------
## blt_add_doxygen_target(TARGET [doxygen_target_name])
##
## Creates a build target for invoking doxygen to generate docs
##------------------------------------------------------------------------------
macro(blt_add_doxygen_target)
    set(_doxygen_options)
    set(_doxygen_single_value_args TARGET)
    set(_doxygen_multi_value_args)
    cmake_parse_arguments(DOXYGEN
                          "${_doxygen_options}"
                          "${_doxygen_single_value_args}"
                          "${_doxygen_multi_value_args}"
                          ${ARGN})

    if(DOXYGEN_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "blt_add_doxygen_target received unexpected arguments: ${DOXYGEN_UNPARSED_ARGUMENTS}")
    endif()

    # add a target to generate API documentation with Doxygen
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile @ONLY)
    add_custom_target(${DOXYGEN_TARGET}
                     ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
                     WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                     COMMENT "Generating API documentation with Doxygen for ${DOXYGEN_TARGET} target" VERBATIM)

    add_dependencies(doxygen_docs ${DOXYGEN_TARGET})

    install(CODE "execute_process(COMMAND ${CMAKE_BUILD_TOOL} ${DOXYGEN_TARGET} WORKING_DIRECTORY \"${CMAKE_CURRENT_BINARY_DIR}\")")

    install(DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/html" 
            DESTINATION docs/doxygen/${DOXYGEN_TARGET} OPTIONAL)

endmacro(blt_add_doxygen_target)


##------------------------------------------------------------------------------
## blt_add_sphinx_target(TARGET       [sphinx_target_name]
##                       SOURCE_DIR   [source_dir]
##                       CONF_DIR     [conf_dir]
##                       DEPENDS      [dep1 ...])
##
## Creates a build target for invoking sphinx to generate docs
##------------------------------------------------------------------------------
macro(blt_add_sphinx_target)
    set(_sphinx_options)
    set(_sphinx_single_value_args
        TARGET
        SOURCE_DIR
        CONF_DIR)
    set(_sphinx_multi_value_args
        DEPENDS)
    cmake_parse_arguments(SPHINX
                          "${_sphinx_options}"
                          "${_sphinx_single_value_args}"
                          "${_sphinx_multi_value_args}"
                          ${ARGN})

    if(SPHINX_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "blt_add_sphinx_target received unexpected arguments: ${SPHINX_UNPARSED_ARGUMENTS}")
    endif()

    if(NOT SPHINX_SOURCE_DIR)
        set(SPHINX_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()

    # Path to Sphinx conf.py configuration file
    if(NOT SPHINX_CONF_DIR)
        set(SPHINX_CONF_DIR "${SPHINX_SOURCE_DIR}")
    endif()

    # Sphinx cache with pickled ReST documents
    set(SPHINX_DOCTREE_DIR "${CMAKE_CURRENT_BINARY_DIR}/_doctrees")

    # HTML output directory
    set(SPHINX_HTML_DIR "${CMAKE_CURRENT_BINARY_DIR}/html")

    # support both direct use of a conf.py file and a cmake-configured
    # sphinx input file (conf.py.in). The cmake-configured input file is
    # preferred when both exist.
    if(EXISTS "${SPHINX_CONF_DIR}/conf.py.in")
        set(new_conf_dir_ "${CMAKE_CURRENT_BINARY_DIR}/_conf")
        configure_file("${SPHINX_CONF_DIR}/conf.py.in"
                       "${new_conf_dir_}/conf.py"
                       @ONLY)
        set(SPHINX_CONF_DIR "${new_conf_dir_}")
        unset(new_conf_dir_)
    endif()

    add_custom_target(${SPHINX_TARGET}
        COMMAND ${SPHINX_EXECUTABLE}
                -q
                -b html
                -c "${SPHINX_CONF_DIR}"
                -d "${SPHINX_DOCTREE_DIR}"
                "${SPHINX_SOURCE_DIR}"
                "${SPHINX_HTML_DIR}"
        COMMENT "Building HTML documentation with Sphinx for ${SPHINX_TARGET} target"
        DEPENDS ${SPHINX_DEPENDS})

    # hook our new target into the docs dependency chain
    add_dependencies(sphinx_docs ${SPHINX_TARGET})

    ######
    # This snippet makes sure if we do a make install w/o the optional "docs"
    # target built, it will be built during the install process.
    ######

    install(CODE "execute_process(COMMAND ${CMAKE_BUILD_TOOL} ${SPHINX_TARGET} WORKING_DIRECTORY \"${CMAKE_CURRENT_BINARY_DIR}\")")

    install(DIRECTORY "${SPHINX_HTML_DIR}" 
            DESTINATION "docs/sphinx/${SPHINX_TARGET}" OPTIONAL)

endmacro(blt_add_sphinx_target)
