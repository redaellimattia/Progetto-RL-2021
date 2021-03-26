# Prova Finale di reti logiche 2021.
## Presentazione del progetto
L’obiettivo del progetto è quello di scrivere un programma VHDL che simuli il comportamento di una rete logica capace di equalizzare l’istogramma di immagini in toni di grigio, ovvero ricalibrare il contrasto.
<p align="center">
  <img width="635" height="295" src="/Doc/img/esempio.png">
</p>
## Scelte progettuali
Si è scelto di implementare la macchina sopra descritta utilizzando un’architettura di tipo behavioural composta di un solo processo.  
Ad ogni ciclo di clock il segnale **CURR_S** determina lo stato di esecuzione corrente in base all’assegnamento eseguito al ciclo di clock precedente. Tutti i segnali vengono aggiornati in questo modo e ciò ha reso necessario l’inserimento di due stati adibiti alla semplice attesa affinchè i segnali possano aggiornarsi correttamente (WAIT_UPDATE, WAIT_READ).
Inoltre, per lo stesso motivo, si è deciso di utilizzare delle variabili a supporto di alcune operazioni (queste sono infatti aggiornate immediatamente dopo l’assegnamento di valore), tra cui:
* **pixel_counter**: Un contatore per tenere traccia dello stato di avanzamento dell’esecuzione;
* **delta_value, delta_int, temp**: Variabili a supporto del calcolo del valore nuovo pixel.

Per la lettura e la scrittura in memoria si utilizza un segnale di supporto **ADDRESS**, che ogni volta viene inizializzato all’indirizzo di memoria necessario in quel momento dell’esecuzione.  
Per quanto riguarda l’implementazione dell’algoritmo per il calcolo del nuovo valore del pixel, sono state fatte alcune considerazioni tenendo conto della necessità di sintetizzare il componente.  
In primis, per implementare il secondo passo, è stato usato un controllo a soglia che sostituisce a pieno la funzione descritta sopra e calcola lo shift_level;
Mentre per effettuare l’operazione di shift 􀀀 left ed ottenere temp_pixel, per poter rappresentare a pieno tutta la scala di valori possibili, è stato utilizzato un segnale di tipo vettore di 16 bit (caso pessimo: pixel valore 255 shiftato di 8 bit), che viene "composto"
concatenando i singoli bit.
Poi, per la funzione di min(255; temp_pixel), viene controllato se il valore di temp_pixel
sia superiore a 255 (in quel caso viene utilizzato 255), oppure si utilizza temp_pixel(7
down to 0).

## Testing
Il componente ha passato diversi casi di test descritti dettagliatamente [qui](/Doc/relazione.pdf).  
Le singole immagini dei risultati dei test sono consultabili [qui](/Code_And_Tests/Tests).

## Conclusione
In conclusione, il risultato del lavoro é un componente sintetizzabile e correttamente simulabile in post-sintesi, con un totale di **305 Look Up Tables** (copertura del 0.23%) e un totale di **145 Flip Flop** (copertura del 0.05%).  
La macchina a stati finiti composta da 12 stati, si ritiene esegua correttamente l’implementazione dell’algoritmo descritto nelle specifiche, avendo passato i casi di test limite e la computazione di decina di migliaia di immagini in sequenza.

Il codice é consultabile [qui](/Code_And_Tests/project_reti_logiche.vhd).
