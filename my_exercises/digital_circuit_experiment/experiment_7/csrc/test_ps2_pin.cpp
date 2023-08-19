#include <nvboard.h>
#include <Vtest_ps2_pin.h>

#define TOPNAME Vtest_ps2_pin

static TOPNAME* top;

void nvboard_bind_all_pins(TOPNAME* top);

int main(){
    
    top = new TOPNAME;

    nvboard_bind_all_pins(top);
    nvboard_init();

    while (1)
    {   
        nvboard_update();
        top->eval();
    }

    delete top;
}

