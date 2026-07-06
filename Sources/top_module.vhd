----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- Create Date: 23.06.2026
-- Design Name: 
-- Module Name: TOP_module - Behavioral
-- Description: 4-channel XADC round-robin sampling into separate FIFOs
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TOP_module is
    Port ( 
        CLK100MHZ : in std_logic;
        vauxp2, vauxn2 : in std_logic;
        vauxp3, vauxn3 : in std_logic;
        vauxp10, vauxn10 : in std_logic;
        vauxp11, vauxn11 : in std_logic;
        vp, vn : in std_logic;
      UART_TX : out std_logic  -- Add output ports here if you want to expose FIFO data (e.g. for UART, BRAM, etc.)
    );
end TOP_module;

architecture Behavioral of TOP_module is

    -- XADC signals
    signal address_in : std_logic_vector(6 downto 0);
    signal enable      : std_logic;
    signal ready       : std_logic;
    signal data        : std_logic_vector(15 downto 0);
    
    -- Channel management
    signal xadc_channel_index : std_logic_vector(1 downto 0) := "00";
    signal fifo_channel_d1    : std_logic_vector(1 downto 0) := "00";  -- delayed for write
    
    -- FIFO write enables
    signal fifo_wr_en_0 : std_logic := '0';
    signal fifo_wr_en_1 : std_logic := '0';
    signal fifo_wr_en_2 : std_logic := '0';
    signal fifo_wr_en_3 : std_logic := '0';
    
    -- FIFO read enables
    signal fifo_rd_en_0 : std_logic := '0';
    signal fifo_rd_en_1 : std_logic := '0';
    signal fifo_rd_en_2 : std_logic := '0';
    signal fifo_rd_en_3 : std_logic := '0';
    
    -- FIFO status
    signal fifo_full_0, fifo_full_1, fifo_full_2, fifo_full_3 : std_logic;
    signal fifo_empty_0, fifo_empty_1, fifo_empty_2, fifo_empty_3 : std_logic;
    
    -- FIFO outputs (12-bit data)
    signal fifo_dout_0, fifo_dout_1, fifo_dout_2, fifo_dout_3 : std_logic_vector(11 downto 0);
    
    -- Slow read counter
    signal count : unsigned(23 downto 0) := (others => '0');
    signal fifo_read_index : std_logic_vector(1 downto 0) := "00";
        signal uart_tx_data  : std_logic_vector(7 downto 0);
    signal uart_tx_valid : std_logic := '0';
    signal uart_tx_ready : std_logic;
    signal byte_sel      : std_logic := '0';
signal fifo_data_valid : std_logic := '0';
begin

    --============================================================
    -- XADC Wizard Instantiation
    --============================================================
    xadc_inst: entity work.xadc_wiz_0
    port map (
        daddr_in     => address_in,
        den_in       => enable,
        di_in        => (others => '0'),
        dwe_in       => '0',
        do_out       => data,
        drdy_out     => ready,
        dclk_in      => CLK100MHZ,
        reset_in     => '0',
        
        vauxp2       => vauxp2,
        vauxn2       => vauxn2,
        vauxp3       => vauxp3,
        vauxn3       => vauxn3,
        vauxp10      => vauxp10,
        vauxn10      => vauxn10,
        vauxp11      => vauxp11,
        vauxn11      => vauxn11,
        
        vp_in        => vp,
        vn_in        => vn,
        
        eoc_out      => enable,      -- Important: drives next conversion
        busy_out     => open,
        channel_out  => open,
        eos_out      => open,
        alarm_out    => open
    );

    --============================================================
    -- Channel Selection
    --============================================================
    channel_sel_proc: process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            case xadc_channel_index is
                when "00"   => address_in <= "0010010";  -- VAUX2  (0x12)
                when "01"   => address_in <= "0010011";  -- VAUX3  (0x13)
                when "10"   => address_in <= "0011010";  -- VAUX10 (0x1A)
                when others => address_in <= "0011011";  -- VAUX11 (0x1B)
            end case;

            if ready = '1' then
                xadc_channel_index <= std_logic_vector(unsigned(xadc_channel_index) + 1);
            end if;
        end if;
    end process;

    -- Delay channel index for correct FIFO write (data is ready one cycle after selection)
    delay_proc: process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            fifo_channel_d1 <= xadc_channel_index;
        end if;
    end process;

    --============================================================
    -- FIFO Write Logic
    --============================================================
    fifo_write_proc: process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            fifo_wr_en_0 <= '0';
            fifo_wr_en_1 <= '0';
            fifo_wr_en_2 <= '0';
            fifo_wr_en_3 <= '0';

            if ready = '1' then
                case fifo_channel_d1 is
                    when "00" =>
                        if fifo_full_0 = '0' then
                            fifo_wr_en_0 <= '1';
                        end if;
                    when "01" =>
                        if fifo_full_1 = '0' then
                            fifo_wr_en_1 <= '1';
                        end if;
                    when "10" =>
                        if fifo_full_2 = '0' then
                            fifo_wr_en_2 <= '1';
                        end if;
                    when others =>
                        if fifo_full_3 = '0' then
                            fifo_wr_en_3 <= '1';
                        end if;
                end case;
            end if;
        end if;
    end process;

    --============================================================
    -- FIFO Instantiations (assuming fifo_generator_0 is 12-bit wide)
    --============================================================
    fifo0_inst: entity work.fifo_generator_0
    port map (
        clk    => CLK100MHZ,
        srst   => '0',
        din    => data(15 downto 4),
        wr_en  => fifo_wr_en_0,
        rd_en  => fifo_rd_en_0,
        dout   => fifo_dout_0,
        full   => fifo_full_0,
        empty  => fifo_empty_0
    );

    fifo1_inst: entity work.fifo_generator_0
    port map (
        clk    => CLK100MHZ,
        srst   => '0',
        din    => data(15 downto 4),
        wr_en  => fifo_wr_en_1,
        rd_en  => fifo_rd_en_1,
        dout   => fifo_dout_1,
        full   => fifo_full_1,
        empty  => fifo_empty_1
    );

    fifo2_inst: entity work.fifo_generator_0
    port map (
        clk    => CLK100MHZ,
        srst   => '0',
        din    => data(15 downto 4),
        wr_en  => fifo_wr_en_2,
        rd_en  => fifo_rd_en_2,
        dout   => fifo_dout_2,
        full   => fifo_full_2,  
        empty  => fifo_empty_2
    );   
 
    fifo3_inst: entity work.fifo_generator_0
    port map (
        clk    => CLK100MHZ,
        srst   => '0',
        din    => data(15 downto 4),
        wr_en  => fifo_wr_en_3,
        rd_en  => fifo_rd_en_3,
        dout   => fifo_dout_3,
        full   => fifo_full_3,
        empty  => fifo_empty_3
    );

    --============================================================
    -- Slow Read Logic (approx. every 10 ms @ 100 MHz)
    --============================================================
    --============================================================
    -- Slow Read Logic + UART Transmitter
    --============================================================
           read_proc: process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            fifo_rd_en_0 <= '0';
            fifo_rd_en_1 <= '0';
            fifo_rd_en_2 <= '0';
            fifo_rd_en_3 <= '0';
            uart_tx_valid <= '0';

            count <= count + 1;

            -- Read one channel every 10,000 clocks
            if count = 10_000 - 1 then
                count <= (others => '0');

                case fifo_read_index is
                    when "00" => if fifo_empty_0='0' then fifo_rd_en_0 <= '1'; end if;
                    when "01" => if fifo_empty_1='0' then fifo_rd_en_1 <= '1'; end if;
                    when "10" => if fifo_empty_2='0' then fifo_rd_en_2 <= '1'; end if;
                    when others => if fifo_empty_3='0' then fifo_rd_en_3 <= '1'; end if;
                end case;
          
            end if;

            -- UART Transmission - Full 12-bit


            if (fifo_rd_en_0 or fifo_rd_en_1 or fifo_rd_en_2 or fifo_rd_en_3) = '1'  then
            fifo_data_valid <='1';
                -- UART Transmission from FIFO
if uart_tx_ready = '1' then
    case fifo_read_index is

        when "00" =>
            if byte_sel = '0' then
                uart_tx_data <= "0000" & fifo_dout_0(11 downto 8); -- Upper 4 bits
                uart_tx_valid <= '1';
                byte_sel <= '1';
            else
                uart_tx_data <= fifo_dout_0(7 downto 0);           -- Lower 8 bits
                uart_tx_valid <= '1';
                byte_sel <= '0';
                fifo_read_index <= "01";   
            end if;

        when "01" =>
            if byte_sel = '0' then
                uart_tx_data <= "0000" & fifo_dout_1(11 downto 8);
                uart_tx_valid <= '1';
                byte_sel <= '1';
            else
                uart_tx_data <= fifo_dout_1(7 downto 0);
                uart_tx_valid <= '1';
                byte_sel <= '0';
                fifo_read_index <= "10";   
            end if;

        when "10" =>
            if byte_sel = '0' then
                uart_tx_data <= "0000" & fifo_dout_2(11 downto 8);
                uart_tx_valid <= '1';
                byte_sel <= '1';
            else
                uart_tx_data <= fifo_dout_2(7 downto 0); 
                uart_tx_valid <= '1';
                byte_sel <= '0';
                fifo_read_index <= "11";   
            end if;

        when others =>
            if byte_sel = '0' then 
                uart_tx_data <= "0000" & fifo_dout_3(11 downto 8);
                uart_tx_valid <= '1';
                byte_sel <= '1';
            else
                uart_tx_data <= fifo_dout_3(7 downto 0);
                uart_tx_valid <= '1';
                byte_sel <= '0';
                fifo_read_index <= "00"; 
            end if;

    end case;
 
else
    uart_tx_valid <= '0';
end if; 
end if;
end if ; 
    end process;
        uart_inst: entity work.uart_tx
    generic map (CLK_FREQ => 100_000_000, BAUD_RATE => 115200)
    port map (
        clk      => CLK100MHZ, 
        rst      => '0',
        tx_data  => uart_tx_data,
        tx_valid => uart_tx_valid,
        tx_ready => uart_tx_ready,
        tx       => UART_TX
    );

end Behavioral;
