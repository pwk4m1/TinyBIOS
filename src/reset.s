.section .text
.global test
test:
    hlt

.section .reset
.global reset
reset:
     cli
     hlt

