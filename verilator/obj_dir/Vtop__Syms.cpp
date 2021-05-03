// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vtop__Syms.h"
#include "Vtop.h"



// FUNCTIONS
Vtop__Syms::Vtop__Syms(Vtop* topp, const char* namep)
    // Setup locals
    : __Vm_namep(namep)
    , __Vm_didInit(false)
    // Setup submodule names
{
    // Pointer to top level
    TOPp = topp;
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOPp->__Vconfigure(this, true);
    // Setup scopes
    __Vscope_TOP.configure(this, name(), "TOP", "TOP", VerilatedScope::SCOPE_OTHER);
    __Vscope_top.configure(this, name(), "top", "top", VerilatedScope::SCOPE_OTHER);
    // Setup export functions
    for (int __Vfinal=0; __Vfinal<2; __Vfinal++) {
        __Vscope_TOP.varInsert(__Vfinal,"VGA_B", &(TOPp->VGA_B), VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,1 ,7,0);
        __Vscope_TOP.varInsert(__Vfinal,"VGA_G", &(TOPp->VGA_G), VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,1 ,7,0);
        __Vscope_TOP.varInsert(__Vfinal,"VGA_R", &(TOPp->VGA_R), VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,1 ,7,0);
        __Vscope_TOP.varInsert(__Vfinal,"clk_12", &(TOPp->clk_12), VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0);
        __Vscope_TOP.varInsert(__Vfinal,"inputs", &(TOPp->inputs), VLVT_UINT16,VLVD_IN|VLVF_PUB_RW,1 ,11,0);
        __Vscope_TOP.varInsert(__Vfinal,"reset", &(TOPp->reset), VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0);
        __Vscope_top.varInsert(__Vfinal,"VGA_B", &(TOPp->top__DOT__VGA_B), VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_top.varInsert(__Vfinal,"VGA_G", &(TOPp->top__DOT__VGA_G), VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_top.varInsert(__Vfinal,"VGA_R", &(TOPp->top__DOT__VGA_R), VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_top.varInsert(__Vfinal,"clk_12", &(TOPp->top__DOT__clk_12), VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_top.varInsert(__Vfinal,"inputs", &(TOPp->top__DOT__inputs), VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,11,0);
        __Vscope_top.varInsert(__Vfinal,"joystick", &(TOPp->top__DOT__joystick), VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
        __Vscope_top.varInsert(__Vfinal,"led", &(TOPp->top__DOT__led), VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,3,0);
        __Vscope_top.varInsert(__Vfinal,"playerinput", &(TOPp->top__DOT__playerinput), VLVT_UINT16,VLVD_NODIR|VLVF_PUB_RW,1 ,9,0);
        __Vscope_top.varInsert(__Vfinal,"reset", &(TOPp->top__DOT__reset), VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_top.varInsert(__Vfinal,"trakball", &(TOPp->top__DOT__trakball), VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,7,0);
    }
}
