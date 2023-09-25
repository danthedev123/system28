/*
    * start.cpp
    * Entry (_start)
    * Created 01/09/23 DanielH
*/
#include <early/bootloader_data.hpp>
#include <terminal/terminal.hpp>
#include <hal/cpu.hpp>
#include <mm/pmm.hpp>
#include <hal/cpu/smp/smp.hpp>
#include <hal/vmm.hpp>
#include <mm/mem.hpp>
#include <hal/acpi.hpp>
#include <hal/cpu/interrupt/apic.hpp>
#include <mm/heap.hpp>
#include <libs/kernel.hpp>
#include <logo.h>

BootloaderData GlobalBootloaderData;

extern "C" void _start()
{
    GlobalBootloaderData = GetBootloaderData();

    limine_framebuffer fb = *GlobalBootloaderData.fbData.framebuffers[0];
    uint32_t *fb_ptr = (uint32_t *)fb.address;

    Kernel::CPU::Initialize();
    Kernel::Init::InitializeFlanterm(fb_ptr, fb.width, fb.height, fb.pitch);
    Kernel::Mem::InitializePMM(GlobalBootloaderData.memmap);
    Kernel::Print(System28ASCII());
    Kernel::Log(KERNEL_LOG_SUCCESS, "Kernel initializing...\n");
    Kernel::Log(KERNEL_LOG_INFO, "Kernel: Number of CPUs: %d\n", GlobalBootloaderData.smp.cpu_count);
    Kernel::VMM::InitPaging(GlobalBootloaderData.memmap, GlobalBootloaderData.kernel_addr, GlobalBootloaderData.hhdm_response.offset);
    Kernel::ACPI::SetRSDP((uintptr_t)GlobalBootloaderData.rsdp_response.address);
    Kernel::CPU::SMPSetup(*GlobalBootloaderData.smp.cpus, GlobalBootloaderData.smp.cpu_count);
    Kernel::CPU::InitializeMADT();
    Kernel::Mem::InitializeHeap(0x1000 * 10);
    Kernel::CPU::SetupAllCPUs();

    while (true) {
        Kernel::CPU::Halt();
    }
}