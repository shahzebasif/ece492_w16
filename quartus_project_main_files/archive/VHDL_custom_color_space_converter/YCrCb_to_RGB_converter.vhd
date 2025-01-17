LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_misc.all;
use IEEE.std_logic_arith.all;

LIBRARY lpm;
USE lpm.all;


ENTITY YCrCb_to_RGB_converter IS 

PORT (
	-- Inputs
	clk								  :IN		STD_LOGIC;
	clk_en							:IN		STD_LOGIC;
	reset								:IN		STD_LOGIC;

	Y									  :IN		STD_LOGIC_VECTOR( 7 DOWNTO  0);	
	Cr									:IN		STD_LOGIC_VECTOR( 7 DOWNTO  0);	
	Cb									:IN		STD_LOGIC_VECTOR( 7 DOWNTO  0);	
	stream_in_startofpacket		:IN		STD_LOGIC;
	stream_in_endofpacket		  :IN		STD_LOGIC;
	--stream_in_empty				    :IN		STD_LOGIC;
	stream_in_valid				    :IN		STD_LOGIC;

	-- Bidirectionals

	-- Outputs
	R									:BUFFER	STD_LOGIC_VECTOR( 7 DOWNTO  0);	
	G									:BUFFER	STD_LOGIC_VECTOR( 7 DOWNTO  0);	
	B									:BUFFER	STD_LOGIC_VECTOR( 7 DOWNTO  0);	
	stream_out_startofpacket	:BUFFER	STD_LOGIC;
	stream_out_endofpacket		:BUFFER	STD_LOGIC;
	--stream_out_empty				:BUFFER	STD_LOGIC;
	stream_out_valid				:BUFFER	STD_LOGIC

);

END YCrCb_to_RGB_converter;

ARCHITECTURE Behaviour OF YCrCb_to_RGB_converter IS
-- *****************************************************************************
-- *                           Constant Declarations                           *
-- *****************************************************************************

-- *****************************************************************************
-- *                       Internal Signals Declarations                       *
-- *****************************************************************************
	
	-- Internal Wires
	SIGNAL	product_0					:STD_LOGIC_VECTOR(35 DOWNTO  0);	
	SIGNAL	product_1					:STD_LOGIC_VECTOR(35 DOWNTO  0);	
	SIGNAL	product_2					:STD_LOGIC_VECTOR(35 DOWNTO  0);	
	SIGNAL	product_3					:STD_LOGIC_VECTOR(35 DOWNTO  0);	
	SIGNAL	product_4					:STD_LOGIC_VECTOR(35 DOWNTO  0);	
	
	SIGNAL	R_sum							:STD_LOGIC_VECTOR(10 DOWNTO  0);	
	SIGNAL	G_sum							:STD_LOGIC_VECTOR(10 DOWNTO  0);	
	SIGNAL	B_sum							:STD_LOGIC_VECTOR(10 DOWNTO  0);	
	
	-- Internal Registers
	SIGNAL	Y_sub							:STD_LOGIC_VECTOR(10 DOWNTO  0);	
	SIGNAL	Cr_sub						:STD_LOGIC_VECTOR(10 DOWNTO  0);	
	SIGNAL	Cb_sub						:STD_LOGIC_VECTOR(10 DOWNTO  0);	
	
	SIGNAL	Y_1d1640						:STD_LOGIC_VECTOR(10 DOWNTO  0);	
	SIGNAL	Cr_0d813						:STD_LOGIC_VECTOR(10 DOWNTO  0);	
	SIGNAL	Cr_1d596						:STD_LOGIC_VECTOR(10 DOWNTO  0);	
	SIGNAL	Cb_2d017						:STD_LOGIC_VECTOR(10 DOWNTO  0);	
	SIGNAL	Cb_0d392						:STD_LOGIC_VECTOR(10 DOWNTO  0);	
	
	SIGNAL	startofpacket_shift_reg	:STD_LOGIC_VECTOR( 1 DOWNTO  0);	
	SIGNAL	endofpacket_shift_reg	:STD_LOGIC_VECTOR( 1 DOWNTO  0);	
	--SIGNAL	empty_shift_reg			:STD_LOGIC_VECTOR( 1 DOWNTO  0);	
	SIGNAL	valid_shift_reg			:STD_LOGIC_VECTOR( 1 DOWNTO  0);	
	
	-- State Machine Registers
	
-- *****************************************************************************
-- *                          Component Declarations                           *
-- *****************************************************************************
	COMPONENT lpm_mult
	GENERIC (
		lpm_widtha				:INTEGER;
		lpm_widthb				:INTEGER;
		lpm_widthp				:INTEGER;
		lpm_widths				:INTEGER;
		lpm_type					:STRING;
		lpm_representation	:STRING;
		lpm_hint					:STRING
	);
	PORT (
		-- Inputs
		dataa		:IN		STD_LOGIC_VECTOR(17 DOWNTO  0);
		datab		:IN		STD_LOGIC_VECTOR(17 DOWNTO  0);
		aclr		:IN		STD_LOGIC;
		clken		:IN		STD_LOGIC;
		clock		:IN		STD_LOGIC;
	
		-- Bidirectionals
	
		-- Outputs
		result	:BUFFER	STD_LOGIC_VECTOR(35 DOWNTO  0);
		sum		:BUFFER	STD_LOGIC
	);
	END COMPONENT;

BEGIN
-- *****************************************************************************
-- *                         Finite State Machine(s)                           *
-- *****************************************************************************


-- *****************************************************************************
-- *                             Sequential Logic                              *
-- *****************************************************************************

	-- Output Registers
	PROCESS (clk)
	BEGIN
		IF clk'EVENT AND clk = '1' THEN
			IF (reset = '1') THEN
				R <= B"00000000";
				G <= B"00000000";
				B <= B"00000000";
			ELSIF (clk_en = '1') THEN
				IF (R_sum(10) = '1') THEN -- Negative number
					R <= B"00000000";
				ELSIF ((R_sum(9) OR R_sum(8)) = '1') THEN -- Number greater than 255
					R <= B"11111111";
				ELSE
					R <= R_sum(7 DOWNTO 0);
				END IF;
			
				IF (G_sum(10) = '1') THEN -- Negative number
					G <= B"00000000";
				ELSIF ((G_sum(9) OR G_sum(8)) = '1') THEN -- Number greater than 255
					G <= B"11111111";
				ELSE
					G <= G_sum(7 DOWNTO 0);
				END IF;
			
				IF (B_sum(10) = '1') THEN -- Negative number
					B <= B"00000000";
				ELSIF ((B_sum(9) OR B_sum(8)) = '1') THEN -- Number greater than 255
					B <= B"11111111";
				ELSE
					B <= B_sum(7 DOWNTO 0);
				END IF;
			END IF;
		END IF;
	END PROCESS;


	PROCESS (clk)
	BEGIN
		IF clk'EVENT AND clk = '1' THEN
			IF (clk_en = '1') THEN
				stream_out_startofpacket	<= startofpacket_shift_reg(1);
				stream_out_endofpacket		<= endofpacket_shift_reg(1);
				--stream_out_empty				<= empty_shift_reg(1);
				stream_out_valid				<= valid_shift_reg(1);
			END IF;
		END IF;
	END PROCESS;


	-- Internal Registers
	-- ---------------------------------------------------------------------------
	--
	-- Offset Y, Cr, and Cb.
	-- Note: Internal wires are all 11 bits from here out, to allow for 
	-- increasing bit extent due to additions, subtractions, and multiplies
	-- Note: Signs are not extended when appropriate.

	PROCESS (clk)
	BEGIN
		IF clk'EVENT AND clk = '1' THEN
			IF (reset = '1') THEN
				Y_sub		<= B"00000000000";
				Cr_sub	<= B"00000000000";
				Cb_sub	<= B"00000000000";
			ELSIF (clk_en = '1') THEN
				Y_sub		<= (B"000" & Y  - B"00000010000");  -- result always positive
				Cr_sub	<= (B"000" & Cr - B"00010000000"); 	-- result is positive or negative
				Cb_sub	<= (B"000" & Cb - B"00010000000"); 	-- result is positive or negative
			END IF;
		END IF;
	END PROCESS;


	PROCESS (clk)
	BEGIN
		IF clk'EVENT AND clk = '1' THEN
			IF (reset = '1') THEN
				Y_1d1640 <= B"00000000000";
				Cr_0d813 <= B"00000000000";
				Cr_1d596 <= B"00000000000";
				Cb_2d017 <= B"00000000000";
				Cb_0d392 <= B"00000000000";
			ELSIF (clk_en = '1') THEN
				Y_1d1640 <= product_0(25 DOWNTO 15);
				Cr_0d813 <= product_1(25 DOWNTO 15);
				Cr_1d596 <= product_2(25 DOWNTO 15);
				Cb_2d017 <= product_3(25 DOWNTO 15);
				Cb_0d392 <= product_4(25 DOWNTO 15);
			END IF;
		END IF;
	END PROCESS;


	PROCESS (clk)
	BEGIN
		IF clk'EVENT AND clk = '1' THEN
			IF (reset = '1') THEN
				startofpacket_shift_reg	<= B"00";
				endofpacket_shift_reg	<= B"00";
				--empty_shift_reg			<= B"00";
				valid_shift_reg			<= B"00";
			ELSIF (clk_en = '1') THEN
				startofpacket_shift_reg(1)	<= startofpacket_shift_reg(0);
				endofpacket_shift_reg(1)	<= endofpacket_shift_reg(0);
				--empty_shift_reg(1)			<= empty_shift_reg(0);
				valid_shift_reg(1)			<= valid_shift_reg(0);
		
				startofpacket_shift_reg(0)	<= stream_in_startofpacket;
				endofpacket_shift_reg(0)	<= stream_in_endofpacket;
				--empty_shift_reg(0)			<= stream_in_empty;
				valid_shift_reg(0)			<= stream_in_valid;
			END IF;
		END IF;
	END PROCESS;


-- *****************************************************************************
-- *                            Combinational Logic                            *
-- *****************************************************************************

	-- Output Assignments

	-- Internal Assignments
	-- ---------------------------------------------------------------------------
	--
	-- Sum the proper outputs from the multiply to form R'G'B'
	--
	R_sum <= Y_1d1640 + Cr_1d596;
	G_sum <= Y_1d1640 - Cr_0d813 - Cb_0d392;
	B_sum <= Y_1d1640            + Cb_2d017;

-- *****************************************************************************
-- *                          Component Instantiations                         *
-- *****************************************************************************


	-- Formula Set #1
	-- ---------------------------------------------------------------------------
	-- R' = 1.164(Y-16) + 1.596(Cr-128)
	-- G' = 1.164(Y-16) -  .813(Cr-128) -  .392(Cb-128)
	-- B' = 1.164(Y-16)                 + 2.017(Cb-128)
	-- 
	-- use full precision of multiply to experiment with coefficients
	-- 1.164 -> I[1:0].F[14:0]  .164 X 2^15 = 094FD or 00 1.001 0100 1111 1101 
	-- 0.813 -> I[1:0].F[14:0]  .813 X 2^15 = 06810 or 00 0.110 1000 0001 0000
	-- 1.596 -> I[1:0].F[14:0]  .596 X 2^15 = 0CC49 or 00 1.100 1100 0100 1001
	-- 2.017 -> I[1:0].F[14:0]  .017 X 2^15 = 1022D or 01 0.000 0010 0010 1101
	-- 0.392 -> I[1:0].F[14:0]  .392 X 2^15 = 0322D or 00 0.011 0010 0010 1101

	lpm_mult_component_0 : component lpm_mult 
	GENERIC MAP (
		lpm_widtha				=> 18,
		lpm_widthb				=> 18,
		lpm_widthp				=> 36,
		lpm_widths				=> 1,
		lpm_type					=> "LPM_MULT",
		lpm_representation	=> "SIGNED",
		lpm_hint					=> "INPUT_B_IS_CONSTANT=YES,MAXIMIZE_SPEED=5"
	)
	PORT MAP (
		-- Inputs
		dataa		=> Y_sub(10) & Y_sub(10) & Y_sub(10) & Y_sub(10) & Y_sub(10) & 
						Y_sub(10) & Y_sub(10) & Y_sub,
		datab		=> B"001001010011111101",
		aclr		=> '0',
		clken		=> '1',
		clock		=> '0',
		
		-- Bidirectionals
		
		-- Outputs
		result	=> product_0,
		sum		=> '0'
	);


	lpm_mult_component_1 : component lpm_mult 
	GENERIC MAP (
		lpm_widtha				=> 18,
		lpm_widthb				=> 18,
		lpm_widthp				=> 36,
		lpm_widths				=> 1,
		lpm_type					=> "LPM_MULT",
		lpm_representation	=> "SIGNED",
		lpm_hint					=> "INPUT_B_IS_CONSTANT=YES,MAXIMIZE_SPEED=5"
	)
	PORT MAP (
		-- Inputs
		dataa		=> Cr_sub(10) & Cr_sub(10) & Cr_sub(10) & Cr_sub(10) & Cr_sub(10) & 
						Cr_sub(10) & Cr_sub(10) & Cr_sub,
		datab		=> B"000110100000010000",
		aclr		=> '0',
		clken		=> '1',
		clock		=> '0',
		
		-- Bidirectionals
		
		-- Outputs
		result	=> product_1,
		sum		=> '0'
	);


	lpm_mult_component_2 : component lpm_mult 
	GENERIC MAP (
		lpm_widtha				=> 18,
		lpm_widthb				=> 18,
		lpm_widthp				=> 36,
		lpm_widths				=> 1,
		lpm_type					=> "LPM_MULT",
		lpm_representation	=> "SIGNED",
		lpm_hint					=> "INPUT_B_IS_CONSTANT=YES,MAXIMIZE_SPEED=5"
	)
	PORT MAP (
		-- Inputs
		dataa		=> Cr_sub(10) & Cr_sub(10) & Cr_sub(10) & Cr_sub(10) & Cr_sub(10) & 
						Cr_sub(10) & Cr_sub(10) & Cr_sub,
		datab		=> B"001100110001001001",
		aclr		=> '0',
		clken		=> '1',
		clock		=> '0',
		
		-- Bidirectionals
		
		-- Outputs
		result	=> product_2,
		sum		=> '0'
	);


	lpm_mult_component_3 : component lpm_mult 
	GENERIC MAP (
		lpm_widtha				=> 18,
		lpm_widthb				=> 18,
		lpm_widthp				=> 36,
		lpm_widths				=> 1,
		lpm_type					=> "LPM_MULT",
		lpm_representation	=> "SIGNED",
		lpm_hint					=> "INPUT_B_IS_CONSTANT=YES,MAXIMIZE_SPEED=5"
	)
	PORT MAP (
		-- Inputs
		dataa		=> Cb_sub(10) & Cb_sub(10) & Cb_sub(10) & Cb_sub(10) & Cb_sub(10) & 
						Cb_sub(10) & Cb_sub(10) & Cb_sub,
		datab		=> B"010000001000101101",
		aclr		=> '0',
		clken		=> '1',
		clock		=> '0',
		
		-- Bidirectionals
		
		-- Outputs
		result	=> product_3,
		sum		=> '0'
	);


	lpm_mult_component_4 : component lpm_mult 
	GENERIC MAP (
		lpm_widtha				=> 18,
		lpm_widthb				=> 18,
		lpm_widthp				=> 36,
		lpm_widths				=> 1,
		lpm_type					=> "LPM_MULT",
		lpm_representation	=> "SIGNED",
		lpm_hint					=> "INPUT_B_IS_CONSTANT=YES,MAXIMIZE_SPEED=5"
	)
	PORT MAP (
		-- Inputs
		dataa		=> Cb_sub(10) & Cb_sub(10) & Cb_sub(10) & Cb_sub(10) & Cb_sub(10) & 
						Cb_sub(10) & Cb_sub(10) & Cb_sub,
		datab		=> B"000011001000101101",
		aclr		=> '0',
		clken		=> '1',
		clock		=> '0',
		
		-- Bidirectionals
		
		-- Outputs
		result	=> product_4,
		sum		=> '0'
	);

	-- Formula Set #2
	-- ---------------------------------------------------------------------------
	-- R = Y + 1.402   (Cr-128)
	-- G = Y - 0.71414 (Cr-128) - 0.34414 (Cb-128) 
	-- B = Y                    + 1.772   (Cb-128)
	-- 
	-- use full precision of multiply to experiment with coefficients
	-- 1.00000 -> I[0].F[16:0]  1.00000 X 2^15 = 08000  
	-- 1.40200 -> I[0].F[16:0]  1.40200 X 2^15 = 0B375 
	-- 0.71414 -> I[0].F[16:0]  0.71414 X 2^15 = 05B69 
	-- 0.34414 -> I[0].F[16:0]  0.34414 X 2^15 = 02C0D 
	-- 1.77200 -> I[0].F[16:0]  1.77200 X 2^15 = 0E2D1 


END Behaviour;
