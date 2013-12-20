Computer-Organisation
=====================

This consists of the assignments done as a part of the Computer Organisation course in the 4th semester in IIT Madras

 

1. The objective of The  first  assignment is to  you understand the basics of x86 architecture,We  write an assembly code that takes in two matrices A 10*20 and B 20*30 in row-major form from the adresses 0-799 and 800-3199, and multiplies them, storing the resultant matrix C 10*30 in memory location 3199-5199, also in row-major form. We use the following instructions: ADD,ADDC,IMUL,MOV rs,rd, MOV rs, [rd] , JMP,JNE. The manual can be found <a href="http://www.intel.com/design/pentium4/manuals/."><b>here </b></a>
2. The objective of this assignment is to  understand the basics of segmentation, and the working issues in compilation related to function calls.We write an assembly code that takes in two matrices A 10*20 and B 20*30 in row-major form from the data segments DS and ES respectively, and multiply them, storing the resultant matrix C 10*30 in data segment GS, also in row-major form. The matrices A and B are generated randomly by a C-program, which also multiplies these two matrices to produce the matrix C, which is eventually stored in data segment FS. The assembly code also compares the matrices stored in data segments FS and GS to find out whether multiplication has been done correctly or not. The multiplication should be done in protected mode. Segments DS, ES, FS, GS and SS need to be precisely described in the GDT, with tight limits. The multiplication of two 32-bit integers is done through a procedure call.
3. We write Interrupt Service Routine for Trap 0 (Divide by Zero), 11 and 13. We simulate these interrupts.
4. The primary objective of this assignment is to understand Paging, handling page faults,TLB and other details about Paging.
5. The objective of this assignment is to understand Task Switching and Call gate.We first use task gates to switch from PL0->PL1->PL2->PL3 and then in PL3 we try to access a PL2 data segment. This generates an interrupt. This is serviced by the Interrupt service routine(ISR) which changes the PL and returns.Then we use Call Gate to access PL0 from PL3 and returning back to PL3
