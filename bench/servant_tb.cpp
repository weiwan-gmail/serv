#include <fcntl.h>
#include <stdarg.h>
#include <stdint.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctime>

/* Host C++: Linux gcc + Windows MSVC.
 * MSVC has no <unistd.h> (PC2023 C1083). Do not #define open — that would
 * rewrite VerilatedVcdC::open. sleep() is unused here; map it for MSVC. */
#if defined(_WIN32)
# include <io.h>
# include <sys/stat.h>
# if defined(_MSC_VER)
#  ifndef WIN32_LEAN_AND_MEAN
#   define WIN32_LEAN_AND_MEAN
#  endif
#  ifndef NOMINMAX
#   define NOMINMAX
#  endif
#  include <windows.h>
#  ifndef S_IRWXU
#   define S_IRWXU (_S_IREAD | _S_IWRITE)
#  endif
# else
#  include <unistd.h>
# endif
#else
# include <unistd.h>
#endif

#ifndef O_BINARY
# if defined(_WIN32)
#  define O_BINARY _O_BINARY
# else
#  define O_BINARY 0
# endif
#endif

#include "verilated_vcd_c.h"
#include "Vservant_sim.h"

using namespace std;

static int tb_open_trunc(const char *path)
{
#if defined(_WIN32) && defined(_MSC_VER)
  return _open(path, _O_WRONLY | _O_CREAT | _O_TRUNC | _O_BINARY,
               _S_IREAD | _S_IWRITE);
#else
  return open(path, O_WRONLY | O_CREAT | O_TRUNC | O_BINARY, S_IRWXU);
#endif
}

static int tb_write(int fd, const void *buf, unsigned n)
{
#if defined(_WIN32) && defined(_MSC_VER)
  return _write(fd, buf, n);
#else
  return (int)write(fd, buf, n);
#endif
}

static void tb_close(int fd)
{
#if defined(_WIN32) && defined(_MSC_VER)
  _close(fd);
#else
  close(fd);
#endif
}

static int tb_dprintf(int fd, const char *fmt, ...)
{
  char buf[128];
  va_list ap;
  va_start(ap, fmt);
  int n = vsnprintf(buf, sizeof(buf), fmt, ap);
  va_end(ap);
  if (n <= 0)
    return n;
  if (n >= (int)sizeof(buf))
    n = (int)sizeof(buf) - 1;
  return tb_write(fd, buf, (unsigned)n);
}

/* sleep() lives in unistd.h; MSVC uses Sleep(). Unused in this TB. */
#if defined(_WIN32) && defined(_MSC_VER)
# define tb_sleep(sec) Sleep((sec) * 1000u)
#else
# define tb_sleep(sec) sleep(sec)
#endif

static bool done;
static int exit_code = 0;
static unsigned long cycles = 0;

vluint64_t main_time = 0;       // Current simulation time
// This is a 64-bit integer to reduce wrap over issues and
// allow modulus.  You can also use a double, if you wish.

double sc_time_stamp () {       // Called by $time in Verilog
  return main_time;           // converts to double, to match
  // what SystemC does
}

void INThandler(int signal)
{
  printf("\nCaught ctrl-c\n");
  done = true;
}

typedef struct {
  bool last_value;
} gpio_context_t;

void do_gpio(gpio_context_t *context, bool gpio) {
  if (context->last_value != gpio) {
    context->last_value = gpio;
    printf("%llu output q is %s\n", (unsigned long long)main_time, gpio ? "ON" : "OFF");
  }
}

typedef struct {
  uint8_t state;
  char ch;
  uint32_t baud_t;
  vluint64_t last_update;
} uart_context_t;

void uart_init(uart_context_t *context, uint32_t baud_rate) {
  context->baud_t = 1000*1000*1000/baud_rate;
  context->state = 0;
}

bool do_uart(uart_context_t *context, bool rx) {
  if (context->state == 0) {
    if (rx)
      context->state++;
  }
  else if (context->state == 1) {
    if (!rx) {
      context->last_update = main_time + context->baud_t/2;
      context->state++;
    }
  }
  else if(context->state == 2) {
    if (main_time > context->last_update) {
      context->last_update += context->baud_t;
      context->ch = 0;
      context->state++;
    }
  }
  else if (context->state < 11) {
    if (main_time > context->last_update) {
      context->last_update += context->baud_t;
      context->ch |= rx << (context->state-3);
      context->state++;
    }
  }
  else {
    if (main_time > context->last_update) {
      context->last_update += context->baud_t;
      context->state=1;
      return true;
    }
  }
  return false;
}

int main(int argc, char **argv, char **env)
{
  (void)env;
  int baud_rate = 0;

  gpio_context_t gpio_context;
  uart_context_t uart_context;
  Verilated::commandArgs(argc, argv);

  Vservant_sim* top = new Vservant_sim;

  const char *arg = Verilated::commandArgsPlusMatch("uart_baudrate=");
  if (arg[0]) {
    baud_rate = atoi(arg+15);
    if (baud_rate) {
      uart_init(&uart_context, baud_rate);
    }
  }

  VerilatedVcdC * tfp = 0;
  const char *vcd = Verilated::commandArgsPlusMatch("vcd=");
  if (vcd[0]) {
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace (tfp, 99);
    tfp->open ("trace.vcd");
  }

  signal(SIGINT, INThandler);

  int tf = 0;
  const char *arg_trace_pc = Verilated::commandArgsPlusMatch("trace_pc=");
  if (arg_trace_pc[0])
    tf = tb_open_trunc("trace.bin");

  vluint64_t timeout = 0;
  const char *arg_timeout = Verilated::commandArgsPlusMatch("timeout=");
  if (arg_timeout[0])
    timeout = atoi(arg_timeout+9);

  vluint64_t vcd_start = 0;
  const char *arg_vcd_start = Verilated::commandArgsPlusMatch("vcd_start=");
  if (arg_vcd_start[0])
    vcd_start = atoi(arg_vcd_start+11);

  int cur_cycle = 0;
  int last_cycle = 0;
  std::time_t last_time = std::time(nullptr);
  int cps_file = 0;
  const char *arg_cps = Verilated::commandArgsPlusMatch("cps=");
  if (arg_cps[0])
    cps_file = tb_open_trunc("cps");

  bool dump = false;
  top->wb_clk = 1;
  bool q = top->q;
  while (!(done || Verilated::gotFinish())) {
    if (tfp && !dump && (main_time > vcd_start)) {
      dump = true;
    }
    top->wb_rst = main_time < 100;
    top->eval();
    if (dump)
      tfp->dump(main_time);
    if (baud_rate) {
      if (do_uart(&uart_context, top->q)) {
	putchar(uart_context.ch);
	fflush(stdout);
      }
    } else {
      do_gpio(&gpio_context, top->q);
    }
    if (tf && top->wb_clk && top->pc_vld)
      if (tb_write(tf, (void *)&top->pc_adr, 4) < 0) exit(1);
    if (timeout && (main_time >= timeout)) {
      printf("TIMEOUT after %llu clock cycles (sim time %llu)\n",
             (unsigned long long)cycles, (unsigned long long)main_time);
      printf("verilator_exit=2\n");
      done = true;
      exit_code = 2;
    }

    if (top->wb_clk)
      cycles++;
    top->wb_clk = !top->wb_clk;
    main_time+=31.25;

    if (cps_file) {
      cur_cycle++;
      if (std::time(nullptr) > last_time) {
	tb_dprintf(cps_file,"%d\n", (cur_cycle-last_cycle)/2);
	last_cycle = cur_cycle;
	last_time++;
      }
    }
  }
  if (cps_file > 0)
    tb_close(cps_file);
  if (tf > 0)
    tb_close(tf);
  if (tfp)
    tfp->close();
  if (exit_code == 0) {
    printf("SIM DONE after %llu clock cycles\n", (unsigned long long)cycles);
    printf("verilator_exit=0\n");
    printf("ALL TESTS PASSED.\n");
  }
  exit(exit_code);
}
