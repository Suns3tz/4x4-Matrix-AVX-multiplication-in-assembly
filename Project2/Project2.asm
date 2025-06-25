extern printf : proc

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

    fmt db "El valor es: %d", 10, 0
    fmt_fila db "%f %f %f %f", 10, 0
    fmt_titulo db "Resultado de la multiplicacion:", 10, 0

    ; Matriz A (matriz1) 4x4
    ALIGN 16
    matriz1:  
        dd 1.0, 2.0, 3.0, 4.0   ; fila 0
        dd 5.0, 6.0, 7.0, 8.0   ; fila 1
        dd 10.0, 10.0, 11.0, 12.0 ; fila 2
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
    
    one_float dd 1.0

.code

main PROC

    ; ========================
    ; PRUEBA PRINT
    ; ========================
    ;sub rsp, 28h          ; reservar espacio para alineación

    ;mov rcx, offset fmt   ; primer argumento: string formato
    ;mov edx, 1234         ; segundo argumento: valor %d
    ;call printf

    ;add rsp, 28h          ; restaurar stack
    ; ========================
    ; FIN PRUEBA
    ; ========================

    ; Reservar espacio en el stack para las llamadas a printf
    sub rsp, 48h            ; Alineación de 16 bytes + espacio para parámetros

    lea rdx, matriz1        ; rdx = puntero a matriz1 (A)
    lea r8, matriz2         ; r8 = puntero a matriz2 (B)
    lea r10, resultado      ; rcx = puntero al resultado C

    ; Cargar filas de matriz2 en donde corresponden
    vmovaps xmm0, [r8]                      ; fila 0 de B
    vmovaps xmm1, [r8+16]                   ; fila 1 de B
    vmovaps xmm2, [r8+32]                   ; fila 2 de B
    vmovaps xmm3, [r8+48]                   ; fila 3 de B

    mov r11, rdx                            ; r11 = puntero base a matriz1 (Guardar punteros base para no perderlos)
    xor r9d, r9d                            ; r9d = j = 0

    loop_filas:

        mov eax, r9d                ; eax = índice de fila actual
        shl eax, 4                  ; eax = índice * 16
        lea rdx, [r11 + rax]        ; rdx = dirección de la fila actual

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
        lea rax, [r10 + rax]
        vmovaps [rax], xmm4

        inc r9d                     ; Incrementar el contador de las filas, j
        cmp r9d, 4                  ; Si el contador ya llego a 4
        jl loop_filas               ; Si si, termina el ciclo, si no, repite el bucle

        ; ===========================
        ; IMPRESION EN CONSOLA
        ; ===========================

        lea rcx, offset fmt_titulo  ; Imprimir título
        call printf

        lea rbx, resultado      ; puntero base a resultado
        xor rsi, rsi            ; contador filas = 0

        print_loop:
            ; Cargar los 4 floats de la fila actual
            movss xmm0, dword ptr [rbx]        ; primer float
            movss xmm1, dword ptr [rbx+4]      ; segundo float  
            movss xmm2, dword ptr [rbx+8]      ; tercer float
            movss xmm3, dword ptr [rbx+12]     ; cuarto float
    
            ; Convertir de float (32-bit) a double (64-bit)
            cvtss2sd xmm0, xmm0
            cvtss2sd xmm1, xmm1
            cvtss2sd xmm2, xmm2
            cvtss2sd xmm3, xmm3

            ; Para funciones variádicas en Windows x64, los argumentos de punto flotante
            ; deben estar TANTO en registros XMM COMO en registros enteros
    
            ; Copiar los doubles a registros enteros (para printf variádico)
            movq rdx, xmm0          ; primer double -> RDX
            movq r8, xmm1           ; segundo double -> R8  
            movq r9, xmm2           ; tercer double -> R9
            movq rax, xmm3          ; cuarto double -> RAX (temporal)
    
            ; El cuarto parámetro va al stack
            mov qword ptr [rsp+20h], rax
    
            ; Configurar parámetros para printf
            lea rcx, fmt_fila       ; primer argumento: formato string
            ; rdx = primer double (también en xmm0)
            ; r8 = segundo double (también en xmm1)  
            ; r9 = tercer double (también en xmm2)
            ; [rsp+20h] = cuarto double

            call printf

            add rbx, 16             ; siguiente fila (4 floats * 4 bytes = 16 bytes)
            inc rsi                 ; incrementar contador
            cmp rsi, 4              ; comparar con 4 filas
            jl print_loop           ; continuar si no hemos terminado

        ; ===========================
        ; FIN DE LA PRUEBA
        ; ===========================

        ; Restaurar el stack
        add rsp, 48h

        ret

main ENDP
END
