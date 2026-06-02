# EMU86 Sandbox Architecture Control Document

## 1 Project Identity

Project name

EMU86 Sandbox A Measured Policy Enforcing Execution Environment with Hash Chained Audit Trail

Course

Computer Organization and Assembly Language

Session

Spring 2026

Project status

Instructor approved custom COAL project

Main implementation platform

EMU8086 or MASM or TASM style 8086 assembly

Main demo type

Reliable simulated interrupt gateway

Optional extension

Real TSR INT 21h hook as future work or bonus only

## 2 Project Scope

This project implements a small 8086 assembly sandbox that checks selected DOS service requests before allowing them to execute.

The guest program or guest routine sends requests through a sandbox handler. The sandbox reads the DOS service number from AH, checks a fixed policy table, logs the decision, updates a simple hash chain, and either forwards the request or blocks it.

The project demonstrates policy checking, audit logging, checksum based measurement, tamper detection, and fail closed behavior.

## 3 Out of Scope Items

The project does not implement real cryptographic security.

The project does not implement SHA 256.

The project does not implement JWT.

The project does not use RDTSC.

The project does not use 32 bit registers.

The project does not use 64 bit registers.

The project does not use modern operating system APIs.

The project does not claim production grade sandboxing.

The project does not depend on a real TSR hook for the main demo.

## 4 Architecture Overview

The main execution flow is

Guest Request

Sandbox Gateway

Policy Engine

Audit Logger

Hash Chain Update

DOS Forwarding or Safe Blocking

Self Check

Fail Closed Verification

The sandbox gateway is the central control point. It receives the requested function number in AH. It calls the policy engine to decide what to do. It calls the logger to record the result. It calls checksum routines to maintain the hash chain. It forwards safe requests to DOS and blocks restricted requests.

## 5 Main Modules

| Module   | Purpose                                    | Main File                    | Lead Member           |
| -------- | ------------------------------------------ | ---------------------------- | --------------------- |
| Module 1 | Sandbox Core and Simulated INT 21h Gateway | sandbox.asm                  | Ahmad Kaleem Bhatti   |
| Module 2 | Policy Engine and Masking Logic            | policy.inc                   | Nouman Akhtar         |
| Module 3 | Audit Logger and Hash Chain                | logger.inc and checksum.inc  | Muneeb Ul Hassan      |
| Module 4 | Guest Testing and Analysis                 | guest.asm and Analysis files | Muhammad Aezaz Hassan |

## 6 Team Contribution Plan

Ahmad Kaleem Bhatti leads the sandbox core and integration work.

Nouman Akhtar leads policy enforcement and masking logic.

Muneeb Ul Hassan leads audit logging and checksum chaining.

Muhammad Aezaz Hassan leads guest testing, output files, and performance analysis.

Every member contributes to coding, testing, debugging, integration, and viva preparation.

No member is assigned only documentation or presentation work.

## 7 Monitored DOS Services

The sandbox monitors these DOS service numbers through AH.

| AH Value | Service              | Policy            |
| -------- | -------------------- | ----------------- |
| 09h      | Print string         | Allow or mask     |
| 01h      | Read character       | Allow             |
| 02h      | Print character      | Allow             |
| 3Ch      | Create file          | Deny              |
| 3Dh      | Open file            | Allow             |
| 3Eh      | Close file           | Allow             |
| 3Fh      | Read file or device  | Allow             |
| 40h      | Write file or device | Approval required |
| 4Ch      | Terminate program    | Allow             |

## 8 Policy Decisions

The policy engine uses these decisions.

| Decision Name  | Value | Meaning                         |
| -------------- | ----: | ------------------------------- |
| POLICY_ALLOW   |     0 | Forward request                 |
| POLICY_DENY    |     1 | Block request                   |
| POLICY_MASK    |     2 | Redact sensitive output         |
| POLICY_APPROVE |     3 | Block and log approval required |
| POLICY_TAMPER  |     4 | Log tamper event                |

## 9 Audit Log Design

The audit log is stored in memory.

Each entry stores

Entry number

DOS function number

Decision

Previous hash

Current hash

Recommended entry size

8 bytes

Recommended maximum entries

64

Estimated log memory usage

512 bytes

## 10 Hash Chain Design

The hash chain uses a simple 16 bit checksum.

Formula

new hash equals previous hash XOR function number XOR decision XOR entry counter

Then rotate the result left by one bit.

This is used for educational tamper evidence only. It is not cryptographically secure.

## 11 Startup Measurement

At program startup the sandbox computes a checksum of the policy table.

The result is stored as the expected measurement.

The program prints the measurement during initialization.

Example output

[Sandbox] Policy Measurement = 4A2F

## 12 Self Check Design

The self check routine recomputes the policy table checksum.

If the recomputed checksum is different from the stored measurement, the sandbox logs a TAMPER event and sets fail closed mode.

Tamper can be simulated during the demo by modifying one policy table byte or by calling a tamper simulation procedure.

## 13 Fail Closed Design

When fail closed mode is active, the sandbox denies protected operations.

Only AH 4Ch termination is allowed.

This demonstrates safer behavior after integrity failure.

## 14 Masking Design

Masking applies to AH 09h print string requests.

The sandbox checks the string at DS DX.

If the text contains SECRET, PASSWORD, or TOKEN, the sandbox prints [REDACTED] instead of the original string.

The event is logged as POLICY_MASK.

## 15 Approval Required Simplification

Interactive approval is not implemented inside the low level handler.

If policy returns approval required, the sandbox blocks the request and logs POLICY_APPROVE.

This avoids recursive DOS calls and keeps the project reliable in EMU8086.

## 16 Source File Responsibilities

sandbox.asm contains the main program, initialization, sandbox gateway, demo flow, and module integration.

policy.inc contains policy constants, DOS service constants, policy table, and CheckPolicy.

logger.inc contains audit log storage, log counter, previous hash storage, AddLogEntry, and DisplayLog.

checksum.inc contains ComputePolicyChecksum, ComputeLogHash, SelfCheck, and tamper support.

macros.inc contains simple helper macros such as print string and newline.

guest.asm contains the guest test behavior. If a separate guest program is not reliable in the emulator, the guest behavior can be included as a procedure inside sandbox.asm.

build_notes.txt explains how to compile and run the project.

## 17 Build Approach

Primary build target

EMU8086

Alternative build target

TASM with DOSBox

Main demo command flow

Open sandbox.asm

Compile

Emulate

Run

Capture screenshots

## 18 Expected Demo Flow

The demo should show

Sandbox initialization

Policy measurement

Normal print allowed

Sensitive print masked

File creation denied

Write request blocked as approval required

Audit log entries

Tamper simulation

Fail closed mode

Safe exit

## 19 Output Files

Output/sample_outputs.txt stores copied console output.

Output/test_cases.txt stores all test cases.

Output/screenshot_checklist.md stores required screenshots.

Output/screenshots stores captured images.

## 20 Analysis Files

Analysis/performance_analysis.md explains sandbox overhead.

Analysis/memory_usage.md calculates memory usage.

Analysis/instruction_count.md estimates native and sandboxed instruction counts.

The analysis uses estimates because RDTSC is not available on 8086.

## 21 Report Style Rules

The final report must use numbered headings.

The report must avoid colon characters in headings.

The report must avoid dash based bullet lists.

The report must avoid em dashes.

The report must use natural student academic writing.

The report must not sound like AI generated text.

The report must make realistic claims only.

The report must clearly mention limitations.

The report must not claim cryptographic security.

The report must not claim production grade sandboxing.

## 22 Code Style Rules

Use MASM TASM or EMU8086 style assembly.

Use procedures for each major function.

Use 8086 compatible instructions only.

Use essential comments only.

Keep comments short and useful.

Avoid comments that explain obvious register moves.

Avoid robotic or over detailed comments.

Before final submission, review all comments and remove unnatural comments.

## 23 Development Phases

Phase 1 creates folder structure and this architecture document.

Phase 2 creates the basic console demo skeleton.

Phase 3 creates policy constants and policy table.

Phase 4 implements policy checking.

Phase 5 implements sandbox gateway.

Phase 6 implements allow and deny behavior.

Phase 7 implements audit logger.

Phase 8 implements hash chain checksum.

Phase 9 implements masking.

Phase 10 implements startup measurement.

Phase 11 implements self check and tamper simulation.

Phase 12 implements fail closed behavior.

Phase 13 creates guest test behavior.

Phase 14 creates output files.

Phase 15 creates analysis files.

Phase 16 creates report draft.

Phase 17 creates viva preparation.

Phase 18 creates final submission checklist.

## 24 Scope Lock Rule

All future implementation must follow this architecture document.

If a requested feature conflicts with this document, update this document first.

Do not add unsupported advanced features.

Do not expand the project beyond the approved COAL scope.

Reliable working implementation is more important than unrealistic complexity.

## 25 Final Deliverables

The final project must include

Complete assembly source files

Modular include files

Build notes

Sample outputs

Test cases

Screenshots

Instruction count analysis

Memory usage analysis

Performance analysis

Final report

Viva preparation

Submission checklist

GitHub collaboration evidence
