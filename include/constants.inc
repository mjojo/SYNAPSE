; ============================================================================
; TITAN Language - Языковые константы
; (c) 2025 mjojo (Vitaly.G) & GLK-Dev
; https://github.com/GLK-Dev
;
; Платформо-независимые константы языка TITAN
; Платформо-зависимые константы см. в platform_*.inc
; ============================================================================

; ----------------------------------------------------------------------------
; Windows API константы (TODO: вынести в platform при полной кроссплатформе)
; ----------------------------------------------------------------------------
STD_INPUT_HANDLE  = -10
STD_OUTPUT_HANDLE = -11
STD_ERROR_HANDLE  = -12

; Размеры буферов
INPUT_BUFFER_SIZE = 256
JIT_BUFFER_SIZE   = 4096

; Типы токенов (для лексера)
TOKEN_NONE        = 0
TOKEN_NUMBER      = 1
TOKEN_IDENTIFIER  = 2
TOKEN_STRING      = 3
TOKEN_OPERATOR    = 4
TOKEN_KEYWORD     = 5
TOKEN_EOL         = 6
TOKEN_STRING_VAR  = 7   ; Идентификатор с $ на конце (A$, B$, ...)
TOKEN_FLOAT       = 8   ; Phase 15: Число с плавающей точкой (3.14, 0.5)

; Типы переменных (Phase 15: Floating Point)
VAR_TYPE_INT      = 0   ; 64-bit integer (default)
VAR_TYPE_FLOAT    = 1   ; 64-bit double

; Ключевые слова (коды)
KW_PRINT          = 1
KW_INPUT          = 2
KW_CLS            = 3
KW_LET            = 4
KW_DIM            = 5
KW_GOTO           = 6
KW_IF             = 7
KW_THEN           = 8
KW_ELSE           = 9
KW_GOSUB          = 10
KW_RETURN         = 11
KW_END            = 12
KW_STOP           = 13
KW_FOR            = 14
KW_TO             = 15
KW_STEP           = 16
KW_NEXT           = 17
KW_WHILE          = 18
KW_WEND           = 19
KW_DATA           = 20
KW_READ           = 21
KW_RESTORE        = 22
KW_AND            = 23
KW_OR             = 24
KW_NOT            = 25
KW_RUN            = 26
KW_LIST           = 27
KW_NEW            = 28
KW_SAVE           = 29
KW_LOAD           = 30
KW_EXIT           = 31
KW_HELP           = 32
KW_DUMP           = 33
KW_VARS           = 34
KW_REGS           = 35
KW_REM            = 36
KW_CRASH          = 37   ; Тестовая команда для проверки crash handler

; === SIMD команды (Phase 9) ===
KW_VDIM           = 38   ; VDIM V0 — объявить вектор
KW_VSET           = 39   ; VSET V0 = 1,2,3,4,5,6,7,8
KW_VADD           = 40   ; VADD V0 V1 — сложить 8 пар
KW_VSUB           = 41   ; VSUB V0 V1
KW_VMUL           = 42   ; VMUL V0 V1
KW_VPRINT         = 43   ; VPRINT V0 — вывести вектор

; === Phase 11: Benchmarks ===
KW_TIMER          = 44   ; TIMER T — сохранить rdtsc в переменную

; === Phase 12: Local Variables (Stack Frames) ===
KW_FUNC           = 45   ; FUNC Name — начало функции
KW_ENDFUNC        = 46   ; ENDFUNC — конец функции
KW_LOCAL          = 47   ; LOCAL A — локальная переменная

; === Phase 13: FFI (Foreign Function Interface) ===
KW_DECLARE        = 48   ; DECLARE MSGBOX LIB "user32.dll" ALIAS "MessageBoxA"
KW_TEST_GUI       = 49   ; TEST_GUI — тестовая команда для проверки FFI
KW_MSGBOX         = 50   ; MSGBOX "Text", "Title" — показать MessageBox
KW_LIB            = 51   ; LIB — ключевое слово для DECLARE
KW_ALIAS          = 52   ; ALIAS — ключевое слово для DECLARE

; === Phase 17: Binary File I/O ===
KW_BLOAD          = 53   ; BLOAD "file.bin", A — загрузить данные в массив
KW_BSAVE          = 54   ; BSAVE "file.bin", A — сохранить массив в файл

; === Phase 18: Tensor Operations ===
KW_MATMUL         = 55   ; MATMUL C, A, B, M, N, K — умножение матриц
KW_VRELU          = 56   ; VRELU A, N — активация ReLU на массиве

; === Phase 20: Interactive Input ===
KW_MOUSE          = 57   ; MOUSE X, Y — получить координаты мыши
KW_KEYDOWN        = 58   ; KEYDOWN(vk) — проверить нажатие клавиши
KW_SLEEP          = 59   ; SLEEP ms — пауза в миллисекундах
KW_ADDR           = 60   ; ADDR(A) — получить адрес массива

; === Phase 21: Graphics Window ===
KW_WINDOW         = 61   ; WINDOW w, h, "title" — создать графическое окно
KW_PSET           = 62   ; PSET x, y, color — установить пиксель
KW_UPDATE         = 63   ; UPDATE — обновить экран (flush framebuffer)
KW_WCLS           = 64   ; WCLS [color] — очистить графическое окно

; === Phase 22: Vision (Neural Eye) ===
KW_CAPTURE        = 65   ; CAPTURE array — захватить 28x28 в float массив

; === Phase 23: The Lens (Downsampling) ===
KW_DOWNSAMPLE     = 66   ; DOWNSAMPLE x,y,w,h,array,scale — сжать область в массив

; === Phase 23b: Array Operations ===
KW_ARRADD         = 67   ; ARRADD C, A, B, N — C[i] = A[i] + B[i] для float64 массивов

; === Phase 24: The Voice (Bitmap Fonts) ===
KW_GPRINT         = 68   ; GPRINT x, y, "text", color, scale — вывод текста в графику

; Операторы (коды)
OP_PLUS           = 1   ; +
OP_MINUS          = 2   ; -
OP_MUL            = 3   ; *
OP_DIV            = 4   ; /
OP_POWER          = 5   ; ^
OP_EQ             = 6   ; =
OP_LT             = 7   ; <
OP_GT             = 8   ; >
OP_LE             = 9   ; <=
OP_GE             = 10  ; >=
OP_NE             = 11  ; <>
OP_LPAREN         = 12  ; (
OP_RPAREN         = 13  ; )
OP_COMMA          = 14  ; ,
OP_SEMICOLON      = 15  ; ;
OP_COLON          = 16  ; :

; Коды ошибок
ERR_NONE          = 0
ERR_SYNTAX        = 1
ERR_UNDEFINED_VAR = 2
ERR_DIV_BY_ZERO   = 3
ERR_OUT_OF_MEMORY = 4
ERR_LINE_NOT_FOUND= 5
