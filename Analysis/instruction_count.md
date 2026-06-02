# Instruction Count Estimate

All values are theoretical estimates based on counting assembly instructions for each operation. No actual cycle timing was measured because RDTSC is not available on the 8086.

## Core Gateway Operations

| Operation | Native Instructions | Sandboxed Instructions | Overhead |
| --- | --- | --- | --- |
| Print string (AH 09h) | 2 | 25 | 23 extra |
| Masked print string (exact lowercase) | 2 | 40 | 38 extra |
| Masked print string (mixed-case, after fold) | 2 | 55 | 53 extra |
| Print character (AH 02h) | 2 | 20 | 18 extra |
| File create blocked (AH 3Ch) | 2 | 15 | 13 extra |
| Write blocked (AH 40h) | 2 | 15 | 13 extra |
| Unknown service blocked | 2 | 12 | 10 extra |
| Audit log update | 0 | 12 | 12 extra |
| Hash chain update | 0 | 5 | 5 extra |
| Self check | 0 | 20 | 20 extra |
| Fail closed block | 0 | 8 | 8 extra |

## Admin Subsystem Operations

| Operation | Instructions | Notes |
| --- | --- | --- |
| InPlaceLowercase (64-char input) | up to 192 | 3 instructions per character in worst case |
| MatchExactString (7-char password) | up to 28 | 4 instructions per character, exits early on mismatch |
| AdminAuthenticate (success path) | approximately 45 | includes prompt, read, match, log write |
| AdminAuthenticate (failure path) | approximately 50 | includes prompt, read, match, fail message, counter update |
| DisplayLog (per entry) | approximately 30 | hex8 x2, hexword x1, decimal x1, print calls |
| PrintHex8 | 12 | two nibble extractions, two DOS 02h calls |
| PrintDecimal (single digit) | approximately 20 | division loop, skip-leading-zero scan, PrintString |
| DoStatsCommand | approximately 80 | 7 label-print plus 7 PrintDecimal calls |
| DoClearLogsCommand | approximately 520 | 512-iteration zero loop plus counter resets |

## Key Observations

The mixed-case masking path is more expensive than exact lowercase matching because InPlaceLowercase must iterate over every character in the input buffer before the scan begins. This is a one-time cost per input string regardless of where the sensitive keyword appears.

The admin subsystem operations are invoked only on demand and not on every REPL iteration. Their overhead does not affect normal string evaluation performance.

DoClearLogsCommand uses a simple byte-by-byte zero loop over 512 bytes. This is the most instruction-heavy single operation in the system but runs only when the admin explicitly clears the log.
