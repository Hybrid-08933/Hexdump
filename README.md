# Hexdump Utility

## Overview

This project is a **low-level hexdump utility written in x86_64 assembly for Linux**. The primary goal of this project was to learn **assembly programming, Linux syscalls, and low-level file I/O**, rather than to replicate all features of standard hexdump tools.

The utility reads files in fixed-size chunks and displays their contents in **hexadecimal and ASCII columns**, including the filename.

---

## Features

* Written in **x86_64 assembly** using **NASM** and linked with **GNU Linker**
* Uses **Linux syscalls** (`sys_open`, `sys_read`, `sys_write`, `sys_exit`) for file operations
* Reads files in **512-byte chunks** for efficient processing
* Prints **hexadecimal bytes and printable ASCII characters side by side**, including the filename
* Exits cleanly at **EOF**
* Handles **basic error checking** for missing filename input
* Built with **Make** for easy assembly and linking

---

## Sample Output
```
sample.txt:
48  65  6C  6C  6F  2C  20  57  6F  72  6C  64  21  0A  3C  20    Hello, World!.< 
3E  20  21  20  5F  20  2D  20  2B  20  40  20  23  20  24  20    > ! _ - + @ # $ 
25  0A  5E  20  26  20  2A  20  28  20  29  20  5B  20  5D  20    %.^ & * ( ) [ ] 
7B  20  7D  20  5C  0A  7C  20  27  20  22  20  3A  20  3B  20    { } \.| ' " : ; 
2C  20  2E  20  2F  20  3F  20  60  0A                            , . / ? `.
```

---

## How It Works (High-Level)

* The program runs by:

  1. Accepting a **filename** as a command-line argument
  2. Opening the file with **sys_open**
  3. Reading the file in **512-byte chunks** using **sys_read**
  4. Printing the **hex bytes and ASCII characters side by side** with **sys_write**
  5. Repeating until EOF, then closing the file and exiting with **sys_exit**

* If no filename is provided, the program prints an error message and exits gracefully.
* Focuses on **low-level memory access and syscall usage**, rather than full error handling or extra features.

---

## Compilation & Execution

```bash
make
./build/hexdump file
```

---

## Known Limitations

* Only handles missing filename errors; other file I/O errors are not handled
* Output does not include offset column like standard hexdump tools
* Focused on learning assembly and syscalls, not production-ready features

---

## Learning Objectives & Takeaways

Through this project, I learned:

* Basics of x86_64 assembly programming
* Using Linux syscalls for file operations
* Handling buffers and memory access at a low level
* Formatting output in hexadecimal and ASCII
* Managing builds using NASM, GNU Linker, and Make

---

## Future Improvements

* Add a offset column
* Use buffered output
* Use a translation table instead of bit-shifting to convert binary to hex
* Handle potential syscall errors
* Use SIMD instructions to parallize processing (advanced)

---

## Disclaimer

This project was created **for learning purposes** by a student new to assembly programming. The emphasis was on understanding concepts rather than producing a feature-complete utility program.
