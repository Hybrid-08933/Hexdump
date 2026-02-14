# Hexdump Utility (mmap version)

## Overview

This branch implements an experimental version of the hexdump utility using `mmap()` to map the entire file into memory instead of reading it into a fixed-size buffer.  

- Memory mapping uses the `MAP_POPULATE` flag to pre-fault pages into RAM, reducing page faults during iteration.
- Output is still written using a **buffered write** mechanism, so the core formatting and output hot loop remain unchanged.
- This approach allows the program to handle files larger than a fixed buffer size and slightly improves execution consistency.

---

## Reproducing results

```bash
git checkout main
make benchmark

git checkout mmap
make benchmark
```

---

## Performance Comparison

Performance was measured on a 512 MB test file with stdout redirected to `/dev/null` to focus on CPU-bound formatting work.

### perf stat output (both reads and writes buffered)

```
perf stat -r 5 ./build/hexdump test512.bin > /dev/null

 Performance counter stats for './build/hexdump test512.bin' (5 runs):

            536.93 msec task-clock:u                     #    0.999 CPUs utilized               ( +-  2.46% )
                 0      context-switches:u               #    0.000 /sec                      
                 0      cpu-migrations:u                 #    0.000 /sec                      
                69      page-faults:u                    #  128.509 /sec                      
    10,670,458,289      instructions:u                   #    4.84  insn per cycle            
                                                  #    0.00  stalled cycles per insn     ( +-  0.00% )
     2,204,977,177      cycles:u                         #    4.107 GHz                         ( +-  0.17% )
         2,932,130      stalled-cycles-frontend:u        #    0.13% frontend cycles idle        ( +- 25.02% )
     1,174,431,108      branches:u                       #    2.187 G/sec                       ( +-  0.00% )
            28,096      branch-misses:u                  #    0.00% of all branches             ( +-  6.92% )

            0.5375 +- 0.0133 seconds time elapsed  ( +-  2.47% )
```

### perf stat output (file mmaped, writes buffered)

```
perf stat -r 5 ./build/hexdump test512.bin > /dev/null

 Performance counter stats for './build/hexdump test512.bin' (5 runs):

            532.28 msec task-clock:u                     #    0.996 CPUs utilized               ( +-  0.29% )
                 0      context-switches:u               #    0.000 /sec                      
                 0      cpu-migrations:u                 #    0.000 /sec                      
                68      page-faults:u                    #  127.752 /sec                      
    10,737,451,679      instructions:u                   #    4.63  insn per cycle            
                                                  #    0.00  stalled cycles per insn     ( +-  0.00% )
     2,319,353,802      cycles:u                         #    4.357 GHz                         ( +-  0.32% )
         4,463,355      stalled-cycles-frontend:u        #    0.19% frontend cycles idle        ( +- 19.85% )
     1,207,960,169      branches:u                       #    2.269 G/sec                       ( +-  0.00% )
            20,478      branch-misses:u                  #    0.00% of all branches             ( +-  6.68% )

           0.53438 +- 0.00176 seconds time elapsed  ( +-  0.33% )
```

---

**Key Observations:**
- Mean runtime is essentially the same, confirming the workload is **compute-bound** rather than I/O-bound.
- Using `MAP_POPULATE` reduces run-to-run variance and page faults, resulting in more consistent execution.
- Buffered output keeps the CPU busy in the same hot loop, so IPC and branch behavior remain remain close to scalar execution limits

---

## Conclusion

The mmap + MAP_POPULATE approach **does not significantly improve throughput**, but it provides **more consistent performance** by preloading file pages into memory. This branch serves as an experiment in memory-mapped input while keeping the core formatting pipeline and buffered output unchanged.
