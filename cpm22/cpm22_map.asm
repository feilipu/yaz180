;
; Copyright (C) 2017 Phillip Stevens  All Rights Reserved.
;
; Permission is hereby granted, free of charge, to any person obtaining a copy of
; this software and associated documentation files (the "Software"), to deal in
; the Software without restriction, including without limitation the rights to
; use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
; the Software, and to permit persons to whom the Software is furnished to do so,
; subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
; FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
; COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
; IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;; 1 tab == 4 spaces!
;

SECTION     cpm_page0   ;rewrite page 0 as needed
ORG         0x0000

SECTION     cpm_tpa     ;transitory program area
ORG         0x0100

SECTION     cpm_ccp     ;base of ccp
ORG         0xCF00

SECTION     cpm_ccp_data
ORG         -1

SECTION     cpm_bdos
ORG         -1

SECTION     cpm_bdos_data
ORG         -1

SECTION     cpm_bios    ;base of bios
ORG         0xE600


SECTION     cpm_bios_data
ORG         -1

;==============================================================================
