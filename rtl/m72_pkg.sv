package m72_pkg;

    typedef struct packed {
        bit [24:0] base_addr;
        bit reorder_64;
    } region_t;

    parameter region_t REGION_CPU_ROM = '{ base_addr:'h000000, reorder_64:0 };
    parameter region_t REGION_SPRITE =  '{ 'h100000, 1 };
    parameter region_t REGION_BG_A =    '{ 'h200000, 0 };
    parameter region_t REGION_BG_B =    '{ 'h300000, 0 };

    parameter region_t LOAD_REGIONS[4] = '{
        REGION_CPU_ROM,
        REGION_SPRITE,
        REGION_BG_A,
        REGION_BG_B
    };

    parameter region_t REGION_CPU_RAM = '{ 'h400000, 0 };

    typedef enum logic[7:0] {
        M72_RTYPE,
        M72_GALLOP
    } board_type_t;

endpackage