# Hexdump Utility

## Overview

Experimental version which uses mmap to memory map the entire file into memory instead of using a buffer to hold the file. There are no limits on how big the file can be which is less than ideal i suppose but why would anyone hexdump a file gigabytes in size.

## Performance difference
Heres perf stat for the buffered version on a 512mb file with cold cache
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

Heres perf stat for the mmap version
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
The mmap version is much more consistent but uses as much memory as the size of the file.
