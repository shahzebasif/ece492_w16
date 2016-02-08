library ieee;
use ieee.std_logic_1164.all;
	
entity niosII_gesture_detection is
	
	port
	(
	CLOCK_50	: in  std_logic;
	CLOCK_27 : in std_logic;

	I2C_SCLK : out std_logic;
	I2C_SDAT : inout std_logic;

	TD_DATA : in std_logic_vector(7 downto 0);
	TD_HS : in std_logic;
	TD_VS : in std_logic;
	TD_RESET : out std_logic;

	SRAM_ADDR : out std_logic_vector(17 downto 0);
	SRAM_DQ : inout std_logic_vector(15 downto 0);
	SRAM_WE_N : out std_logic;
	SRAM_OE_N : out std_logic;
	SRAM_UB_N : out std_logic;
	SRAM_LB_N : out std_logic;
	SRAM_CE_N : out std_logic;

	VGA_R : out std_logic_vector(9 downto 0);
	VGA_G : out std_logic_vector(9 downto 0);
	VGA_B : out std_logic_vector(9 downto 0);
	VGA_HS		: out std_logic;
	VGA_VS		: out std_logic;
	VGA_SYNC		: out std_logic;
	VGA_BLANK	: out std_logic;
	VGA_CLK		: out std_logic
		
	);
end niosII_gesture_detection;

architecture structure of niosII_gesture_detection is
    component niosII_system is
        port (
            clk_clk                                         : in    std_logic                     := 'X';             -- clk
            reset_reset_n                                   : in    std_logic                     := 'X';             -- reset_n

            video_decoder_external_interface_TD_CLK27       : in    std_logic                     := 'X';             -- TD_CLK27
            video_decoder_external_interface_TD_DATA        : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- TD_DATA
            video_decoder_external_interface_TD_HS          : in    std_logic                     := 'X';             -- TD_HS
            video_decoder_external_interface_TD_VS          : in    std_logic                     := 'X';             -- TD_VS
            video_decoder_external_interface_TD_RESET       : out   std_logic;                                        -- TD_RESET
            --video_decoder_external_interface_overflow_flag  : out   std_logic;                                        -- overflow_flag

            sram_controller_external_interface_DQ           : inout std_logic_vector(15 downto 0) := (others => 'X'); -- DQ
            sram_controller_external_interface_ADDR         : out   std_logic_vector(17 downto 0);                    -- ADDR
            sram_controller_external_interface_LB_N         : out   std_logic;                                        -- LB_N
            sram_controller_external_interface_UB_N         : out   std_logic;                                        -- UB_N
            sram_controller_external_interface_CE_N         : out   std_logic;                                        -- CE_N
            sram_controller_external_interface_OE_N         : out   std_logic;                                        -- OE_N
            sram_controller_external_interface_WE_N         : out   std_logic;                                        -- WE_N

            video_vga_controller_0_external_interface_CLK   : out   std_logic;                                        -- CLK
            video_vga_controller_0_external_interface_HS    : out   std_logic;                                        -- HS
            video_vga_controller_0_external_interface_VS    : out   std_logic;                                        -- VS
            video_vga_controller_0_external_interface_BLANK : out   std_logic;                                        -- BLANK
            video_vga_controller_0_external_interface_SYNC  : out   std_logic;                                        -- SYNC
            video_vga_controller_0_external_interface_R     : out   std_logic_vector(9 downto 0);                     -- R
            video_vga_controller_0_external_interface_G     : out   std_logic_vector(9 downto 0);                     -- G
            video_vga_controller_0_external_interface_B     : out   std_logic_vector(9 downto 0);                     -- B

            audio_video_config_external_interface_SDAT      : inout std_logic                     := 'X';             -- SDAT
            audio_video_config_external_interface_SCLK      : out   std_logic                                         -- SCLK
        );
    end component niosII_system;

begin

    u0 : component niosII_system
        port map (
            clk_clk                                         => CLOCK_50,       -- clk.clk
            reset_reset_n                                   => '1',            -- reset.reset_n

            video_decoder_external_interface_TD_CLK27       => CLOCK_27,       -- video_decoder_external_interface.TD_CLK27
            video_decoder_external_interface_TD_DATA        => TD_DATA,        -- .TD_DATA
            video_decoder_external_interface_TD_HS          => TD_HS,          -- .TD_HS
            video_decoder_external_interface_TD_VS          => TD_VS,          -- .TD_VS
            video_decoder_external_interface_TD_RESET       => TD_RESET,       -- .TD_RESET
            --video_decoder_external_interface_overflow_flag  => CONNECTED_TO_video_decoder_external_interface_overflow_flag,  -- .overflow_flag

            sram_controller_external_interface_DQ           => SRAM_DQ,           -- sram_controller_external_interface.DQ
            sram_controller_external_interface_ADDR         => SRAM_ADDR,         -- .ADDR
            sram_controller_external_interface_LB_N         => SRAM_LB_N,         -- .LB_N
            sram_controller_external_interface_UB_N         => SRAM_UB_N,         -- .UB_N
            sram_controller_external_interface_CE_N         => SRAM_CE_N,         -- .CE_N
            sram_controller_external_interface_OE_N         => SRAM_OE_N,         -- .OE_N
            sram_controller_external_interface_WE_N         => SRAM_WE_N,         -- .WE_N

            video_vga_controller_0_external_interface_CLK   => VGA_CLK,   --video_vga_controller_0_external_interface.CLK
            video_vga_controller_0_external_interface_HS    => VGA_HS,    -- .HS
            video_vga_controller_0_external_interface_VS    => VGA_VS,    -- .VS
            video_vga_controller_0_external_interface_BLANK => VGA_BLANK, -- .BLANK
            video_vga_controller_0_external_interface_SYNC  => VGA_SYNC,  -- .SYNC
            video_vga_controller_0_external_interface_R     => VGA_R,     -- .R
            video_vga_controller_0_external_interface_G     => VGA_G,     -- .G
            video_vga_controller_0_external_interface_B     => VGA_B,     -- .B

            audio_video_config_external_interface_SDAT      => I2C_SDAT,      -- audio_video_config_external_interface.SDAT
            audio_video_config_external_interface_SCLK      => I2C_SCLK       -- .SCLK
        );

end structure;







