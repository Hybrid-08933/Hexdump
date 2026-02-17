# Hexdump Utility

## Overview

Minimal hexdump utility in x86_64 assembly for Linux using direct syscalls. Formats file contents into hex + ASCII columns with buffered output and no libc dependencies. Designed to explore hot-loop performance and syscall overhead.

---

## Build, Run, & Benchmark

Run:
```bash
make
./build/hexdump <file>
```

Benchmark:
```bash
make benchmark SIZE=512 ITER=5
```
Parameters (optional):
- SIZE - test file size in MB (default: 512)
- ITER - number of benchmark iterations (default: 5)

---

## Key Characteristics

* Implemented entirely in **x86_64 assembly** (NASM)
* Uses **direct Linux syscalls (`open`, `read`, `write`, `exit`)**
* Processes input in **64 KB chunks** to reduce syscall overhead
* Formats output into fixed-width hexadecimal and ASCII columns
* Minimal runtime dependencies
* Built using **Make** and linked with **GNU ld**

---

## Performance Characteristics

Benchmarked with `perf stat -r 5` on a 512MB file with stdout redirected to /dev/null.

Observed:
- ~5.2 IPC (sustained across runs)
- near-zero branch mispredicts
- negligible frontend stalls
- ~0.5% timing variance across runs
- compute-bound when input is page-cached

Hot loop designed for predictable control flow and minimal syscall overhead.

---

## Example Output
```
sample.txt:
48  65  6C  6C  6F  2C  20  57  6F  72  6C  64  21  0A  3C  20    Hello, World!.< 
3E  20  21  20  5F  20  2D  20  2B  20  40  20  23  20  24  20    > ! _ - + @ # $ 
25  0A  5E  20  26  20  2A  20  28  20  29  20  5B  20  5D  20    %.^ & * ( ) [ ] 
7B  20  7D  20  5C  0A  7C  20  27  20  22  20  3A  20  3B  20    { } \.| ' " : ; 
2C  20  2E  20  2F  20  3F  20  60  0A                            , . / ? `.
```

---

## High-Level Design

* At a high level, the program:

  1. Accepts a filename as a command-line argument
  2. Opens the file using a Linux syscall
  3. Reads data into a fixed-size buffer
  4. Converts each byte into hexadecimal and printable ASCII
  5. Writes formatted output using buffered `write` syscalls
  6. Repeats until EOF, then exits cleanly

* The implementation deliberately avoids libc abstractions to keep control over register usage, memory layout, and syscall boundaries.
---

## Limitations

* Only basic argument validation is performed
* No offset column is included
* Full error reporting for I/O failures is not implemented
* Not intended as a drop-in replacement for `hexdump` or `xxd`

---

## Notes on Implementation

* Output is buffered to reduce syscall frequency on large inputs
* Hexadecimal and ASCII conversion use a lookup table rather than bit manipulation
* The formatting loop is structured to keep control flow predictable
* Debugging and validation were performed using `gdb` and `perf`

---

## Future Improvements

* Add a offset column
* Improve syscall error handling
* Support configurable output width
* Experiment with SIMD-based formatting for larger throughput

---
