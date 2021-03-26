----------------------------------------------------------------------------------
--
-- Prova Finale (Progetto di Reti Logiche)
-- Prof. Gianluca Palermo - Anno Accademico 2020/2021
--
-- Gabriele Rivi (Codice Persona: 10663569  Matricola: 910564)
-- Mattia Redaelli (Codice Persona: 10622823  Matricola: 907429)
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type STATUS is (RST,SET_ADDRESS,WAIT_UPDATE,WAIT_READ,GET_VALUE,CALC_SHIFT_LEVEL,SET_READ,NEW_PIXEL,SET_WRITE,WRITE,DONE,IDLE);
    
    signal CURR_S :STATUS; --Current state
    signal ADDRESS :std_logic_vector(15 downto 0);
    signal rows,columns,min,max,new_pixel_value :std_logic_vector(7 downto 0);
    signal num_pixel,temp_pixel :std_logic_vector(15 downto 0); --Number of total pixels in the image
    signal shift_level :std_logic_vector(3 downto 0);
    signal row_check,column_check,pixel_counter_check, from_SET_ADDRESS,from_SET_READ,from_SET_WRITE :std_logic; --Boolean values to help with the transition from a state to another
  
begin
    equalization :process (i_clk)
    --needed variables for instant operation, to avoid waiting for a clock round
    variable delta_value, temp : std_logic_vector(7 downto 0);
    variable delta_int : integer;
    variable pixel_counter :std_logic_vector(15 downto 0);
    
    begin
        if (rising_edge(i_clk)) then
            if (i_rst = '1') then
                CURR_S <= RST;
            elsif (i_rst = '0') then   
                         
                case CURR_S is
                    when RST =>         --Reset state: initialize all signals and variable to a default value
                                        ADDRESS <= "0000000000000000"; --RAM Address, 16 bit  
                                        rows <= "00000000"; --Rows number
                                        columns <= "00000000"; --Columns number
                                        min <= "11111111"; --Min pixel value
                                        max <= "00000000"; --Max pixel value
                                        new_pixel_value <= "00000000";
                                        temp_pixel <= "0000000000000000"; --Temp_pixel value
                                        num_pixel <= "0000000000000000"; --Processed pixels
                                        shift_level <= "0000";
                                        pixel_counter := "0000000000000000"; --Processed pixels
                                        delta_value := "00000000"; --Reset delta_value
                                        temp := "00000000"; --Reset temp value 
                                        delta_int := 0;
                                        row_check <= '0';
                                        column_check <= '0';
                                        pixel_counter_check <= '0';
                                        from_SET_ADDRESS <= '0';
                                        from_SET_READ <= '0';
                                        from_SET_WRITE <= '0';
                                        o_done <= '0';
                                        if (i_start = '1') then     --On i_start signal, start processing the image
                                            o_en <= '1'; --Enable RAM access           
                                            o_we <= '0';       
                                            CURR_S <= SET_ADDRESS;                                        
                                        end if;
                                        
                    when SET_ADDRESS => --Update ADDRESS in order to read rows and columns number on RAM, then to scan pixel values
                                        from_SET_ADDRESS <= '1';
                                        if(pixel_counter_check = '0' AND column_check = '1') then
                                            ADDRESS <= ADDRESS + 1; --Address increment
                                        else
                                            if(column_check = '1' AND row_check = '1') then 
                                                pixel_counter_check <= '0'; --Need to skip a clock round in order to properly update num_pixel, without incrementing the ADDRESS
                                                pixel_counter := num_pixel - 1 ;
                                            end if;
                                        end if;
                                        if(column_check = '1' AND row_check = '1' AND (rows = "00000000" OR columns = "00000000")) then --If column and row are already read and rows is 0 or columns is 0, then go to DONE
                                            CURR_S <= DONE; --Check 0 Pixels
                                        else 
                                            CURR_S <= WAIT_UPDATE;
                                        end if;
                                        
                    when WAIT_UPDATE => --Waiting clk time to update address in order to access RAM correctly
                                        o_address <= ADDRESS;
                                        if(from_SET_ADDRESS = '1') then --if coming from SET_ADDRESS, next state is GET_VALUE
                                            CURR_S <= WAIT_READ;    
                                        elsif(from_SET_READ = '1') then --if coming from SET_READ, next state is WAIT_READ
                                            CURR_S <= WAIT_READ;
                                        elsif(from_SET_WRITE = '1') then --if coming from SET_WRITE, next state is WRITE
                                            from_SET_WRITE <= '0';
                                            CURR_S <= WRITE;
                                        end if;
                                     
                    when WAIT_READ => --Waiting again to read correctly from the start
                                        if(from_SET_ADDRESS = '1') then --Waiting to read correctly from i_data in GET_VALUE state
                                            from_SET_ADDRESS <= '0';
                                            CURR_S <= GET_VALUE;    
                                        elsif(from_SET_READ = '1') then --Waiting to read correctly from i_data in NEW_PIXEL state
                                            from_SET_READ <= '0';
                                            CURR_S <= NEW_PIXEL;
                                        end if;                                  
                                        
                    when GET_VALUE =>   --Reading values from RAM
                                        if(column_check = '0') then
                                            columns <= i_data; --Read Columns Value
                                            column_check <= '1'; --Update boolean value on columns
                                            CURR_S <= SET_ADDRESS;
                                        elsif(row_check = '0') then
                                            rows <= i_data; --Read Rows Value
                                            row_check <= '1'; --Update boolean value on rows
                                            CURR_S <= SET_ADDRESS;
                                        elsif(num_pixel = "0000000000000000") then --num_pixel has to be calculated, will skip a clock round in SET_ADDRESS
                                            num_pixel <= rows * columns; --Number of pixels that need to be examinated
                                            pixel_counter_check <= '1'; --Boolean needed to skip a clock round in SET_ADDRESS
                                            CURR_S <= SET_ADDRESS;
                                        elsif(conv_integer(pixel_counter)>=0) then --Scanning Pixels
                                            if(conv_integer(i_data) > conv_integer(max)) then --Update Max value
                                                max <= i_data;
                                            end if;
                                            if(conv_integer(i_data) < conv_integer(min)) then --Update Min value
                                                min <= i_data;
                                            end if;
                                            if(max = "11111111" AND min = "00000000") then --Max and Min already found, stop scanning pixels (to optimize in case of maximum range of values)
                                                pixel_counter := "0000000000000000";        
                                            end if;
                                            if(pixel_counter = "0000000000000000") then --Pixels over or Max and Min found, start equalization
                                                CURR_S <= CALC_SHIFT_LEVEL;
                                            else
                                                pixel_counter := pixel_counter -1;
                                                CURR_S <= SET_ADDRESS; --Pixels still need to be scanned 
                                            end if;  
                                        end if;
                    when CALC_SHIFT_LEVEL => --calculate the shift_level in order to estimate the value for the new pixels
                                            delta_value := max - min + 1;
                                            delta_int := conv_integer(delta_value);
                                            if(delta_int >= 256) then --threshold control to implement the function (8- floor(log2(delta_value + 1)))
                                                shift_level <= "0000";
                                            elsif (delta_int >= 128) then
                                                shift_level <= "0001";
                                            elsif (delta_int >= 64) then
                                                shift_level <= "0010";
                                            elsif (delta_int >= 32) then
                                                shift_level <= "0011";
                                            elsif (delta_int >= 16) then
                                                shift_level <= "0100";
                                            elsif (delta_int >= 8) then
                                                shift_level <= "0101";
                                            elsif (delta_int >= 4) then
                                                shift_level <= "0110";
                                            elsif (delta_int >= 2) then
                                                shift_level <= "0111";
                                            elsif (delta_int >= 1) then
                                                shift_level <= "1000";
                                            end if;
                                            
                                            ADDRESS <= "0000000000000010"; --Set ADDRESS on the address of the first pixel in RAM
                                            CURR_S <= SET_READ;
                    when SET_READ => 
                                            from_SET_READ <= '1'; --Boolean value to enroute correctly in WAIT_UPDATE
                                            o_we <= '0';          --RAM access on 'read'
                                            ADDRESS <= ADDRESS + conv_integer(pixel_counter); --Scan every pixel one by one using my processed_pixel_counter;
                                            CURR_S <= WAIT_UPDATE;
                                                  
                    when NEW_PIXEL =>       
                                            temp := i_data - min;
                                            case shift_level is    --Case on shift_level to implement the shift_left function 
                                                when "0000" =>
                                                        temp_pixel <= "00000000" & temp; --temp_pixel 16 bit signal for worst-case-scenario (temp = 255), so it correctly represent the maximum possible value
                                                when "0001" =>
                                                        temp_pixel <= "0000000" & temp & '0';
                                                when "0010" =>
                                                        temp_pixel <= "000000" & temp & "00";
                                                when "0011" =>
                                                        temp_pixel <= "00000" & temp & "000";
                                                when "0100" =>
                                                        temp_pixel <= "0000" & temp & "0000";
                                                when "0101" =>
                                                        temp_pixel <= "000" & temp & "00000";
                                                when "0110" =>
                                                        temp_pixel <= "00" & temp & "000000";
                                                when "0111" =>
                                                        temp_pixel <= "0" & temp & "0000000";
                                                when "1000" =>
                                                        temp_pixel <= temp & "00000000";
                                                when others =>
                                                        
                                            end case;
                                            
                                            CURR_S <= SET_WRITE;
                     
                     when SET_WRITE =>    
                                            from_SET_WRITE <= '1'; --Boolean value to enroute correctly in WAIT_UPDATE
                                            ADDRESS <= ADDRESS + conv_integer(num_pixel); --Prepare ADDRESS to point on the correct slot of memory to write the new_pixel_value
                                            if(conv_integer(temp_pixel) > 255) then  --Implementation of the function: new_pixel_value = min(255, temp_pixel)
                                                new_pixel_value <= "11111111";
                                            else
                                                new_pixel_value <= temp_pixel(7 downto 0);
                                            end if;
                                            CURR_S <= WAIT_UPDATE;
                                            
                     
                     when WRITE =>  
                                            o_we <= '1'; --RAM access on 'write'
                                            o_data <= new_pixel_value;  --Output signal towards the memory is set on new_pixel_value
                                            pixel_counter := pixel_counter + 1;    --Set parameter in order to read again from memory from the right position                  
                                            ADDRESS <= "0000000000000010"; --Set ADDRESS again on the first pixel, it will correctly update using pixel_counter
                                            if(pixel_counter = num_pixel) then --Every pixel is processed
                                              CURR_S <= DONE;
                                            else 
                                              CURR_S <= SET_READ;
                                            end if;
                     
                     when DONE =>
                                            o_done <= '1'; --Set done signal to 1 to notify the process is finished
                                            o_we <= '0'; --Reset RAM access values
                                            o_en <= '0'; --Reset RAM access values
                                            CURR_S <= IDLE;
                     when IDLE =>
                                            if( i_start = '0') then --When start signal is notified of the done signal,done signal is put to 0 to go back to the RST state
                                              o_done <= '0';
                                              CURR_S <= RST;
                                            end if;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
