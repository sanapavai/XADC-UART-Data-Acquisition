library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    generic (
        CLK_FREQ  : integer := 100_000_000;  -- 100 MHz
        BAUD_RATE : integer := 115200         -- Common baud rate
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        tx_data  : in  std_logic_vector(7 downto 0);   -- Byte to send
        tx_valid : in  std_logic;                      -- New data available
        tx_ready : out std_logic;                      -- Ready for next byte
        tx       : out std_logic                       -- UART TX pin
    );
end uart_tx;

architecture Behavioral of uart_tx is
    constant TICKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    
    signal tick_counter : integer range 0 to TICKS_PER_BIT-1 := 0;
    signal bit_index    : integer range 0 to 9 := 0;
    signal shift_reg    : std_logic_vector(9 downto 0) := (others => '1');
    signal tx_busy      : std_logic := '0';
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                tx_busy <= '0';
                tx <= '1';
                tick_counter <= 0;
                bit_index <= 0;
            else
                if tx_valid = '1' and tx_busy = '0' then
                    -- Load data: Stop(1) + 8 data bits + Start(0)
                    shift_reg <= '1' & tx_data & '0';
                    tx_busy <= '1';
                    bit_index <= 0;
                    tick_counter <= 0;
                elsif tx_busy = '1' then
                    if tick_counter = TICKS_PER_BIT - 1 then
                        tick_counter <= 0;
                        tx <= shift_reg(bit_index);
                        bit_index <= bit_index + 1;
                        
                        if bit_index = 9 then
                            tx_busy <= '0';   -- Transmission complete
                        end if;
                    else
                        tick_counter <= tick_counter + 1;
                    end if;
                else
                    tx <= '1';   -- Idle state
                end if;
            end if;
        end if;
    end process;

    tx_ready <= not tx_busy;

end Behavioral;
