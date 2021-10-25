# The whole programs works in 4 sections just as asked in the Task
.data

matrix1_buffer: .space 1000
matrix2_buffer: .space 1000
matrix3_buffer: .space 1000

matrix1_file: .asciiz "mat1.txt"
matrix2_file: .asciiz "mat2.txt"
matrix3_file: .asciiz "mat3.txt"

readErrorMsg: .asciiz "\nError in reading from file\n"
openErrorMsg: .asciiz "\nError in opening file\n"

.text

main:
# Section 1: Here we open and read from the the files mat1.txt and mat2.txt and then close them.
# Open mat1.txt
	li $v0, 13 # Open file command
	la $a0, matrix1_file # File to open
	li $a1, 0 # Open to read
	li $a2, 0                           
	syscall
	
	bltz $v0, openError # If negative number then there is an error      
	move $s0, $v0 # Save file descriptor    

# Read mat1.txt
	li $v0, 14 # Read from file command        
	move $a0, $s0 # Set file descriptor           
	la $a1, matrix1_buffer # Address of output buffer          
	li $a2, 1000 # Hardcoded buffer length        
	syscall 
	            
	bltz $v0, readError  
	
# Close file mat1.txt
	li   $v0, 16 # Close operation      
	move $a0, $s0 # matrix.txt decriptor
	syscall 

# Open mat2.txt
	li $v0, 13 # Open file command  
	la $a0, matrix2_file # File to open     
	li $a1, 0 #Open to read     
	li $a2, 0                      
	syscall
	
	bltz $v0, openError # If negative number then there is an error     
	move $s0, $v0 # Save file descriptor   

# Read mat2.txt
	li $v0, 14 # Read from file command         
	move $a0, $s0  # Set file descriptor       
	la $a1, matrix2_buffer # Address of output buffer      
	li $a2, 1000 # Hardcoded buffer length        
	syscall   
	          
	bltz $v0, readError  
	
# Close file mat2.txt
	li   $v0, 16 # Close operation        
	move $a0, $s0 # matrix.txt decriptor      
	syscall

# Section 2: Here we check the size of the matrix and according to that we allocate memory dinamically with syscall 9,
# then we convert both matricies from string to integers (word) for stage 3 (multiplication).
# Start counting columns to know size of matrix
	move $s0, $0 # Columns counter
	la $t1, matrix1_buffer # Get Start of matrix1_buffer address and save in temporary
	subi $t1, $t1, 1

countColumns:
	addi $t1, $t1, 1 # Go further in buffer
	lbu $t2, ($t1) # Get byte from buffer
	beq $t2, ' ', increaseCounter # If new btye == space
	bne $t2, '\n', countColumns # If new btye != new line 

# Calculate array bit size
	mul $a0, $s0, $s0 # Rows*Columns = number of elements
	sll $a0, $a0, 2 # Multiply number of elements by 2^2 = 4

# Create matrix 1
	li  $v0, 9 # Allocate heap memory
	syscall
	move $s1, $v0 # Save matrix 1 in $s1

# Create matrix 2
	li  $v0, 9 # Allocate heap memory
	syscall
	move $s2, $v0 # Save matrix 2 in $s2

# Create matrix 3
	li  $v0, 9 # Allocate heap memory
	syscall
	move $s3, $v0 # Save matrix 3 in $s3

# Transfer data from matrix1_buffer to matrix1
	move $t0, $0 # Initialize number to 0
	la $t1 matrix1_buffer # Get Start of matrix1_buffer address and save in temporary
	subi $t1, $t1, 1 # Go back by one bit to fit loop
	la $t2, ($s1) # Get Start of matrix1 address and save in temporary
	addi $t3, $0, 1 # Multiply number
	addi $t5, $0, 10 # Save 10 as temporary

convertFileToMatrix1:
	addi $t1, $t1, 1 # Go further in buffer
	lbu $t4, ($t1) # Get byte from buffer
	
	beq $t4, 0, end1  # End of buffer
	beq $t4, ' ', addNumberToMatrix1 # If new btye == space
	beq $t4, '\n', convertFileToMatrix1 # If new btye == new line 
	blt $t4, '0', convertFileToMatrix1 # If new byte < 0 in ascii form
	bgt $t4, '9', convertFileToMatrix1 # If new byte > 9 in ascii form

	subi $t4, $t4, 48 # Reduce 48 from number in ascii form
	mul $t0, $t0, $t3 # Multiply number by 1 or 10
	add $t0, $t0, $t4 # Add new number to current number
	move $t3, $t5 # Change multiply amount to 10
	j convertFileToMatrix1

end1:
# Transfer data from matrix2_buffer to matrix2
	move $t0, $0 # Initialize number to 0
	la $t1 matrix2_buffer # Get Start of matrix2_buffer address and save in temporary
	subi $t1, $t1, 1 # Go back by one bit to fit loop
	la $t2, ($s2) # Get Start of matrix2 address and save in temporary
	addi $t3, $0, 1 # Multiply number

convertFileToMatrix2:
	addi $t1, $t1, 1 # Go further in buffer
	lbu $t4, ($t1) # Get byte from buffer

	beq $t4, 0, end2  # End of buffer
	beq $t4, ' ', addNumberToMatrix2 # If new btye == space
	beq $t4, '\n', convertFileToMatrix2 # If new btye == new line 
	blt $t4, '0', convertFileToMatrix2 # If new byte < 0 in ascii form
	bgt $t4, '9', convertFileToMatrix2 # If new byte > 9 in ascii form

	subi $t4, $t4, 48 # Reduce 48 from number in ascii form
	mul $t0, $t0, $t3 # Multiply number by 1 or 10
	add $t0, $t0, $t4 # Add new number to current number
	move $t3, $t5 # Change multiply amount to 10
	j convertFileToMatrix2

end2:
# Section 3: Here we multiply matrix 1 by 2 and inster the result into matrix 3.
# The thought proccess of the code can also be seen as such:
# for (int i = 0; i < 10; i++)
#{
#	for (int j = 0; j < 10; j++)
#	{
#		for (int k = 0; k < 10; k++)
#		{
#			sum += matrixOne[i][k] * matrixTwo[k][j];
#		}
#
#		matrixThree[i][j] = sum;
#		sum = 0;
#	}
#}
# It really helped looking a simple code from c++ to understand how to write it mips.
# Initialize matrix3 = matrix1 * matrix2
	move $t0, $0 # Number Sum
	addi $s4, $0, 4 # Save word length
	mul $s4, $s4, $s0 # Length of whole row
	mul $t9, $s4, $s0 # Size of whole array

	la $t1, ($s1) # Get Start of matrix1 address and save in temporary				
	la $t2, ($s2) # Get Start of matrix2 address and save in temporary
	la $t3, ($s3) # Get Start of matrix3 address and save in temporary

	sub $t4, $0, 1 # Index i = -1
 
loop_i:
	addi $t4, $t4, 1 # i++
	subi $t5, $0, 1 # Index j = -1

	blt $t4, $s0, loop_j # If i < rows/columns size
	j end3

loop_j:
	addi $t5, $t5, 1 # j++
	move $t6, $0 # Index k = 0

	blt $t5, $s0, loop_k # If j < rows/columns size
	add $t1, $t1, $s4 # Move to next row
	sub $t2, $t2, $s4 # reset matrix2 address
	j loop_i 

loop_k:
	addi $t6, $t6, 1 # k++

	lw $t7, ($t1) # Load matrix1[i][k]
	lw $t8, ($t2) # Load matrix2[k][j]
	mul $t7, $t7, $t8 # temporary = matrix1[i][k]*matrix2[k][j]
	add $t0, $t0, $t7 # sumn += temporary
	addi $t1, $t1, 4 # matrix1 next column
	add $t2, $t2, $s4 # matrix2 next row

	blt $t6, $s0, loop_k # If k < rows/columns size

	sw $t0, ($t3) # matrix3[i][j] = sum
	addi $t3, $t3, 4 # matrix3 address++
	move $t0, $0 # sum = 0

	sub $t1, $t1, $s4 # Reset matrix1 address
	sub $t2, $t2, $t9 # reset matrix2 address
	addi $t2, $t2, 4 # Move to next column

	j loop_j

end3:
# Section 4: Here we convert matrix 3 from integer (word) to string,
# and then open a new file for writing and write the string buffer into the file.
# Transfer data from array matrix3 to matrix3_buffer
	la $t0, ($s3) # Save matrix3 address to a temporary
	la $t1, matrix3_buffer # Save matrix3 buffer address
	subi $t2, $0, 1 # i = -1
	addi $t4, $0, 10 # Space in ascii
	addi $t5, $0, 32 # New line in ascii
	addi $t8, $0, 1 # Devision amount
	move $t9, $t8 # Save the number 1

initializeMatrix3BufferLoop1:
	addi $t2, $t2, 1 # i++
	subi $t3, $0, 1 # j = -1
	blt $t2, $s0, initializeMatrix3BufferLoop2 # If i < rows\columns size, jump
	j initializeMatrix3File
	
initializeMatrix3BufferLoop2:	
	addi $t3, $t3, 1 # j++
	lw $t6, ($t0) # Get number for matrix 3
	
	blt $t3, $s0, itoa # If j < rows\columns size, jump
	
	sb $t4, ($t1) # Store new line into buffer
	addi $t1, $t1, 1 # buffer adress++
	
	j initializeMatrix3BufferLoop1

itoa:
	div $t6, $t8 # Current number / 10
	mflo $t7 # Qoutient
	
	mul $t8, $t8, $t4 # Increase devision amount by 10
	bge $t7, $t4, itoa # If Qoutient >= 10, jump
	div $t8, $t8, $t4 # Decrease devision amount by 10
	
itoaRemainder:
	addi $t7, $t7, 48 # Turn into ascii form
	sb $t7, ($t1) # Store number into buffer
	addi $t1, $t1, 1 # buffer adress++
	
	div $t8, $t8, $t4 # Decrease devision amount by 10
	div $t7, $t6, $t8 # Current number = current number / 10000, 1000, 100, 10, 1
	
	div $t7, $t4 # Current number / 10
	mfhi $t7 #Remainder
	
	bgt $t8, $t9, itoaRemainder # if Devision number > 1, jump
	
	addi $t7, $t7, 48 # Turn into ascii form
	sb $t7, ($t1) # Store number into buffer
	addi $t1, $t1, 1 # buffer adress++
	
	sb $t5, ($t1) # Store space into buffer
	addi $t1, $t1, 1 # buffer adress++
	
	addi $t0, $t0, 4 # matrix 3 address++
	move $t8, $t9 # Reset Devision number to 1
	j initializeMatrix3BufferLoop2

# Create mat3.txt file
initializeMatrix3File:
# Open mat3.txt file
	li $v0, 13 # Open file operation
	la $a0, matrix3_file # File name
	li $a1, 1 # Open for writing
	li $a2, 0 # Mode is ignored
	syscall
	bltz $v0, openError # If negative number then there is an error  
	move $s5, $v0 # Save file descriptor 

# Write to mat3.txt file
	li   $v0, 15       # system call for write to file
	move $a0, $s5      # file descriptor 
	la   $a1, matrix3_buffer   # address of buffer from which to write
	li   $a2, 1000       # hardcoded buffer length
	syscall            # write to file

# Close file mat3.txt
	li   $v0, 16 # Close operation        
	move $a0, $s3 # matrix.txt decriptor      
	syscall
	
endProgram:
	li $v0, 10 # Terminate executaion
	syscall

increaseCounter:
	addi $s0, $s0, 1 # Counter++
	j countColumns

addNumberToMatrix1:
	sw $t0, ($t2) # Store number into matrix1
	addi $t2, $t2, 4 # Go to next address in matrix1
	addi $t3, $0, 1 # Reset multiply number
	move $t0, $0 # Reset number to 0
	j convertFileToMatrix1

addNumberToMatrix2:
	sw $t0, ($t2) # Store number into matrix2
	addi $t2, $t2, 4 # Go to next address in matrix2
	addi $t3, $0, 1 # Reset multiply number
	move $t0, $0 # Reset number to 0
	j convertFileToMatrix2

openError:
	li $v0, 4 # Print string
	la $a0, openErrorMsg # Set string
	syscall
	j endProgram

readError:
	li $v0, 4 # Print string
	la $a0, readErrorMsg # Set string
	syscall
	j endProgram
