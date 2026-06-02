# Instruction Count Estimate

All values are theoretical estimates based on counting assembly instructions for each operation. No actual cycle timing was measured because RDTSC is not available on the 8086.

| Operation | Native Instructions | Sandboxed Instructions | Overhead |
| --- | --- | --- | --- |
| Print string (AH 09h) | 2 | 25 | 23 extra |
| Masked print string | 2 | 40 | 38 extra |
| Print character (AH 02h) | 2 | 20 | 18 extra |
| File create blocked (AH 3Ch) | 2 | 15 | 13 extra |
| Write blocked (AH 40h) | 2 | 15 | 13 extra |
| Unknown service blocked | 2 | 12 | 10 extra |
| Audit log update | 0 | 12 | 12 extra |
| Hash chain update | 0 | 5 | 5 extra |
| Self check | 0 | 20 | 20 extra |
| Fail closed block | 0 | 8 | 8 extra |

Native instruction count uses mov ah, value and int 21h. The sandboxed path adds policy table lookup, string scanning where needed, audit log write, and hash computation.

The masking path adds the most overhead because the program scans the string byte by byte until it finds or clears a sensitive keyword match.

