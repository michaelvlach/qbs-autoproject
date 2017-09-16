#pragma once

#ifdef WIN32
#  define EXPORT __declspec(dllimport)
#  define IMPORT __declspec(dllexport)
#else
#  define EXPORT
#  define IMPORT
#endif
