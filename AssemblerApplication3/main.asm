.cseg

jmp reset
.org OC1Aaddr
jmp OCI1A_Interrupt

reset:
	.def temp = r16
	.def count = r17 
	.def andarAtual = r18 
	.def direcao = r19
	.def status = r20
	.def aguardando = r21

	.def terreo = r25
	.def primeiroAndar = r26
	.def segundoAndar = r27
	.def terceiroAndar = r28


	.equ Botao_Terro_Interno = PC0
	.equ Botao_Primeiro_Andar_Interno = PC1
	.equ Botao_Segundo_Andar_Interno = PC2
	.equ Botao_Terceiro_Andar_Interno = PC3
	.equ Botao_Abrir_Porta = PC4
	.equ Botao_Fechar_Porta = PC5

	.equ Botao_Terro_Externo = PD7
	.equ Botao_Primeiro_Andar_Externo = PD6
	.equ Botao_Segundo_Andar_Externo = PD5
	.equ Botao_Terceiro_Andar_Externo = PD4

	.equ LED = PB4
	.equ BUZZER = PB6
	
	.equ subindo = 2
	.equ descendo = 1
	.equ parado = 0
										

	//Inicialização da Pilha
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	// Pinos PB3, PB2, PB1, PB0, da porta B, utilizados para configuração do CI CD4511
	// Pino PB4 - Configurado como LED
	// Pino PB6 - Configurado como Buzzer
	ldi temp, 0b00001111
	out DDRB, temp
	
	// Inicia o Display com 0
	ldi temp, 0
	out PORTB, temp 

	//Define todos da porta C como Botões
	ldi temp, 0b00000000
	out DDRC, temp

	ldi temp, 0b00111111 // Carrega 00111111 em temp
	out PORTC, temp // Habilita pull-up em PC5, PC4, PC3, PC2, PC1 e PC0

	// Pinos PD7, PD6, PD5, PD4, da porta D, utilizados para Botões
	ldi temp, 0b00000000
	out DDRD, temp
	
	ldi temp, 0b11111111 ;Carrega 11111111 em temp
	out PORTD, temp  // Habilita pull-up em PD7, PD6, PD5, PD4


	// Definição Timer com 1 Segundo * Início *
	.equ ClockMHz = 16 ;16MHz
	.equ DelayMs = 20 ;20ms

	.equ TimerDelaySeg = 1
	.equ PreScaleDiv = 256
	.equ PreScaleMask = 0b100
	.equ TOP = int(0.5 + ((ClockMHz*1000000/PreScaleDiv)*TimerDelaySeg)); 1s --> TOP = 62500 com prescaler de 256
	.equ WGM = 0b0100 ; Configura o modo de operação do timer para CTC 

	ldi temp, high(TOP) ; Carregando TOP em OCR1A
	sts OCR1AH, temp
	ldi temp, low(TOP)
	sts OCR1AL, temp

	ldi temp, ((WGM&0b11)<<WGM10) ; Carrega WGM e PreScale
	sts TCCR1A, temp 
	ldi temp, ((WGM>> 2) << WGM12)|(PreScaleMask << CS10)
	sts TCCR1B, temp 

	lds temp, TIMSK1
	sbr temp, 1 <<OCIE1A
	sts TIMSK1, temp
	// Definição Timer com 1 Segundo * Fim *

	
	ldi count, 0 //Inicializa Contador em 0
	ldi status, parado //Inicializa status em 0

	rjmp main_lp

// Interrupção do timer, Sua função é incrementar o count a cada 1 segundo
OCI1A_Interrupt:
	push r16
	in r16, SREG
	push r16
	
	inc count
	
	pop r16
	out SREG, r16
	pop r16
	sei
	reti

// Efetuar um delay de 20ms
debounce:
	ldi r31, byte3(ClockMHz * 1000 * DelayMs / 5)
	ldi r30, high(ClockMHz * 1000 * DelayMs / 5)
	ldi r29, low(ClockMHz * 1000 * DelayMs / 5)
	
	subi r29, 1
	sbci r30, 0
	sbci r31, 0
	brcc pc-3
	
	ret

main_lp:
	sei

	sbic PINC, Botao_Terro_Interno   // Quando este botao for precionado aciona a rotina
	rjmp Botao_Terreo_Interno_Pressionado  

	sbic PINC, Botao_Primeiro_Andar_Interno // Quando este botao for precionado aciona a rotina 
	rjmp Botao_Primeiro_Andar_Interno_Pressionado 

	sbic PINC, Botao_Segundo_Andar_Interno  // Quando este botao for precionado aciona a rotina
	rjmp Botao_Segundo_Andar_Interno_Pressionado 

	sbic PINC, Botao_Terceiro_Andar_Interno  // Quando este botao for precionado aciona a rotina
	rjmp Botao_Terceiro_Andar_Interno_Pressionado

	sbic PINC, Botao_Terro_Externo  // Quando este botao for precionado aciona a rotina
	rjmp Botao_Terreo_Externo_Pressionado 

	sbic PIND, Botao_Primeiro_Andar_Externo // Quando este botao for precionado aciona a rotina
	rjmp Botao_Primeiro_Andar_Externo_Pressionado 

	sbic PIND, Botao_Segundo_Andar_Externo  // Quando este botao for precionado aciona a rotina
	rjmp Botao_Segundo_Andar_Externo_Pressionado 

	sbic PIND, Botao_Terceiro_Andar_Externo  // Quando este botao for precionado aciona a rotina
	rjmp Botao_Terceiro_Andar_Externo_Pressionado

	sbic PINC, Botao_Abrir_Porta // Quando este botao for precionado aciona a rotina
	jmp Botao_Abrir_Porta_Pressionado 

	sbic PINC, Botao_Fechar_Porta  // Quando este botao for precionado aciona a rotina
	jmp Botao_Fechar_Porta_Pressionado


	cpi aguardando, 1  // Verifica se registrador 'aguardando' está ativado, Se sim, desvia para a rotina
	breq aguardando1	

	cpi status, parado // Verifica se registrador 'status' está com o valor de parado, Se sim, desvia para a rotina
	breq parado1

	cpi status, subindo // Verifica se registrador 'status' está com o valor de subindo, Se sim, desvia para a rotina
	breq subindo1

	cpi status, descendo // // Verifica se registrador 'status' está com o valor de descendo, Se sim, desvia para a rotina
	breq descendo1


	aguardando1: // Pula para rotina de aguardando
	jmp Elevador_Aguardando

	parado1:  // Pula para rotina de parado
	jmp Elevador_Parado

	subindo1: // Pula para rotina de subindo
	jmp Elevador_subindo

	descendo1: // Pula para rotina de descendo
	jmp Elevador_Descendo

	rjmp main_lp



Botao_Terreo_Interno_Pressionado:
	call debounce              // Chama o delay de 20ms
	ldi temp, 0               // Define o Registrador 'temp', com o numero do andar pressionado
	ldi terreo, 1            // Marca o registrador 'terreo' como chamada interna, Prioridade
	cpi status, parado      // Verifica se o registrador 'status' está parado, se sim, aciona rotina 
	breq Inicia_Elevador
	rjmp main_lp          // Pula para o loop
	

Botao_Primeiro_Andar_Interno_Pressionado:
	call debounce                 // Chama o delay de 20ms  
	ldi temp, 1    			     // Define o Registrador 'temp', com o numero do andar pressionado
	ldi primeiroAndar, 1	    // Marca o registrador 'primeiroAndar' como chamada interna, Prioridade
	cpi status, parado  	   // Verifica se o registrador 'status' está parado, se sim, aciona rotina
	breq Inicia_Elevador
	rjmp main_lp 			 // Pula para o loop


Botao_Segundo_Andar_Interno_Pressionado:
	call debounce                 // Chama o delay de 20ms
	ldi temp, 2				     // Define o Registrador 'temp', com o numero do andar pressionado
	ldi segundoAndar, 1		    // Marca o registrador 'segundoAndar' como chamada interna, Prioridade
	cpi status, parado		   // Verifica se o registrador 'status' está parado, se sim, aciona rotina
	breq Inicia_Elevador
	rjmp main_lp			 // Pula para o loop


Botao_Terceiro_Andar_Interno_Pressionado:
	call debounce                    // Chama o delay de 20ms
	ldi temp, 3					    // Define o Registrador 'temp', com o numero do andar pressionado
	ldi terceiroAndar, 1		   // Marca o registrador 'terceiroAndar' como chamada interna, Prioridade
	cpi status, parado			  // Verifica se o registrador 'status' está parado, se sim, aciona rotina
	breq Inicia_Elevador
	rjmp main_lp				// Pula para o loop


Botao_Terreo_Externo_Pressionado:
	call debounce	             // Chama o delay de 20ms    
	ldi temp, 0			    	// Define o Registrador 'temp', com o numero do andar pressionado				
	cpi terreo, 1              // Verifica se o chamada do Terreo ja foi feita pelo botão interno
	breq Continue_Terreo      // Se foi feita, mantem a prioridade	
	ldi terreo, 2            // Se não, marca o registrador 'terreo' como chamada externa, sem Prioridade
	Continue_Terreo:
	cpi status, parado     // Verifica se o registrador 'status' está parado, se sim, aciona rotina
	breq Inicia_Elevador
	rjmp main_lp         // Pula para o loop
	

Botao_Primeiro_Andar_Externo_Pressionado:
	call debounce				         // Chama o delay de 20ms    
	ldi temp, 1					    	// Define o Registrador 'temp', com o numero do andar pressionado				
	cpi primeiroAndar, 1		       // Verifica se o chamada do primeiro andar ja foi feita pelo botão interno
	breq Continue_Primeiro_Andar      // Se foi feita, mantem a prioridade	
	ldi primeiroAndar, 2		     // Se não, marca o registrador 'primeiroAndar' como chamada externa, sem Prioridade
	Continue_Primeiro_Andar:
	cpi status, parado			   // Verifica se o registrador 'status' está parado, se sim, aciona rotina
	breq Inicia_Elevador
	rjmp main_lp				 // Pula para o loop


Botao_Segundo_Andar_Externo_Pressionado:
	call debounce			           // Chama o delay de 20ms    
	ldi temp, 2				          // Define o Registrador 'temp', com o numero do andar pressionado				
	cpi segundoAndar, 1		         // Verifica se o chamada do segundo andar ja foi feita pelo botão interno
	breq Continue_Segundo_Andar     // Se foi feita, mantem a prioridade	
	ldi segundoAndar, 2		       // Se não, marca o registrador 'segundoAndar' como chamada externa, sem Prioridade
	Continue_Segundo_Andar:
	cpi status, parado		     // Verifica se o registrador 'status' está parado, se sim, aciona rotina
	breq Inicia_Elevador
	rjmp main_lp			   // Pula para o loop


Botao_Terceiro_Andar_Externo_Pressionado:
	call debounce				        // Chama o delay de 20ms    
	ldi temp, 3					       // Define o Registrador 'temp', com o numero do andar pressionado				
	cpi terceiroAndar, 1		      // Verifica se o chamada do terceiro andar ja foi feita pelo botão interno
	breq Continue_Terceiro_Andar     // Se foi feita, mantem a prioridade	
	ldi terceiroAndar, 2		    // Se não, marca o registrador 'terceiroAndar' como chamada externa, sem Prioridade
	Continue_Terceiro_Andar:
	cpi status, parado			  // Verifica se o registrador 'status' está parado, se sim, aciona rotina
	breq Inicia_Elevador        
	rjmp main_lp				// Pula para o loop



Elevador_Parado:
	ldi count, 0  // Seta o valor do registrador 'count' como 0
	ldi status, parado // Seta o valor do registrador 'status' como Parado
	jmp main_lp

Inicia_Elevador:
	ldi count, 0         // Seta o valor do registrador 'count' como 0

	cp andarAtual, temp //Verifica se o valor do registrador 'andarAtual é IGUAL ao valor colocado em temp
	breq igual         // Valor de tempo definido por qual botão foi apertado  

	cp andarAtual, temp  //Verifica se o valor do registrador 'andarAtual é MAIOR ao valor colocado em temp
	brlo maior			// Valor de tempo definido por qual botão foi apertado  
						
	cp andarAtual, temp //Verifica se o valor do registrador 'andarAtual é MENOR ao valor colocado em temp
	brge menor		   // Valor de tempo definido por qual botão foi apertado  


	igual:
	ldi status, subindo // Se andaAtual for igual, mantem o status de 'MesmoAndar'
	jmp main_lp

	maior:
	ldi status, descendo  // Se andaAtual for maior, define o status para 'descendo'
	jmp main_lp

	menor:
	ldi status, subindo // Se andaAtual for menor, define o status para 'subindo'
	jmp main_lp



Elevador_Aguardando:
	sbi PORTB, LED // Acende o LEd

	cpi count, 5  // Quando se passarem 5 segundos e registrador 'aguardando' como 1,
	breq Ligar_Buzzer  // Ligar o BUZZER
	rjmp pula_buzzer

	Ligar_Buzzer:
	 sbi PORTB, BUZZER

	pula_buzzer:

	cpi count, 10 // Quando se passarem 10 segundos e registrador 'aguardando' como 1,
	breq Fechar_Porta // Chama rotina
	jmp main_lp 

	Fechar_Porta:
	cbi PORTB, LED          // Desliga o LED
	cbi PORTB, BUZZER	   // Desliga BUZZER
	ldi aguardando, 0     // Seta registrador 'aguardando' como 0
	ldi count, 0         // Seta registrador 'count' como 0
	jmp main_lp         // Pula para o loop



Elevador_subindo:
	cpi count, 3   // Quando registrador 'count' = 3, aciona rotina
	breq continue

	jmp main_lp  // Pula para o loop

	continue: // Rotina acionada

	cpi andarAtual, 0   // Caso andarAtual = Terreo
	breq Chegou_Primeiro_Andar

	cpi andarAtual, 1 // Caso andarAtual = Primeiro Andar
	breq Chegou_Segundo_Andar

	cpi andarAtual, 2 // Caso andarAtual = Segundo Andar
	breq Chegou_Terceiro_Andarl
	jmp main_lp

	Chegou_Terceiro_Andarl: // Caso andarAtual = Segundo Andar
	jmp Chegou_Terceiro_Andarl


Chegou_Primeiro_Andar:
	cpi  primeiroAndar, 1   // Caso primero andar esteja como prioridade
	breq Abrir_Primeiro_Andar

	cpi segundoAndar, 1    // Caso segundo andar esteja como prioridade
	breq Subir_Segundo_Andar

	cpi terceiroAndar, 1  // Caso terceiro andar esteja como prioridade
	breq Subir_Terceiro_Andar

	cpi terceiroAndar, 2 // Caso terceiro andar tenha sido pressionado como não prioridade
	breq Subir_Terceiro_Andar

	cpi segundoAndar, 2 // Caso segundo andar tenha sido pressionado como não prioridade
	breq Subir_Segundo_Andar

	cpi  primeiroAndar, 2 // Caso primeiro andar tenha sido pressionado como não prioridade
	breq Abrir_Primeiro_Andar

	cpi terreo, 1   // Caso terreo esteja como prioridade
	breq Descer_Terreo

	cpi terreo, 2 // Caso terro tenha sido pressionado como não prioridade
	breq Descer_Terreo

	inc andarAtual        // Incrementar o andar atual
	ldi primeiroAndar, 0 // Define o registrador 'primeiroAndar' como não pressionado
	ldi count, 0		   // Define o registrador 'count' como 0
	jmp Elevador_Parado // Pula para elevador parado

	Abrir_Primeiro_Andar:
		ldi aguardando, 1        // Define o registrador 'aguardando' como 1
		ldi primeiroAndar, 0    // Define o registrador 'primeiroAndar' como não pressionado
		ldi count, 0           // Define o registrador 'count' como 0
		ldi temp, 1           // Define o registrador 'temp' como 1
		out PORTB, temp      // Mostra no display o valor 1
		jmp main_lp         // Pula para o loop
	
	Subir_Segundo_Andar:	
		ldi count, 0             // Define o registrador 'count' como 0
		inc andarAtual          // Incrementar o andar atual
		out PORTB, andarAtual  // Mostra no display o valor 1
		jmp main_lp           // Pula para o loop

	Subir_Terceiro_Andar:
		ldi count, 0             // Define o registrador 'count' como 0
		inc andarAtual          // Incrementar o andar atual
		out PORTB, andarAtual  // Mostra no display o valor 1
		jmp main_lp           // Pula para o loop
	
	Descer_Terreo:
		inc andarAtual          // Incrementar o andar atual
		ldi count, 0		   // Define o registrador 'count' como 0
		ldi primeiroAndar, 0   // Define o registrador 'primeiroAndar' como não pressionado
		ldi status, descendo  // Define o registrador 'status' como descendo
		jmp main_lp          // Pula para o loop

Chegou_Segundo_Andar:
	
	cpi segundoAndar, 1  // Caso segundo andar esteja como prioridade
	breq Abrir_Segundo_Andar

	cpi terceiroAndar, 1  // Caso terceiro andar esteja como prioridade
	breq Subir_Terceiro_Andar2

	cpi terceiroAndar, 2  // Caso terceiro andar tenha sido pressionado como não prioridade
	breq Subir_Terceiro_Andar2

	cpi segundoAndar, 2  // Caso segundo andar tenha sido pressionado como não prioridade
	breq Abrir_Segundo_Andar

	cpi primeiroAndar, 1  // Caso terceiro andar esteja como prioridade
	breq Descer_Elevador2

	cpi primeiroAndar, 2  // Caso primeiro andar tenha sido pressionado como não prioridade
	breq Descer_Elevador2

	cpi terreo, 1   // Caso terreo esteja como prioridade
	breq Descer_Elevador2

	cpi terreo, 2   // Caso terreo tenha sido pressionado como não prioridade
	breq Descer_Elevador2

	inc andarAtual		  // Incrementar o andar atual
	ldi segundoAndar, 0	 // Define o registrador 'segundoAndar' como não pressionado
	ldi count, 0		   // Define o registrador 'count' como 0
	jmp Elevador_Parado // Pula para elevador parado

	Abrir_Segundo_Andar:
		ldi aguardando, 1        // Define o registrador 'aguardando' como 1
		ldi segundoAndar, 0	    // Define o registrador 'segundoAndar' como não pressionado
		ldi count, 0		   // Define o registrador 'count' como 0
		ldi temp, 2			  // Define o registrador 'temp' como 2
		out PORTB, temp		 // Mostra no display o valor 2
		jmp main_lp			// Pula para o loop
	
	Subir_Terceiro_Andar2:
		ldi count, 0		     // Define o registrador 'count' como 0
		inc andarAtual		    // Incrementar o andar atual
		out PORTB, andarAtual  // Mostra no display o valor 2
		jmp main_lp           // Pula para o loop
	
	Descer_Elevador2:
		inc andarAtual		       // Incrementar o andar atual
		ldi count, 0		      // Define o registrador 'count' como 0
		ldi segundoAndar, 0	     // Define o registrador 'segundoAndar' como não pressionado
		ldi status, descendo    // Define o registrador 'status' como descendo
		jmp main_lp            // Pula para o loop



Chegou_Terceiro_Andar:
	cpi terceiroAndar, 1  // Caso segundo andar esteja como prioridade
	breq Abrir_Terceiro_Andar3

	cpi terceiroAndar, 2 // Caso terceiro andar tenha sido pressionado como não prioridade
	breq Abrir_Terceiro_Andar3
	 
	cpi segundoAndar, 1  // Caso segundo andar esteja como prioridade
	breq Descer_Elevador3

	cpi segundoAndar, 2 // Caso segundo andar tenha sido pressionado como não prioridade
	breq Descer_Elevador3

	cpi primeiroAndar, 1 // Caso primeiro andar esteja como prioridade
	breq Descer_Elevador3

	cpi primeiroAndar, 2 // Caso primeiro andar tenha sido pressionado como não prioridade
	breq Descer_Elevador3

	cpi terreo, 1   // Caso terreo  esteja como prioridade
	breq Descer_Elevador3

	cpi terreo, 2 // Caso terreo tenha sido pressionado como não prioridade
	breq Descer_Elevador3

	inc andarAtual		    // Incrementar o andar atual
	ldi terceiroAndar,  0  // Define o registrador 'terceiroAndar' como não pressionado
	ldi count, 0		   // Define o registrador 'count' como 0
	jmp Elevador_Parado   // Pula para elevador parado


	Abrir_Terceiro_Andar3:
		ldi aguardando, 1	        // Define o registrador 'aguardando' como 1
		ldi terceiroAndar,  0      // Define o registrador 'terceiroAndar' como não pressionado
		ldi count, 0		      // Define o registrador 'count' como 0
		ldi temp, 3			     // Define o registrador 'temp' como 3
		out PORTB, temp		    // Mostra no display o valor 3
		jmp main_lp            // Pula para o loop

	Descer_Elevador3:
		inc andarAtual		      // Incrementar o andar atual
		ldi count, 0		     // Define o registrador 'count' como 0
		ldi terceiroAndar, 0    // Define o registrador 'terceiroAndar' como não pressionado
		ldi status, descendo   // Define o registrador 'status' como descendo
		jmp main_lp			  // Pula para o loop




Elevador_Descendo:
	cpi count, 3  // Quando registrador 'count' = 3, aciona rotina
	breq continue1 

	jmp main_lp   // Pula para o loop

	continue1:  // Rotina acionada

	cpi andarAtual, 3  // Caso andarAtual = Terceiro Andar
	breq Chegou_Segundo_Andar1

	cpi andarAtual, 2 // Caso andarAtual = Segundo Andar
	breq Chegou_Primeiro_Andar1

	cpi andarAtual, 1 // Caso andarAtual = Primeiro Andar
	breq Chegou_Terreo_Andar1l
	jmp main_lp

	Chegou_Terreo_Andar1l:  // Caso andarAtual = Primeiro Andar
	jmp Chegou_Terreo_Andar1


Chegou_Segundo_Andar1:
	cpi segundoAndar, 1  // Caso segundo andar esteja como prioridade
	breq Abrir_Segundo_Andar4

	cpi segundoAndar, 2 // Caso segundo andar tenha sido pressionado como não prioridade
	breq Abrir_Segundo_Andar4

	cpi primeiroAndar, 1  // Caso primeiro andar esteja como prioridade
	breq Descer_Primeiro_Andar

	cpi primeiroAndar, 2 // Caso primeiro andar tenha sido pressionado como não prioridade
	breq Descer_Primeiro_Andar

	cpi terreo, 1  // Caso terreo esteja como prioridade
	breq Descer_Terreo2

	cpi terreo, 2  // Caso terreo esteja como prioridade
	breq Descer_Terreo2

	cpi terceiroAndar, 1  // Caso tereiro andar esteja como prioridade
	breq Subir

	cpi terceiroAndar, 2 // Caso terceiro andar tenha sido pressionado como não prioridade
	breq Subir

	dec andarAtual		   // Decrementa o andar atual
	ldi segundoAndar,  0  // Define o registrador 'segundoAndar' como não pressionado
	ldi count, 0		   // Define o registrador 'count' como 0
	jmp Elevador_Parado  // Pula para elevador parado



	Abrir_Segundo_Andar4:
		ldi aguardando, 1          // Define o registrador 'aguardando' como 1
		ldi segundoAndar, 0	      // Define o registrador 'segundoAndar' como não pressionado
		ldi count, 0		     // Define o registrador 'count' como 0
		ldi temp, 2			    // Define o registrador 'temp' como 2
		out PORTB, temp		   // Mostra no display o valor 2
		jmp main_lp			  // Pula para o loop

	Descer_Primeiro_Andar:
		ldi count, 0              // Define o registrador 'count' como 0
		dec andarAtual		     // Decrementa o andar atual
		out PORTB, andarAtual   // Mostra no display o valor 2
		jmp main_lp       	   // Pula para o loop

	Descer_Terreo2:
		ldi count, 0              // Define o registrador 'count' como 0
		dec andarAtual		     // Decrementa o andar atual
		out PORTB, andarAtual   // Mostra no display o valor 2
		jmp main_lp			   // Pula para o loop

	Subir:
		dec andarAtual         // Decrementa o andar atual
		ldi count, 0		   // Define o registrador 'count' como 0
		ldi segundoAndar, 0   // Define o registrador 'terceiroAndar' como não pressionado
		ldi status, subindo  // Define o registrador 'status' como subindo
		jmp main_lp		    // Pula para o loop
						   


Chegou_Primeiro_Andar1:
	cpi primeiroAndar, 1  // Caso primeiro andar esteja como prioridade
	breq Abrir_Primeiro_Andar5

	cpi primeiroAndar, 2  // Caso primeiro andar tenha sido pressionado como não prioridade
	breq Abrir_Primeiro_Andar5

	cpi terreo, 1        // Caso terreo esteja como prioridade
	breq Descer_Terreo1

	cpi terreo, 2         // Caso terreo tenha sido pressionado como não prioridade
	breq Descer_Terreo1

	cpi segundoAndar, 1  // Caso segundo andar esteja como prioridade
	breq Subir1

	cpi segundoAndar, 2  // Caso segundo andar tenha sido pressionado como não prioridade
	breq Subir1

	cpi terceiroAndar, 1  // Caso terceiro andar esteja como prioridade
	breq Subir1

	cpi terceiroAndar, 2  // Caso terceiro andar tenha sido pressionado como não prioridade
	breq Subir1

	dec andarAtual            // Decrementa o andar atual
	ldi primeiroAndar,  0	 // Define o registrador 'primeiroAndar' como não pressionado
	ldi count, 0            // Define o registrador 'count' como 0
	jmp Elevador_Parado	   // Pula para elevador parado


	Abrir_Primeiro_Andar5:
		ldi aguardando, 1          // Define o registrador 'aguardando' como 1
		ldi primeiroAndar, 0      // Define o registrador 'primeiroAndar' como não pressionado
		ldi count, 0		     // Define o registrador 'count' como 0
		ldi temp, 1			    // Define o registrador 'temp' como 1
		out PORTB, temp		   // Mostra no display o valor 1
		jmp main_lp			  // Pula para o loop

	Descer_Terreo1:
		ldi count, 0             // Define o registrador 'count' como 0
		dec andarAtual		    // Decrementa o andar atual
		out PORTB, andarAtual  // Mostra no display o valor 1
		jmp main_lp			  // Pula para o loop

	Subir1:
		dec andarAtual            // Decrementa o andar atual
		ldi count, 0		     // Define o registrador 'count' como 0
		ldi primeiroAndar, 0    // Define o registrador 'primeiroAndar' como não pressionado
		ldi status, subindo	   // Define o registrador 'status' como subindo
		jmp main_lp			  // Pula para o loop



Chegou_Terreo_Andar1:
	cpi terreo, 1 // Caso primeiro andar esteja como prioridade
	breq Abrir_Terreo

	cpi terreo, 2  // Caso terreo tenha sido pressionado como não prioridade
	breq Abrir_Terreo

	cpi primeiroAndar, 1  // Caso primeiro andar esteja como prioridade
	breq subir2

	cpi primeiroAndar, 2   // Caso primeiro andar tenha sido pressionado como não prioridade
	breq subir2

	cpi segundoAndar, 1  // Caso primeiro andar esteja como prioridade
	breq subir2

	cpi segundoAndar, 2   // Caso primeiro andar tenha sido pressionado como não prioridade
	breq subir2

	cpi terceiroAndar, 1  // Caso primeiro andar esteja como prioridade
	breq subir2

	cpi terceiroAndar, 2   // Caso primeiro andar tenha sido pressionado como não prioridade
	breq subir2
	
	dec andarAtual         // Decrementa o andar atual
	ldi terreo,  0		  // Define o registrador 'terreo' como não pressionado
	ldi count, 0 		 // Define o registrador 'count' como 0
	jmp Elevador_Parado	// Pula para elevador parado

	Abrir_Terreo:
		ldi aguardando, 1       // Define o registrador 'aguardando' como 1
		ldi terreo, 0	       // Define o registrador 'terreo' como não pressionado
		ldi count, 0	      // Define o registrador 'count' como 0
		ldi temp, 0		     // Define o registrador 'temp' como 0
		out PORTB, temp	    // Mostra no display o valor 0
		jmp main_lp		   // Pula para o loop

	subir2:
		dec andarAtual		     // Decrementa o andar atual
		ldi count, 0		    // Define o registrador 'count' como 0
		ldi terreo, 0		   // Define o registrador 'terreo' como não pressionado
		ldi status, subindo   // Define o registrador 'status' como subindo
		jmp main_lp          // Pula para o loop


Botao_Abrir_Porta_Pressionado:
	jmp main_lp 

Botao_Fechar_Porta_Pressionado:
	cbi PORTB, LED          // Desliga o LED
	cbi PORTB, BUZZER	   // Desliga BUZZER
	ldi aguardando, 0     // Define registrador 'aguardando'' como 0
	ldi count, 0         // Define o registrador 'count' como 0
	jmp main_lp         // Pula para o loop