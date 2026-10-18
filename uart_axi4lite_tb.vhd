library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_axi4lite_tb is
end entity uart_axi4lite_tb;

architecture sim of uart_axi4lite_tb is

    constant CLK_PERIOD : time := 20 ns;

    signal clk      : std_logic := '0';
    signal resetn   : std_logic := '0';
    signal sim_done : boolean   := false;

    signal awaddr  : std_logic_vector(3 downto 0)  := (others => '0');
    signal awvalid : std_logic := '0';
    signal awready : std_logic;
    signal wdata   : std_logic_vector(31 downto 0) := (others => '0');
    signal wvalid  : std_logic := '0';
    signal wready  : std_logic;
    signal bresp   : std_logic_vector(1 downto 0);
    signal bvalid  : std_logic;
    signal bready  : std_logic := '0';

    signal araddr  : std_logic_vector(3 downto 0)  := (others => '0');
    signal arvalid : std_logic := '0';
    signal arready : std_logic;
    signal rdata   : std_logic_vector(31 downto 0);
    signal rresp   : std_logic_vector(1 downto 0);
    signal rvalid  : std_logic;
    signal rready  : std_logic := '0';

    signal uart_line : std_logic;

begin

    dut : entity work.uart_axi4lite
        generic map (
            CLK_FREQ  => 1_000_000,
            BAUD_RATE => 100_000
        )
        port map (
            clk           => clk,
            resetn        => resetn,
            s_axi_awaddr  => awaddr,
            s_axi_awvalid => awvalid,
            s_axi_awready => awready,
            s_axi_wdata   => wdata,
            s_axi_wvalid  => wvalid,
            s_axi_wready  => wready,
            s_axi_bresp   => bresp,
            s_axi_bvalid  => bvalid,
            s_axi_bready  => bready,
            s_axi_araddr  => araddr,
            s_axi_arvalid => arvalid,
            s_axi_arready => arready,
            s_axi_rdata   => rdata,
            s_axi_rresp   => rresp,
            s_axi_rvalid  => rvalid,
            s_axi_rready  => rready,
            uart_tx       => uart_line,
            uart_rx       => uart_line
        );

    clk <= not clk after CLK_PERIOD / 2 when not sim_done else clk;

    process
        procedure axi_write(
            addr : in std_logic_vector(3 downto 0);
            data : in std_logic_vector(31 downto 0)
        ) is
        begin
            wait until rising_edge(clk);
            awaddr  <= addr;
            awvalid <= '1';
            wdata   <= data;
            wvalid  <= '1';
            bready  <= '1';

            wait until rising_edge(clk) and (awready = '1' and wready = '1');
            awvalid <= '0';
            wvalid  <= '0';

            wait until rising_edge(clk) and bvalid = '1';
            bready  <= '0';
        end procedure;

        procedure axi_read(
            addr : in std_logic_vector(3 downto 0);
            data : out std_logic_vector(31 downto 0)
        ) is
        begin
            wait until rising_edge(clk);
            araddr  <= addr;
            arvalid <= '1';
            rready  <= '1';

            wait until rising_edge(clk) and arready = '1';
            arvalid <= '0';

            wait until rising_edge(clk) and rvalid = '1';
            data    := rdata;
            rready  <= '0';
        end procedure;

        procedure send_and_check(
            char : in std_logic_vector(7 downto 0)
        ) is
            variable read_val : std_logic_vector(31 downto 0);
        begin
            axi_write("0000", x"000000" & char);

            loop
                axi_read("1000", read_val);
                exit when read_val(1) = '1';
            end loop;

            axi_read("0100", read_val);
            assert read_val(7 downto 0) = char
                report "ERREUR : octet recu different de l'octet envoye"
                severity failure;
        end procedure;

    begin
        resetn <= '0';
        wait for 100 ns;
        resetn <= '1';
        wait for 100 ns;
        report "[TB] Reset termine." severity note;

        report "[TB] Test 1 : transmission de 'A' (0x41)" severity note;
        send_and_check(x"41");
        report "[SUCCESS] Caractere 'A' (0x41) transmis et recu avec succes" severity note;

        report "[TB] Test 2 : transmission de 'B' (0x42)" severity note;
        send_and_check(x"42");
        report "[SUCCESS] Caractere 'B' (0x42) transmis et recu avec succes" severity note;

        wait for 500 ns;
        report "=== ALL TESTS PASSED SUCCESSFULLY (SELF-CHECK) ===" severity note;

        sim_done <= true;
        wait;
    end process;

end architecture sim;