library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_axi4lite is
    generic (
        CLK_FREQ  : integer := 50_000_000;
        BAUD_RATE : integer := 115_200
    );
    port (
        clk, resetn : in std_logic;

        s_axi_awaddr  : in  std_logic_vector(3 downto 0);
        s_axi_awvalid : in  std_logic;
        s_axi_awready : out std_logic;

        s_axi_wdata   : in  std_logic_vector(31 downto 0);
        s_axi_wvalid  : in  std_logic;
        s_axi_wready  : out std_logic;

        s_axi_bresp   : out std_logic_vector(1 downto 0);
        s_axi_bvalid  : out std_logic;
        s_axi_bready  : in  std_logic;

        s_axi_araddr  : in  std_logic_vector(3 downto 0);
        s_axi_arvalid : in  std_logic;
        s_axi_arready : out std_logic;

        s_axi_rdata   : out std_logic_vector(31 downto 0);
        s_axi_rresp   : out std_logic_vector(1 downto 0);
        s_axi_rvalid  : out std_logic;
        s_axi_rready  : in  std_logic;

        uart_tx : out std_logic;
        uart_rx : in  std_logic
    );
end entity uart_axi4lite;

architecture rtl of uart_axi4lite is

    signal tx_data : std_logic_vector(7 downto 0);
    signal tx_start, tx_busy : std_logic := '0';
    signal rx_data : std_logic_vector(7 downto 0);
    signal rx_data_ready, rx_data_ack : std_logic := '0';

    type wr_t is (W_IDLE, W_RESP);
    signal wst : wr_t := W_IDLE;

    type rd_t is (R_IDLE, R_DATA);
    signal rst    : rd_t := R_IDLE;
    signal rdata  : std_logic_vector(31 downto 0);

begin

    u_core : entity work.uart_core
        generic map (CLK_FREQ => CLK_FREQ, BAUD_RATE => BAUD_RATE)
        port map (
            clk => clk, resetn => resetn,
            tx_data => tx_data, tx_start => tx_start, tx_busy => tx_busy,
            rx_data => rx_data, rx_data_ready => rx_data_ready,
            rx_data_ack => rx_data_ack,
            uart_tx => uart_tx, uart_rx => uart_rx
        );

  
    process(clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                wst <= W_IDLE; s_axi_awready <= '0';
                s_axi_wready <= '0'; s_axi_bvalid <= '0'; tx_start <= '0';
            else
                tx_start <= '0';
                case wst is
                    when W_IDLE =>
                        s_axi_bvalid <= '0';
                        if s_axi_awvalid = '1' and s_axi_wvalid = '1' then
                            s_axi_awready <= '1'; s_axi_wready <= '1';
                            if s_axi_awaddr = "0000" then
                                tx_data <= s_axi_wdata(7 downto 0);
                                tx_start <= '1';
                            end if;
                            wst <= W_RESP;
                        else
                            s_axi_awready <= '0'; s_axi_wready <= '0';
                        end if;
                    when W_RESP =>
                        s_axi_awready <= '0'; s_axi_wready <= '0';
                        s_axi_bvalid <= '1';
                        if s_axi_bready = '1' then wst <= W_IDLE; end if;
                end case;
            end if;
        end if;
    end process;

    s_axi_bresp <= "00";

    process(clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                rst <= R_IDLE; s_axi_arready <= '0';
                s_axi_rvalid <= '0'; rx_data_ack <= '0';
            else
                rx_data_ack <= '0';
                case rst is
                    when R_IDLE =>
                        s_axi_rvalid <= '0';
                        if s_axi_arvalid = '1' then
                            s_axi_arready <= '1';
                            case s_axi_araddr is
                                when "0100" =>
                                    rdata <= x"000000" & rx_data;
                                    rx_data_ack <= '1';
                                when "1000" =>
                                    rdata <= (31 downto 2 => '0')
                                             & rx_data_ready & tx_busy;
                                when others =>
                                    rdata <= (others => '0');
                            end case;
                            rst <= R_DATA;
                        else
                            s_axi_arready <= '0';
                        end if;
                    when R_DATA =>
                        s_axi_arready <= '0';
                        s_axi_rvalid <= '1';
                        if s_axi_rready = '1' then rst <= R_IDLE; end if;
                end case;
            end if;
        end if;
    end process;

    s_axi_rresp <= "00";
    s_axi_rdata <= rdata;

end architecture rtl;