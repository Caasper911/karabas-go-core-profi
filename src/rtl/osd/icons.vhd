library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;
library unisim;
use unisim.vcomponents.all;

entity icons is
	port (
		CLK		: in std_logic;
		RGB_I 	: in std_logic_vector(8 downto 0);
		RGB_O 	: out std_logic_vector(8 downto 0);
		DS80		: in std_logic;
		HCNT		: in std_logic_vector(9 downto 0);
		VCNT		: in std_logic_vector(8 downto 0);
		
		STATUS_SD : in std_logic := '0'; -- SD card r/w status
		STATUS_CF : in std_logic := '0'; -- CF card r/w status
		STATUS_FD : in std_logic := '0'; -- FDD r/w status
		STATUS_GS : in std_logic := '0'; -- GS r/w status
		STATUS_UA : in std_logic := '0' -- UART r/w status
	);
end entity;

architecture rtl of icons is

	 signal icon_addr : std_logic_vector(10 downto 0);
	 
	 signal paper_icon_fd : std_logic := '0';
	 signal paper_icon_sd : std_logic := '0';
	 signal paper_icon_cf : std_logic := '0';
	 signal paper_icon_gs : std_logic := '0';
	 signal paper_icon_ua : std_logic := '0';
	 signal paper2_icon_fd : std_logic := '0';
	 signal paper2_icon_sd : std_logic := '0';
	 signal paper2_icon_cf : std_logic := '0';	
	 signal paper2_icon_gs : std_logic := '0';	 
	 signal paper2_icon_ua : std_logic := '0';
	 signal icon_x : std_logic_vector(3 downto 0);
	 signal icon_y : std_logic_vector(3 downto 0);
	 signal icon_pixel : std_logic_vector(0 downto 0);
	 signal icon_pixel_reg: std_logic;	 
	 signal is_icon_fd : std_logic := '0';
	 signal is_icon_sd : std_logic := '0';
	 signal is_icon_cf : std_logic := '0';	 
	 signal is_icon_gs : std_logic := '0';
	 signal is_icon_ua : std_logic := '0';

	 constant icon_color: std_logic_vector(8 downto 0) := "000011001";
	 
	 constant icons_start_profi_h : natural := 256 + 8;
	 constant icons_start_spec_h : natural := 256 + 32;
	 constant icons_start_v : natural := 0;
	 constant icon_w : natural := 16;
	 constant icon_h : natural := 16;
	 
	 signal icons_h : std_logic := '0';
	 signal icons_h8 : std_logic := '0';
	 
	 signal icon_pos : std_logic_vector(2 downto 0);
	 
	 signal cnt_icon_fd : std_logic_vector(3 downto 0) := (others => '1');
	 signal cnt_icon_sd : std_logic_vector(3 downto 0) := (others => '1'); 
	 signal cnt_icon_cf : std_logic_vector(3 downto 0) := (others => '1');
	 signal cnt_icon_gs : std_logic_vector(3 downto 0) := (others => '1');
	 signal cnt_icon_ua : std_logic_vector(3 downto 0) := (others => '1');
	 
	 signal tick  : std_logic := '0';
	 signal tick_prev  : std_logic := '0';
	 
begin

	 -- 
	 U_FONT_ICONS: entity work.sprom
	 generic map (
		DATAWIDTH => 1,
		ADDRWIDTH => 11,
		MEM_INIT_FILE => "rtl/osd/iconsGS.bit"
	 )
    port map (
		clock => clk,
      address_a  => icon_addr,
      q_a  => icon_pixel
    );
		
	 icon_x <= hcnt(3 downto 0);
	 icon_y <= vcnt(3 downto 0);

	 icons_h <= '1' when ((DS80='1' and hcnt >= icons_start_profi_h and hcnt < icons_start_profi_h + icon_w) 
									 or (DS80='0' and hcnt >= icons_start_spec_h and hcnt < icons_start_spec_h + icon_w)) else '0';
									 
	 paper_icon_fd <= '1' when icons_h = '1' and vcnt >= icons_start_v and vcnt < icons_start_v + icon_h else '0';
	 paper_icon_sd <= '1' when icons_h = '1' and vcnt >= icons_start_v + icon_h and vcnt < icons_start_v + 2*icon_h else '0';
	 paper_icon_cf <= '1' when icons_h = '1' and vcnt >= icons_start_v + 2*icon_h and vcnt < icons_start_v + 3*icon_h else '0';
	 paper_icon_gs <= '1' when icons_h = '1' and vcnt >= icons_start_v + 3*icon_h and vcnt < icons_start_v + 4*icon_h else '0';
	 paper_icon_ua <= '1' when icons_h = '1' and vcnt >= icons_start_v + 4*icon_h and vcnt < icons_start_v + 5*icon_h else '0';
	 
	 icon_pos <= "000" when paper_icon_fd = '1' else
					 "001" when paper_icon_sd = '1' else 
					 "010" when paper_icon_cf = '1' else 
					 "011" when paper_icon_gs = '1' else
					 "100" when paper_icon_ua = '1' else
					 "000";
	 
	 icon_addr <= icon_y(3) & icon_pos &  not(icon_x(3)) & icon_y(2 downto 0) & icon_x(2 downto 0) when DS80='1' else 
					  icon_y(3) & icon_pos &  icon_x(3) & icon_y(2 downto 0) & icon_x(2 downto 0); --spectrum pos shifter 8 px
					  
	 process(clk,VCNT)
	 begin
		if (rising_edge (clk)) then
			tick_prev <= VCNT(7);
			tick <= VCNT(7) and not tick_prev;
		end if;
	 end process;

	 process(clk, STATUS_FD, STATUS_SD, STATUS_CF)
	 begin 
		if (rising_edge(clk)) then
			if (STATUS_FD = '1') then 
				cnt_icon_fd <= (others => '0');
			elsif (cnt_icon_fd < "1111" and tick = '1') then 
				cnt_icon_fd <= cnt_icon_fd + 1;
			end if;
			if (STATUS_SD = '1') then 
				cnt_icon_sd <= (others => '0');
			elsif (cnt_icon_sd < "1111" and tick = '1') then 
				cnt_icon_sd <= cnt_icon_sd + 1;
			end if;
			if (STATUS_CF = '1') then 
				cnt_icon_cf <= (others => '0');
			elsif (cnt_icon_cf < "1111" and tick = '1') then 
				cnt_icon_cf <= cnt_icon_cf + 1;
			end if;
			if (STATUS_GS = '1') then 
				cnt_icon_gs <= (others => '0');
			elsif (cnt_icon_gs < "1111" and tick = '1') then 
				cnt_icon_gs <= cnt_icon_gs + 1;
			end if;
			if (STATUS_UA = '1') then 
				cnt_icon_ua <= (others => '0');
			elsif (cnt_icon_ua < "1111" and tick = '1') then 
				cnt_icon_ua <= cnt_icon_ua + 1;
			end if;
		end if;
	 end process;
	 
	 is_icon_fd <= '1' when cnt_icon_fd < "1111" else '0';
	 is_icon_sd <= '1' when cnt_icon_sd < "1111" else '0';
	 is_icon_cf <= '1' when cnt_icon_cf < "1111" else '0';
	 is_icon_gs <= '1' when cnt_icon_gs < "1111" else '0';
	 is_icon_ua <= '1' when cnt_icon_ua < "1111" else '0';

    --  RGB
    RGB_O <= 
				icon_color when paper_icon_fd = '1' and icon_pixel(0) = '1' and is_icon_fd = '1' else 
				icon_color when paper_icon_sd = '1' and icon_pixel(0) = '1' and is_icon_sd = '1' else 
				icon_color when paper_icon_cf = '1' and icon_pixel(0) = '1' and is_icon_cf = '1' else
				icon_color when paper_icon_gs = '1' and icon_pixel(0) = '1' and is_icon_gs = '1' else
				icon_color when paper_icon_ua = '1' and icon_pixel(0) = '1' and is_icon_ua = '1' else
				RGB_I;

end architecture;
