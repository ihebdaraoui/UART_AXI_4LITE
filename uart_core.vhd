library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_core is
    generic (
        CLK_FREQ  : integer := 50_000_000;
        BAUD_RATE : integer := 115_200
    );
    port (
        clk           : in  std_logic;
        resetn        : in  std_logic;
        tx_data       : in  std_logic_vector(7 downto 0);
        tx_start      : in  std_logic;
        tx_busy       : out std_logic;
        rx_data       : out std_logic_vector(7 downto 0);
        rx_data_ready : out std_logic;
        rx_data_ack   : in  std_logic;
        uart_tx       : out std_logic;
        uart_rx       : in  std_logic
    );
end entity uart_core;

architecture rtl of uart_core is

    constant DIV : integer := CLK_FREQ / BAUD_RATE;

    type tx_state_t is (T_IDLE, T_START, T_BITS, T_STOP);
    signal tx_state : tx_state_t := T_IDLE;
    signal tx_shift : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_index : integer range 0 to 7 := 0;
    signal tx_cnt   : integer range 0 to DIV - 1 := 0;

    type rx_state_t is (R_IDLE, R_START, R_BITS, R_STOP);
    signal rx_state : rx_state_t := R_IDLE;
    signal rx_shift : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_index : integer range 0 to 7 := 0;
    signal rx_cnt   : integer range 0 to DIV - 1 := 0;
    signal rx_sync1 : std_logic := '1';
    signal rx_sync2 : std_logic := '1';
    signal rx_ready : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                tx_state <= T_IDLE;
                uart_tx  <= '1';
                tx_busy  <= '0';
                tx_cnt   <= 0;
            else
                case tx_state is
                    when T_IDLE =>
                        uart_tx <= '1';
                        tx_busy <= '0';
                        if tx_start = '1' then
                            tx_shift <= tx_data;
                            tx_index <= 0;
                            tx_cnt   <= 0;
                            tx_busy  <= '1';
                            tx_state <= T_START;
                        end if;

                    when T_START =>
                        uart_tx <= '0';
                        if tx_cnt = DIV - 1 then
                            tx_cnt   <= 0;
                            tx_state <= T_BITS;
                        else
                            tx_cnt <= tx_cnt + 1;
                        end if;

                    when T_BITS =>
                        uart_tx <= tx_shift(tx_index);
                        if tx_cnt = DIV - 1 then
                            tx_cnt <= 0;
                            if tx_index = 7 then
                                tx_state <= T_STOP;
                            else
                                tx_index <= tx_index + 1;
                            end if;
                        else
                            tx_cnt <= tx_cnt + 1;
                        end if;

                    when T_STOP =>
                        uart_tx <= '1';
                        if tx_cnt = DIV - 1 then
                            tx_cnt   <= 0;
                            tx_state <= T_IDLE;
                        else
                            tx_cnt <= tx_cnt + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            rx_sync1 <= uart_rx;
            rx_sync2 <= rx_sync1;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                rx_state <= R_IDLE;
                rx_ready <= '0';
                rx_cnt   <= 0;
                rx_index <= 0;
            else
                if rx_data_ack = '1' then
                    rx_ready <= '0';
                end if;

                case rx_state is
                    when R_IDLE =>
                        if rx_sync2 = '0' then
                            rx_cnt   <= 0;
                            rx_state <= R_START;
                        end if;

                    when R_START =>
                        if rx_cnt = DIV - 1 then
                            rx_cnt   <= 0;
                            rx_index <= 0;
                            rx_state <= R_BITS;
                        else
                            rx_cnt <= rx_cnt + 1;
                        end if;

                    when R_BITS =>
                        if rx_cnt = DIV / 2 then
                            rx_shift(rx_index) <= rx_sync2;
                        end if;
                        if rx_cnt = DIV - 1 then
                            rx_cnt <= 0;
                            if rx_index = 7 then
                                rx_state <= R_STOP;
                            else
                                rx_index <= rx_index + 1;
                            end if;
                        else
                            rx_cnt <= rx_cnt + 1;
                        end if;

                    when R_STOP =>
                        if rx_cnt = DIV - 1 then
                            rx_cnt   <= 0;
                            rx_ready <= '1';
                            rx_state <= R_IDLE;
                        else
                            rx_cnt <= rx_cnt + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    rx_data       <= rx_shift;
    rx_data_ready <= rx_ready;

end architecture rtl;