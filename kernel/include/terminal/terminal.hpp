/*
    * terminal.hpp
    * Declares terminal functions
    * Created 01/09/23 DanielH
*/

#pragma once
#include <stdint.h>

enum KernelLogType {
    KERNEL_LOG_SUCCESS,
    KERNEL_LOG_FAIL,
    KERNEL_LOG_INFO,
    KERNEL_LOG_PRINTONLY
};

namespace Kernel {
    namespace Init {
        void InitializeFlanterm(uint32_t *framebuffer, int width, int height, int pitch);
    }

    void Print(const char* string);
    void Log(KernelLogType type, const char *format, ...);
}