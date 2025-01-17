LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_misc.all;

ENTITY YCrCb_to_RGB IS 

GENERIC (
	
	IW		:INTEGER     := 23;
	OW		:INTEGER     := 23;
	
	EIW	:INTEGER       := 1;
	EOW	:INTEGER       := 1
	
);

PORT (

	-- Inputs
	clk								        :IN		STD_LOGIC;
	reset								      :IN		STD_LOGIC;

	stream_in_data					  :IN		STD_LOGIC_VECTOR(IW DOWNTO  0);	
	stream_in_startofpacket		:IN		STD_LOGIC;
	stream_in_endofpacket		  :IN		STD_LOGIC;
	--stream_in_empty				    :IN		STD_LOGIC_VECTOR(EIW DOWNTO  0);	
	stream_in_valid				    :IN		STD_LOGIC;

	stream_out_ready				  :IN		STD_LOGIC;

	-- Outputs
	stream_in_ready				    :BUFFER	STD_LOGIC;

	stream_out_data				    :BUFFER	STD_LOGIC_VECTOR(OW DOWNTO  0);	
	stream_out_startofpacket	:BUFFER	STD_LOGIC;
	stream_out_endofpacket		:BUFFER	STD_LOGIC;
	--stream_out_empty				  :BUFFER	STD_LOGIC_VECTOR(EOW DOWNTO  0);	
	stream_out_valid				  :BUFFER	STD_LOGIC

);

END YCrCb_to_RGB;

ARCHITECTURE Behaviour OF YCrCb_to_RGB IS

-- Internal Wires
	SIGNAL	transfer_data				      :STD_LOGIC;
	SIGNAL	converted_data				    :STD_LOGIC_VECTOR(OW DOWNTO  0);	
	SIGNAL	converted_startofpacket	  :STD_LOGIC;
	SIGNAL	converted_endofpacket	    :STD_LOGIC;
	--SIGNAL	converted_empty			      :STD_LOGIC_VECTOR(EOW DOWNTO  0);	
	SIGNAL	converted_valid			      :STD_LOGIC;
	
	-- Internal Registers
	SIGNAL	data					            :STD_LOGIC_VECTOR(IW DOWNTO  0);	
	SIGNAL	startofpacket			       	:STD_LOGIC;
	SIGNAL	endofpacket			      		:STD_LOGIC;
	--SIGNAL	empty							        :STD_LOGIC_VECTOR(EIW DOWNTO  0);	
	SIGNAL	valid							        :STD_LOGIC;

	COMPONENT YCrCb_to_RGB_converter
	PORT (
		-- Inputs
		clk								        :IN		STD_LOGIC;
		clk_en							      :IN		STD_LOGIC;
		reset								      :IN		STD_LOGIC;

		Y									        :IN		STD_LOGIC_VECTOR( 7 DOWNTO  0);
		Cr									      :IN		STD_LOGIC_VECTOR( 7 DOWNTO  0);
		Cb									      :IN		STD_LOGIC_VECTOR( 7 DOWNTO  0);
		stream_in_startofpacket		:IN		STD_LOGIC;
		stream_in_endofpacket		  :IN		STD_LOGIC;
		--stream_in_empty				    :IN		STD_LOGIC_VECTOR(EIW DOWNTO  0);
		stream_in_valid				    :IN		STD_LOGIC;

		-- Outputs
		R									         :BUFFER	STD_LOGIC_VECTOR( 7 DOWNTO  0);
		G									         :BUFFER	STD_LOGIC_VECTOR( 7 DOWNTO  0);
		B									         :BUFFER	STD_LOGIC_VECTOR( 7 DOWNTO  0);
		stream_out_startofpacket	 :BUFFER	STD_LOGIC;
		stream_out_endofpacket		 :BUFFER	STD_LOGIC;
		--stream_out_empty				   :BUFFER	STD_LOGIC_VECTOR(EOW DOWNTO  0);
		stream_out_valid				   :BUFFER	STD_LOGIC
	);
	END COMPONENT;

BEGIN

-- Output Registers
	PROCESS (clk)
	BEGIN
		IF clk'EVENT AND clk = '1' THEN
			IF (reset = '1') THEN
				stream_out_data				<=  (OTHERS => '0');
				stream_out_startofpacket	<= '0';
				stream_out_endofpacket		<= '0';
				--stream_out_empty				<= B"00";
				stream_out_valid				<= '0';
			ELSIF (transfer_data = '1') THEN
				stream_out_data				<= converted_data;
				stream_out_startofpacket	<= converted_startofpacket;
				stream_out_endofpacket		<= converted_endofpacket;
				--stream_out_empty				<= converted_empty;
				stream_out_valid				<= converted_valid;
			END IF;
		END IF;
	END PROCESS;


	-- Internal Registers
	PROCESS (clk)
	BEGIN
		IF clk'EVENT AND clk = '1' THEN
			IF (reset = '1') THEN
				data								<=	(OTHERS => '0');
				startofpacket					<= '0';
				endofpacket						<= '0';
				--empty								<=  (OTHERS => '0');
				valid								<= '0';
			ELSIF (stream_in_ready = '1') THEN
				data								<= stream_in_data;
				startofpacket					<= stream_in_startofpacket;
				endofpacket						<= stream_in_endofpacket;
				--empty								<= stream_in_empty;
				valid								<= stream_in_valid;
			ELSIF (transfer_data = '1') THEN
				data								<=  (OTHERS => '0');
				startofpacket					<= '0';
				endofpacket						<= '0';
				--empty								<=  (OTHERS => '0');
				valid								<= '0';
			END IF;
		END IF;
	END PROCESS;

	-- Output Assignments
	stream_in_ready <= stream_in_valid AND ( NOT valid OR transfer_data);

	-- Internal Assignments
	transfer_data <= NOT stream_out_valid OR (stream_out_ready AND stream_out_valid);


	converter : component YCrCb_to_RGB_converter 
	PORT MAP (
		-- Inputs
		clk								=> clk,
		clk_en							=> transfer_data,
		reset								=> reset,
	
		Y									=> data( 7 DOWNTO  0),
		Cr									=> data(23 DOWNTO 16),
		Cb									=> data(15 DOWNTO  8),
		stream_in_startofpacket		=> startofpacket,
		stream_in_endofpacket		=> endofpacket,
		--stream_in_empty				=> empty,
		stream_in_valid				=> valid,
	
		-- Bidirectionals
	
		-- Outputs
		R									=> converted_data(23 DOWNTO 16),
		G									=> converted_data(15 DOWNTO  8),
		B									=> converted_data( 7 DOWNTO  0),
		stream_out_startofpacket	=> converted_startofpacket,
		stream_out_endofpacket		=> converted_endofpacket,
		--stream_out_empty				=> converted_empty,
		stream_out_valid				=> converted_valid
	);

END Behaviour;
