# SPIM S20 MIPS simulator.
# The default exception handler for spim.
#
# Copyright (C) 1990-2004 James Larus, larus@cs.wisc.edu.
# ALL RIGHTS RESERVED.
#
# SPIM is distributed under the following conditions:
#
# You may make copies of SPIM for your own use and modify those copies.
#
# All copies of SPIM must retain my name and copyright notice.
#
# You may not sell SPIM or distributed SPIM in conjunction with a commerical
# product or service without the expressed written consent of James Larus.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE.
#

# $Header: $


# Define the exception handling code.  This must go first!

	.kdata
__m1_:	.asciiz "  Exception "
__m2_:	.asciiz " occurred and ignored\n"
__e0_:	.asciiz "  [Interrupt] "
__e1_:	.asciiz	"  [TLB]"
__e2_:	.asciiz	"  [TLB]"
__e3_:	.asciiz	"  [TLB]"
__e4_:	.asciiz	"  [Address error in inst/data fetch] "
__e5_:	.asciiz	"  [Address error in store] "
__e6_:	.asciiz	"  [Bad instruction address] "
__e7_:	.asciiz	"  [Bad data address] "
__e8_:	.asciiz	"  [Error in syscall] "
__e9_:	.asciiz	"  [Breakpoint] "
__e10_:	.asciiz	"  [Reserved instruction] "
__e11_:	.asciiz	""
__e12_:	.asciiz	"  [Arithmetic overflow] "
__e13_:	.asciiz	"  [Trap] "
__e14_:	.asciiz	""
__e15_:	.asciiz	"  [Floating point] "
__e16_:	.asciiz	""
__e17_:	.asciiz	""
__e18_:	.asciiz	"  [Coproc 2]"
__e19_:	.asciiz	""
__e20_:	.asciiz	""
__e21_:	.asciiz	""
__e22_:	.asciiz	"  [MDMX]"
__e23_:	.asciiz	"  [Watch]"
__e24_:	.asciiz	"  [Machine check]"
__e25_:	.asciiz	""
__e26_:	.asciiz	""
__e27_:	.asciiz	""
__e28_:	.asciiz	""
__e29_:	.asciiz	""
__e30_:	.asciiz	"  [Cache]"
__e31_:	.asciiz	""
__excp:	.word __e0_, __e1_, __e2_, __e3_, __e4_, __e5_, __e6_, __e7_, __e8_, __e9_
	.word __e10_, __e11_, __e12_, __e13_, __e14_, __e15_, __e16_, __e17_, __e18_,
	.word __e19_, __e20_, __e21_, __e22_, __e23_, __e24_, __e25_, __e26_, __e27_,
	.word __e28_, __e29_, __e30_, __e31_
s1:	.word 0
s2:	.word 0


.eqv tecla 0xffff0000 #Tecla presionada por el usuario

# This is the exception handler code that the processor runs when
# an exception occurs. It only prints some information about the
# exception, but can server as a model of how to write a handler.
#
# Because we are running in the kernel, we can use $k0/$k1 without
# saving their old values.

# This is the exception vector address for MIPS-1 (R2000):
#	.ktext 0x80000080
# This is the exception vector address for MIPS32:
	.ktext 0x80000180
# Select the appropriate one for the mode in which SPIM is compiled.
	.set noat
	move $k1 $at		# Save $at
	.set at
	sw $v0 s1		# Not re-entrant and we can't trust $sp
	sw $a0 s2		# But we need to use these registers

	mfc0 $k0 $13		# Cause register
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f

	# Print information about exception.
	#
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m1_
	syscall

	li $v0 1		# syscall 1 (print_int)
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	syscall

	li $v0 4		# syscall 4 (print_str)
	andi $a0 $k0 0x3c
	lw $a0 __excp($a0)
	nop
	syscall

	bne $k0 0x18 ok_pc	# Bad PC exception requires special checks
	nop

	mfc0 $a0 $14		# EPC
	andi $a0 $a0 0x3	# Is EPC word-aligned?
	beq $a0 0 ok_pc
	nop

	li $v0 10		# Exit on really bad PC
	syscall

ok_pc:
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m2_
	syscall

	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	bne $a0 0 ret		# 0 means exception was an interrupt
	nop

# Interrupt-specific code goes here!
# Don't skip instruction at EPC since it has not executed.
# Causa de Interrupcion a traves de un shift y un and logico
	mfc0 $k0, $13
	srl $a0, $k0, 2
	andi $a0, $a0, 0x10
	bnez $a0, end  # Ver si no es una tecla de las importantes para moverse
	li $s0, 0xFFFF0000
	lw $a1, 4($s0)  # Cargo la tecla que fue marcada
	
	# Manejo de Teclas
	Teclado:
	
	bne $a1, 0x00000077, no_w
		la $a0, Arriba  # En caso de poder moverse hacia arriba
		jalr $a0
		
		b end
	no_w:
	
	bne $a1, 0x00000061, no_a
		la $a0, Izquierda  # En caso de poder moverse hacia la izquierda
		jalr $a0
		b end
	no_a:
	
	bne $a1, 0x00000073, no_s
		la $a0, Abajo  # En caso de poder moverse hacia abajo
		jalr $a0
		b end
	no_s:
	
	bne $a1, 0x00000064, no_esc
		la $a0, Derecha  # En caso de poder moverse hacia la derecha
		jalr $a0
		b end
	
	no_esc:
	bne $a1, 0x1B, no_d
		li $v0, 10
		syscall	
	no_d:
	
	b end
ret:
# Return from (non-interrupt) exception. Skip offending instruction
# at EPC to avoid infinite loop.
#
	mfc0 $k0 $14		# Bump EPC register
	addiu $k0 $k0 4		# Skip faulting instruction
				# (Need to handle delayed branch case here)
	mtc0 $k0 $14

end:
move $v1, $a0
# Restore registers and reset procesor state
#
	lw $v0 s1		# Restore other registers
	lw $a0 s2

	.set noat
	move $at $k1		# Restore $at
	.set at

	mtc0 $0 $13		# Clear Cause register

	mfc0 $k0 $12		# Set Status register
	ori  $k0 0x1		# Interrupts enabled
	mtc0 $k0 $12

# Return from exception on MIPS32:
	eret

# Return sequence for MIPS-I (R2000):
#	rfe			# Return from exception handler
				# Should be in jr's delay slot
#	jr $k0
#	 nop



# Standard startup code.  Invoke the routine "main" with arguments:
#	main(argc, argv, envp)
#
#	.text
#	.globl __start
#__start:
#	lw $a0 0($sp)		# argc
#	addiu $a1 $sp 4		# argv
#	addiu $a2 $a1 4		# envp
#	sll $v0 $a0 2
#	addu $a2 $a2 $v0
#	jal main
#	nop

#	li $v0 10
#	syscall			# syscall 10 (exit)

#	.globl __eoth
#__eoth:

.data
	ingreso: .asciiz "ingrese el nombre del archivo\n"
		.align 2  # Alineamos con una palabra
		
	nombre: .space 25
		.align 2  # Alineamos con una palabra
	
	salida1: .asciiz "hubo un error leyendo el archivo"
		.align 2  # Alineamos con una palabra
	
	salida2: .asciiz "ingrse las dimensiones del archivo\n"
		.align 2  # Alineamos con una palabra
		
	memoriaInicial: .word 0  # Aqu� se guardar� la memoria inicial del heap
			.align 2
	
	memoriaNegra: .word 0  # Aqu� se guardar� la memoria calculada para empezar a operar
	              .align 2
	
	otraMemoria: .word 0  # Aqu� se guardar�n direcciones para calcular arriba / abajo
	             .align 2		
			
	dimensiones: .word 0  # Guardaremos la dimesion de la imagen, ya que es muy importante para muchos calculos
		     .align 2
	
	palabras: .word 0  # Aqu� se guardar�n el n�mero de palabras que hay por cada celda
		  .align 2
	
	filaActual: .word 3  # Aqu� se guardar� la posicion inicial de la fila
		    .align 2 
		    
	columnaActual: .word 3  # Guarda la columna actual, inicialmente vale 3
			.align 2
			
	error: .asciiz "No puede moverse por ah�\n"
	.align 2

.text
# Usos de registros
# t0 guardar� temporales iniciales: nombres de archivos, direcciones de memoria, etc y el descriptor del archivo
# t1 ayuda a guardar valores para quitar \n input, guarda las dimensiones de la imagen. Finalmente guarda dimension*dimension
# t2 ayuda a guardar valores para quitar \n input, guardar� $t1* 4, esto para poder iterar y cargar la imagen
# t3 guardar� la direcci�n de memoria del heap, y las dimensiones
# t4 guardar� la direcci�n de memoria de donde sacamos palabras para el heap
# t5 guardar� la palabra a meter en el heap, cuando cargamos la imagen
# t6 guardar� la segunda direcci�n del heap donde se guarda la informaci�n de la imagen, luego de mandada al heap, no es necesario tenerla

	main:
	Cargar_Archivo:
		# Mostramos mensajes de lectura
		
		li $v0, 4 
		la $a0, ingreso
		syscall
		
		# Pedimos el nombre del archivo
		
		la $a0, nombre
		li $a1 , 25
		li $v0, 8
		syscall
		
		# Cargamos el \n para borrarlo del input del usuario
		la $t0, nombre
		li $t2, 0x0000000a  # Esta es la forma de guardar \n
		
		quitarEspacio:
			lb $t1, ($t0)
			addi $t0, $t0, 1
			bne $t1, $t2, quitarEspacio
			sub $t0, $t0, 1
			sb $zero, ($t0)
		
		# Abrimos el archivo
		
		li $v0, 13  # Flag de apertura de archivos
		la $a0, nombre  # Buscamos el nombre del archivo
		li $a1, 0
		li $a2, 0
		syscall	
		
		move $t0, $v0  # Guardamos el descriptor del archivo
		
		# Verificaci�n de que ley� el archivo
		
		bgt $t0, $zero, LecturaExitosa  # En caso de fallar indicamos de un error al usuario
		li $v0, 4
		la $a0, salida1
		syscall
		
		b Cargar_Archivo  # Salta en caso de error
		
	LecturaExitosa:
		
		# Pedimos las dimensiones
		la $a0, salida2
		li $v0 , 4
		syscall
		
		# Ingreso de la dimensi�n por parte del usuario
		li $v0, 5
		syscall
		
		# Guardamos las dimensiones
		move $t1 , $v0
		sw $t1, dimensiones
		srl $t2, $t1, 2  # Dividimos entre 4
		
		sw $t2, palabras  # Para futuros calculos
		
		move $t2, $zero  # Reiniciamos t2 
		
		# Crearemos un espacio en el heap de la dimensionDada* dimensionDada * 4
		mul $t1, $t1, $t1  # t1 = t1 * t1
		sll $t2, $t1 ,2  # Como estamos multiplicando por potencias de dos hacemos sll de 2 para multiplicar por 4
		
		# Ahora reservamos el espacio dinamicamente
		li $v0, 9
		move $a0, $t1  # Cargamos la cantidad de espacio que queremos guardar
		syscall
		
		move $t3, $v0  # Guardamos la direcci�n de memoria donde guardaremos la imagen aqu�
		sw $t3, memoriaInicial # Guardamos para futuro uso en cuanto a la l�gica del juego 
		
		# Volvemos a reservar m�s espacio para evitar sobre-escritura
		li $v0, 9
		move $a0, $t1
		syscall
		
		move $t6, $v0  # t6 tendr� la direcci�n para guardar el archivo
		sw $t6, memoriaNegra  # Para futura l�gica del juego
		
		# Hacemos una lectura ahora del archivo
		li $v0 , 14 
		move $a0 , $t0  # Descriptor del archivo
		la $a1, ($t6) # Direccion a guardar todo
		move $a2, $t2  # Dimensiones todo lo que vamos a guardar
		syscall
		
		# Ya no necesitamos m�s del archivo, por lo tanto lo cerramos
		li $v0, 16
		syscall
		
		MostrarImagen:
			lw $t5, ($t6)  # Cargamos la palabra que est� en t6
			addi $t6, $t6, 4  # Ajustamos la direcci�n de memoria a leer
			
			sw $t5, ($t3)  # Guardamos en la primera direcci�n del heap
			addi $t3, $t3, 4  # Ajustamos la direcci�n a memoria para guardar
			
			sub $t1, $t1, 1  # Ajustamos la variable iterativa
			
			bne $t1, $zero, MostrarImagen 
			
			
			# Empezaremos ahora a calcular la direccion del cuadro negro
		CalculoDireccionInicial:
			# Vaciamos todos los temporales en uso
			move $t0, $zero
			move $t1, $zero
			move $t2, $zero
			move $t3, $zero
			move $t4, $zero
			move $t5, $zero
			move $t6, $zero
				
			# Formula: direccionF=DireccionHeap + (dimension * NumeroColumna) + (palabrasPorCelda*N�meroFila)
			# Como tenemos que la primera columna y fila son dadas del enunciado, estas ser�n la 
			# Columna 3 y fila 3. Siempre empezadas a contarse desde el 0
			lw $t0, palabras
			
			mul $t0, $t0, 3  # Multiplico por el n�mero de la fila
			sll $t0, $t0, 2
			lw $t1, dimensiones  # Cargo las dimensiones
			mul $t0, $t0, $t1  # Multiplico por las dimensiones
			mul $t1, $t1, 3  # Multiplico por columna
			lw $t2, memoriaInicial  # Cargo la memoria del heap
			add $t2, $t2, $t1  # direccionF = DireccionHeap + (dimension*NumeroColumna)
			add $t2, $t2, $t0  # DireccionF=DireccionHeap +(dimension*NumeroColumna) + (palabrasPorCelda*numeroFila)
			
			# Guardamos ahora esta direccion, la cual es sagrada
			sw $t2, memoriaNegra
			
			vaciado:
			# Vaciamos todos los temporales en uso por si acaso
			move $t0, $zero
			move $t1, $zero
			move $t2, $zero
			move $t3, $zero
			move $t4, $zero
			move $t5, $zero
			move $t6, $zero			
			
			HabilitarInterrupciones:
				li $t0 0xFFFF0000
				ori $t0, $t0 2  # Enciendo el bit adecuado
				
				sw $t0, 0xFFFF0000  # Guardando todo en la memoria
				
			LoopInfinito:
				li $t7, 0x1B
				beq $a1, $t7 fin
				b LoopInfinito
					
			Izquierda:
				# C�lculo de la nueva direcci�n
				# Formula: direccion=DireccionHeap + (palbras*fila*dimensiones*4) + (dimensiones*columna)
				lw $t0, memoriaInicial
				lw $t1 filaActual
				lw $t2, columnaActual
				lw $t3, dimensiones 
				lw $t4, palabras  # Posible variable iterativa
				
				# Como nos movemos en la columna actualizamos				
				sub $t2, $t2, 1
								
				# Agregar verificaci�n si la columna es menor que cero
				bge $t2, $zero, seguirIzquierdo
				lw $s7 error
				
				li $v0, 4
				move $a0, $s7
				
				syscall
				jr $ra  # Saltamos
				
			seguirIzquierdo:
				sw $t2, columnaActual  # Actualizamos la posici�n de la columna actual	
				mul $t1, $t1, $t3  # Fila * dimensiones
				sll $t1, $t1, 2  # Multiplicamos * 4
				mul $t1, $t1 $t4  # Agregamos * palabras
								
				mul $t2, $t2, $t3 # dimension = dimension* columna
				
				add $t0, $t0 , $t1  # Direccion=DireccionInicial+ (palabras*fila*dimensiones*4)
				add $t0, $t0, $t2  # Direcci�n=Direcci�n + (dimensiones*columnas)
				
				sw $t0 otraMemoria  # Guardamos la memoria actual
				
				# Iniciamos el bucle para poder mover las cosas		
				
				li $t5, 0  # Variable iterativa del bucle de afuera		
				for1Izquierdo:
					li $t7, 0  # Para el bucle de adentro
					lw $t0 otraMemoria
					lw $t6 memoriaNegra 
					
					# Ajustamos las filas
					lw $t1 dimensiones
					sll $t1, $t1, 2
					mul $t1, $t1, $t5
					
					add $t0, $t0, $t1
					add $t6, $t6, $t1
					
					for2Izquierdo:						
						lw $t9 ($t0)  # Cargamos lo que est� a la izquierda
						lw $t8 ($t6)  # Cargamos lo que est� en el hueco negro
						nop
						nop
						
						# Intercambiamos
						sw $t9 ,($t6)  # Guardo donde est� el hueco negro
						sw $t8, ($t0)  # Guardo donde est� la imagen de la izquierdo
						nop
						nop
						
						# Ajustamos las direcciones de memoria
						addi $t6, $t6, 4 
						addi $t0, $t0, 4
						
						# Ajustamos la variable iterativa
						addi $t7, $t7, 1
						
						bne $t7, $t4, for2Izquierdo
					
					# Ajustamos la variable iterativa principal
					addi $t5, $t5, 1
					
					bne $t5, $t4, for1Izquierdo	
					
					# Actualizamos la direccion de memoria del hueco negro	
					lw $s0, otraMemoria  # Sacamos esa direcci�n
					sw $s0, memoriaNegra
						
			# Nos devolvemos a donde estabamos		
			jr $ra
				
			Derecha:
				# Calculo de la nueva direcci�n
				# Formula: direccion=DireccionHeap + (palbras*fila*dimensiones*4) + (dimensiones*columna)
				lw $t0, memoriaInicial
				lw $t1 filaActual
				lw $t2, columnaActual
				lw $t3, dimensiones 
				lw $t4, palabras  # Posible variable iterativa
				
				# Como nos movemos en la columna actualizamos				
				addi $t2, $t2, 1
								
				# Agregar verificaci�n si la columna es menor que cero
				blt $t2, 4, seguirDerecho
				lw $s7 error
				
				li $v0, 4
				move $a0, $s7
				
				syscall
				jr $ra  # Saltamos
				
			seguirDerecho:	
				sw $t2, columnaActual # Actualizamos la posici�n de la columna actual
				mul $t1, $t1, $t3  # Fila * dimensiones
				sll $t1, $t1, 2  # Multiplicamos * 4
				mul $t1, $t1 $t4  # Agregamos * palabras
								
				mul $t2, $t2, $t3 # dimension = dimension* columna
				
				add $t0, $t0 , $t1  # Direccion=DireccionInicial+ (palabras*fila*dimensiones*4)
				add $t0, $t0, $t2  # Direcci�n=Direcci�n + (dimensiones*columnas)
				
				sw $t0 otraMemoria  # Guardamos la memoria actual
				
				# Iniciamos el bucle para poder mover las cosas		
				
				li $t5, 0  # Variable iterativa del bucle de afuera		
				for1Derecho:
					li $t7, 0  # Para el bucle de adentro
					lw $t0 otraMemoria
					lw $t6 memoriaNegra 
					
					# Ajustamos las filas
					lw $t1 dimensiones
					sll $t1, $t1, 2
					mul $t1, $t1, $t5
					
					add $t0, $t0, $t1
					add $t6, $t6, $t1
					
					for2Derecho:						
						lw $t9 ($t0)  # Cargamos lo que est� a la izquierda
						lw $t8 ($t6)  # Cargamos lo que est� en el hueco negro
						nop
						nop
						
						# Intercambiamos
						sw $t9 ,($t6)  # Guardo donde est� el hueco negro
						sw $t8, ($t0)  # Guardo donde est� la imagen de la izquierdo
						nop
						nop
						
						# Ajustamos las direcciones de memoria
						addi $t6, $t6, 4 
						addi $t0, $t0, 4
						
						# Ajustamos la variable iterativa
						addi $t7, $t7, 1
						
						bne $t7, $t4, for2Derecho
					
					# Ajustamos la variable iterativa principal
					addi $t5, $t5, 1
					
					bne $t5, $t4, for1Derecho	
					
					# Actualizamos la direccion de memoria del hueco negro	
					lw $s0, otraMemoria  # Sacamos esa direcci�n
					sw $s0, memoriaNegra
						
			# Nos devolvemos a donde estabamos		
			jr $ra	
			
			Arriba:
				# Calculo de la nueva direcci�n
				# Formula: direccion=DireccionHeap + (palbras*fila*dimensiones*4) + (dimensiones*columna)
				lw $t0, memoriaInicial
				lw $t1 filaActual
				lw $t2, columnaActual
				lw $t3, dimensiones 
				lw $t4, palabras  # Posible variable iterativa
				
				# Como nos movemos en la fila actualizamos				
				sub $t1, $t1, 1
								
				# Agregar verificaci�n si la columna es menor que cero
				bge $t1, $zero, seguirArriba
				lw $s7 error
				
				li $v0, 4
				move $a0, $s7
				
				syscall
				jr $ra  # Saltamos
				
			seguirArriba:	
				sw $t1, filaActual # Actualizamos la posici�n de la fila actual
				mul $t1, $t1, $t3  # Fila * dimensiones
				sll $t1, $t1, 2  # Multiplicamos * 4
				mul $t1, $t1 $t4  # Agregamos * palabras
								
				mul $t2, $t2, $t3 # dimension = dimension* columna
				
				add $t0, $t0 , $t1  # Direccion=DireccionInicial+ (palabras*fila*dimensiones*4)
				add $t0, $t0, $t2  # Direcci�n=Direcci�n + (dimensiones*columnas)
				
				sw $t0 otraMemoria  # Guardamos la memoria actual
				li $t5, 0  # Variable iterativa del bucle de afuera	
					
				for1Arriba:
					li $t7, 0  # Para el bucle de adentro
					lw $t0 otraMemoria
					lw $t6 memoriaNegra 
					
					# Ajustamos las filas
					lw $t1 dimensiones
					sll $t1, $t1, 2
					mul $t1, $t1, $t5  # Multiplicamos las dimensiones por la variable iterativa
					
					# Ajustamos las direcciones de memoria
					add $t0, $t0, $t1
					add $t6, $t6, $t1
					
					for2Arriba:						
						lw $t9 ($t0)  # Cargamos lo que est� a la izquierda
						lw $t8 ($t6)  # Cargamos lo que est� en el hueco negro
						nop
						nop
						
						# Intercambiamos
						sw $t9 ,($t6)  # Guardo donde est� el hueco negro
						sw $t8, ($t0)  # Guardo donde est� la imagen de la izquierdo
						nop
						nop
						
						# Ajustamos las direcciones de memoria
						addi $t6, $t6, 4 
						addi $t0, $t0, 4
						
						# Ajustamos la variable iterativa
						addi $t7, $t7, 1
						
						bne $t7, $t4, for2Arriba
					
					# Ajustamos la variable iterativa principal
					addi $t5, $t5, 1
					
					bne $t5, $t4, for1Arriba	
					
					# Actualizamos la direccion de memoria del hueco negro	
					lw $s0, otraMemoria  # Sacamos esa direcci�n
					sw $s0, memoriaNegra
					
			# Nos devolvemos a donde estabamos		
			jr $ra	
			
			Abajo:
				# Calculo de la nueva direcci�n
				# Formula: direccion=DireccionHeap + (palbras*fila*dimensiones*4) + (dimensiones*columna)
				lw $t0, memoriaInicial
				lw $t1 filaActual
				lw $t2, columnaActual
				lw $t3, dimensiones 
				lw $t4, palabras  # Posible variable iterativa
				
				# Como nos movemos en la fila actualizamos				
				addi $t1, $t1, 1
								
				# Agregar verificaci�n si la columna es menor que cero
				ble $t1, 3, seguirAbajo
				lw $s7 error
				
				li $v0, 4
				move $a0, $s7
				
				syscall
				jr $ra  # Saltamos
				
			seguirAbajo:	
				sw $t1, filaActual # Actualizamos la posici�n de la fila actual
				mul $t1, $t1, $t3  # Fila * dimensiones
				sll $t1, $t1, 2  # Multiplicamos * 4
				mul $t1, $t1 $t4  # Agregamos * palabras
								
				mul $t2, $t2, $t3 # dimension = dimension* columna
				
				add $t0, $t0 , $t1  # Direccion=DireccionInicial+ (palabras*fila*dimensiones*4)
				add $t0, $t0, $t2  # Direcci�n=Direcci�n + (dimensiones*columnas)
				
				sw $t0 otraMemoria  # Guardamos la memoria actual
				li $t5, 0  # Variable iterativa del bucle de afuera	
					
				for1Abajo:
					li $t7, 0  # Para el bucle de adentro
					lw $t0 otraMemoria
					lw $t6 memoriaNegra 
					
					# Ajustamos las filas
					lw $t1 dimensiones
					sll $t1, $t1, 2
					mul $t1, $t1, $t5  # Multiplicamos las dimensiones por la variable iterativa
					
					# Ajustamos las direcciones de memoria
					add $t0, $t0, $t1
					add $t6, $t6, $t1
					
					for2Abajo:						
						lw $t9 ($t0)  # Cargamos lo que est� a la izquierda
						lw $t8 ($t6)  # Cargamos lo que est� en el hueco negro
						nop
						nop
						
						# Intercambiamos
						sw $t9 ,($t6)  # Guardo donde est� el hueco negro
						sw $t8, ($t0)  # Guardo donde est� la imagen de la izquierdo
						nop
						nop
						
						# Ajustamos las direcciones de memoria
						addi $t6, $t6, 4 
						addi $t0, $t0, 4
						
						# Ajustamos la variable iterativa
						addi $t7, $t7, 1
						
						bne $t7, $t4, for2Abajo
					
					# Ajustamos la variable iterativa principal
					addi $t5, $t5, 1
					
					bne $t5, $t4, for1Abajo	
					
					# Actualizamos la direccion de memoria del hueco negro	
					lw $s0, otraMemoria  # Sacamos esa direcci�n
					sw $s0, memoriaNegra
			
			# Nos devolvemos a donde estabamos		
			jr $ra							
		fin:
		li $v0, 10
		syscall
