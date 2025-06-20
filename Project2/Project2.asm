extern printf : proc
includelib msvcrt.lib
includelib legacy_stdio_definitions.lib
includelib ucrt.lib
includelib vcruntime.lib

; Uso de los registros:
; ===================
; Matriz 2
; ===================
; xmm0 = matriz2[0]
; xmm1 = matriz2[1]
; xmm2 = matriz2[2]
; xmm3 = matriz2[3]

; ===================
; Matriz 1
; ===================
; xmm4 = Las distribuciones de la matriz A [0][j]
; xmm5 = Las distribuciones de la matriz A [1][j]
; xmm6 = Las distribuciones de la matriz A [2][j]
; xmm7 = Las distribuciones de la matriz A [3][j]

; ===================
; Entradas
; ===================
; rdx = puntero a la matriz 1
; r8 = puntero a la matriz 2
; rcx = puntero al resultado
; r9d = contador de las filas de A

.data

    fmt_str db "%f ", 0
    fmt_nl  db 10, 0

    ; Matriz A (matriz1) 4x4
    ALIGN 16
    matriz1:  
        dd 1.0, 2.0, 3.0, 4.0   ; fila 0
        dd 5.0, 6.0, 7.0, 8.0   ; fila 1
        dd 9.0, 10.0, 11.0, 12.0 ; fila 2
        dd 13.0, 14.0, 15.0, 16.0 ; fila 3

    ; Matriz B (matriz2) 4x4
    ALIGN 16
    matriz2:  
        dd 1.0, 0.0, 0.0, 0.0   ; fila 0
        dd 0.0, 1.0, 0.0, 0.0   ; fila 1
        dd 0.0, 0.0, 1.0, 0.0   ; fila 2
        dd 0.0, 0.0, 0.0, 1.0   ; fila 3

    ; Matriz resultado C
    ALIGN 16
    resultado:
        dd 0.0, 0.0, 0.0, 0.0
        dd 0.0, 0.0, 0.0, 0.0
        dd 0.0, 0.0, 0.0, 0.0
        dd 0.0, 0.0, 0.0, 0.0

.code

main PROC

    lea rdx, matriz1        ; rdx = puntero a matriz1 (A)
    lea r8, matriz2         ; r8 = puntero a matriz2 (B)
    lea rcx, resultado      ; rcx = puntero al resultado C

    ; Cargar filas de matriz2 en donde corresponden
    vmovaps xmm0, [r8]                      ; fila 0 de B
    vmovaps xmm1, [r8+16]                   ; fila 1 de B
    vmovaps xmm2, [r8+32]                   ; fila 2 de B
    vmovaps xmm3, [r8+48]                   ; fila 3 de B

    xor r9d, r9d                            ; r9d = j = 0

    loop_filas:

        ; Broadcast de los elementos de la fila j de matriz1 (A)
        vbroadcastss xmm4, real4 ptr [rdx]      ; Distribuye la fila A[j][0] esta en xmm4
        vbroadcastss xmm5, real4 ptr [rdx+4]    ; Distribuye la fila A[j][1] esta en xmm5
        vbroadcastss xmm6, real4 ptr [rdx+8]    ; Distribuye la fila A[j][2] esta en xmm6
        vbroadcastss xmm7, real4 ptr [rdx+12]   ; Distribuye la fila A[j][3] esta en xmm7

        ; Multiplicaciones
        vmulps xmm4, xmm4, xmm0     ; xmm4 = A[j][0] * B[0][0] | A[j][0] * B[0][1] | A[j][0] * B[0][2] | A[j][0] * B[0][3]
        vmulps xmm5, xmm5, xmm1     ; xmm5 = A[j][1] * B[1][0] | A[j][1] * B[1][1] | A[j][1] * B[1][2] | A[j][1] * B[1][3]
        vmulps xmm6, xmm6, xmm2     ; xmm6 = A[j][2] * B[2][0] | A[j][2] * B[2][1] | A[j][2] * B[2][2] | A[j][2] * B[2][3]
        vmulps xmm7, xmm7, xmm3     ; xmm7 = A[j][3] * B[3][0] | A[j][3] * B[3][1] | A[j][3] * B[3][2] | A[j][3] * B[3][3]

        ; Sumas
        vaddps xmm4, xmm4, xmm5     ; xmm4 = A[j][0]*B[0][0] + A[j][1]*B[1][0] | A[j][0]*B[0][1] + A[j][1]*B[1][1]...
        vaddps xmm6, xmm6, xmm7     ; xmm6 = A[j][2]*B[2][0] + A[j][3]*B[3][0] | A[j][2]*B[2][1] + A[j][3]*B[3][1]...
        vaddps xmm4, xmm4, xmm6     ; xmm4 = C[j][0] | C[j][1] | C[j][2] | C[j][3]

        mov eax, r9d                ; Guardar el resultado de la fila en la que se encuentre
        shl eax, 4
        lea rax, [rcx + rax]
        vmovaps [rax], xmm4
    
        inc r9d                     ; Incrementar el contador de las filas, j
        cmp r9d, 4                  ; Si el contador ya llego a 4
        jl loop_filas               ; Si si, termina el ciclo, si no, repite el bucle

        ret

main ENDP
END