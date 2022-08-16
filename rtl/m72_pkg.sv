package m72_pkg;

    typedef struct packed {
        bit [24:0] base_addr;
        bit reorder_64;
        bit [1:0] bram_cs;
    } region_t;

    parameter region_t REGION_CPU_ROM = '{ base_addr:'h000000, reorder_64:0, bram_cs:2'b00 };
    parameter region_t REGION_SPRITE =  '{ base_addr:'h100000, reorder_64:1, bram_cs:2'b00 };
    parameter region_t REGION_BG_A =    '{ base_addr:'h200000, reorder_64:0, bram_cs:2'b00 };
    parameter region_t REGION_BG_B =    '{ base_addr:'h300000, reorder_64:0, bram_cs:2'b00 };
    parameter region_t REGION_MCU =     '{ base_addr:'h000000, reorder_64:0, bram_cs:2'b01 };
    parameter region_t REGION_SAMPLES = '{ base_addr:'h000000, reorder_64:0, bram_cs:2'b10 };

    parameter region_t LOAD_REGIONS[6] = '{
        REGION_CPU_ROM,
        REGION_SPRITE,
        REGION_BG_A,
        REGION_BG_B,
        REGION_MCU,
        REGION_SAMPLES
    };

    parameter region_t REGION_CPU_RAM = '{ 'h400000, 0, 2'b00 };

    typedef enum logic[7:0] {
        M72_RTYPE,
        M72_GALLOP
    } board_type_t;

endpackage