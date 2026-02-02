stm8/

    #include "mapping.inc"
    #include "stm8s105c_s.inc"

    ; variables ram
    segment 'ram1'
rom_buffer  ds.b 8          ; tableau pour l'id
bit_counter ds.b 1          ; compteur de bits
byte_counter ds.b 1         ; compteur d'octets

    ; code principal
    segment 'rom'

debut
    ; config horloge
    ; force a 16mhz pour le timing
    mov CLK_CKDIVR, #$00

    ; config leds
    ; pd2 verte et pd3 rouge en sortie
    bset PD_DDR, #2
    bset PD_DDR, #3
    bset PD_CR1, #2
    bset PD_CR1, #3
    
    ; eteint tout au debut
    bres PD_ODR, #2
    bres PD_ODR, #3

    ; config 1-wire
    ; pa3 en mode open drain simule
    bres PA_ODR, #3
    bres PA_CR1, #3

main_loop
    ; etape 1 reset
    ; verifie si un bouton est la
    call reset_bus
    jrc no_device

    ; etape 2 commande
    ; envoie 0x33 pour lire la rom
    ld A, #$33
    call write_byte

    ; etape 3 lecture
    ; lit les 8 octets de l'id
    ldw X, #rom_buffer
    ld A, #8
    ld byte_counter, A
    
read_loop_rom:
    call read_byte
    ld (X), A
    incw X
    
    ld A, byte_counter
    dec A
    ld byte_counter, A
    jrne read_loop_rom

    ; etape 4 validation
    ; regarde si le premier octet est 0x01
    ld A, rom_buffer
    cp A, #$01
    jrne code_invalid

code_valid:
    ; acces autorise
    ; allume la led verte pd2
    bset PD_ODR, #2
    bres PD_ODR, #3
    jra end_loop

code_invalid:
    ; acces refuse
    ; allume la led rouge pd3
    bres PD_ODR, #2
    bset PD_ODR, #3

end_loop:
    ; petite pause avant de recommencer
    ldw X, #$FFFF
    call delay_X
    jra main_loop

no_device:
    ; rien connecte
    ; eteint tout et attend un peu
    bres PD_ODR, #2
    bres PD_ODR, #3
    ldw X, #5000
    call delay_X
    jra main_loop


; fonctions 1-wire

reset_bus
    ; tire la ligne basse 480us
    bset PA_DDR, #3
    ldw X, #2600
    call delay_X
    
    ; relache et attend 70us
    bres PA_DDR, #3
    ldw X, #380
    call delay_X
    
    ; verifie la presence
    btjf PA_IDR, #3, pres_ok
    scf
    jra reset_fin
pres_ok:
    rcf
reset_fin:
    ; attend la fin du slot
    ldw X, #2200
    call delay_X
    ret

write_byte
    ; ecrit un octet bit par bit
    mov bit_counter, #8
wb_loop:
    rrc A
    jrnc write_0
    
    ; ecriture de 1
    bset PA_DDR, #3
    nop
    nop
    nop
    bres PA_DDR, #3
    ldw X, #320
    call delay_X
    jra wb_next

write_0:
    ; ecriture de 0
    bset PA_DDR, #3
    ldw X, #320
    call delay_X
    bres PA_DDR, #3
    ldw X, #10
    call delay_X

wb_next:
    dec bit_counter
    jrne wb_loop
    ret

read_byte
    ; lit un octet bit par bit
    mov bit_counter, #8
    clr A
rb_loop:
    ; debut du slot
    bset PA_DDR, #3
    nop
    nop
    bres PA_DDR, #3
    
    ; attente avant echantillonnage
    ; boucle locale pour etre precis
    push A
    ld A, #20
wait_sample:
    dec A
    jrne wait_sample
    pop A
    
    ; lecture de la pin
    rcf
    btjf PA_IDR, #3, bit_is_0
    scf
bit_is_0:
    rrc A
    
    ; fin du slot
    pushw X
    ldw X, #250
    call delay_X
    popw X
    
    dec bit_counter
    jrne rb_loop
    ret

delay_X
    decw X
    jrne delay_X
    ret

    segment 'vectit'
    dc.l {$82000000+debut}

    end
