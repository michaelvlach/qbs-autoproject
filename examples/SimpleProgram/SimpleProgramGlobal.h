#pragma once

#if defined(_WIN32)
#define EXPORT __declspec(dllexport)
#define IMPORT __declspec(dllimport)
#else
#define EXPORT
#define IMPORT
#endif

#if defined(SIMPLEPROGRAM_LIB)
#define SIMPLEPROGRAM_SHARED EXPORT
#else
#define SIMPLEPROGRAM_SHARED IMPORT
#endif
