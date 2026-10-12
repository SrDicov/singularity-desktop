#include <features.h>
#if defined(__GLIBC__) && defined(__x86_64__)
__asm__ (".symver acosf,acosf@GLIBC_2.2.5");
__asm__ (".symver atan2f,atan2f@GLIBC_2.2.5");
__asm__ (".symver sqrtf,sqrtf@GLIBC_2.2.5");
#endif
#if defined(SIT_GLIB_MINOR) && __has_include(<glibconfig.h>)
#ifndef __GLIB_H_INSIDE__
#define __GLIB_H_INSIDE__
#define SIT_GLIB_INSIDE
#endif
#include <glibconfig.h>
#ifdef SIT_GLIB_INSIDE
#undef __GLIB_H_INSIDE__
#undef SIT_GLIB_INSIDE
#endif
#if GLIB_MINOR_VERSION > SIT_GLIB_MINOR
#undef GLIB_MINOR_VERSION
#define GLIB_MINOR_VERSION SIT_GLIB_MINOR
#undef GLIB_MICRO_VERSION
#define GLIB_MICRO_VERSION 0
#endif
#endif
