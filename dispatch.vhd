library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dispatch is
    generic (control_bits_width : integer := 20);
    port (
        alu_rs_is_free: in std_logic;
        ls_rs_is_free: in std_logic;
        br_rs_is_free: in std_logic;
        br_rs_is_empty: in std_logic; 
        ip1: in std_logic_vector(15 downto 0);
        ip2: in std_logic_vector(15 downto 0);
		  
		  
		  
--         -- types based on how much to read and write and which instruction it is:-
--         -- 1. 0000 => 2 reg read, 1 reg write, which is equivalent to ALU except ADI
--         -- 2. 0001 => 1 reg and 1 imm read, 1 reg write + adi
--         -- 3. 0010 => 1 reg and 1 imm read, 1 reg write + lw
--         -- 4. 0011 => 1 reg and 1 imm read, 1 reg write + sw
--         -- 5. 0100 => 1 imm read, 1 reg write + lli
--         -- 6. 0101 => 1 imm read, 1 reg write + jal
--         -- 7. 0110 => 2 regs and 1 imm read, which is equivalent to beq, blt or ble
--         -- 8. 0111 => 1 reg read and 1 reg write, which is equivalent to jlr
--         -- 9. 1000 => 1 reg and 1 imm read, which is equivalent to jri
        operation_type_1: in std_logic_vector(3 downto 0); 
        operation_type_2: in std_logic_vector(3 downto 0);
		  
		  
        addresses_of_register_to_read_from_1: in std_logic_vector(5 downto 0);
        addresses_of_register_to_read_from_2: in std_logic_vector(5 downto 0);
        immediate_of_operation_1: in std_logic_vector(15 downto 0);
        immediate_of_operation_2: in std_logic_vector(15 downto 0);
        address_of_register_to_write_to_1: in std_logic_vector(2 downto 0);
        address_of_register_to_write_to_2: in std_logic_vector(2 downto 0);
        dependency_bits: in std_logic_vector(1 downto 0);
        control_signals_for_i1: in std_logic_vector(control_bits_width - 1 downto 0);
        control_signals_for_i2: in std_logic_vector(control_bits_width - 1 downto 0);

        i1_reads_c  : in std_logic;
        i1_writes_c : in std_logic;
        i1_reads_z  : in std_logic;
        i1_writes_z : in std_logic;
        i2_reads_c  : in std_logic;
        i2_writes_c : in std_logic;
        i2_reads_z  : in std_logic;
        i2_writes_z : in std_logic;
        
        current_branch_tag_i1: in std_logic_vector(2 downto 0);
        current_branch_tag_i2: in std_logic_vector(2 downto 0);

        rrf_busy_bits_col: in std_logic_vector(63 downto 0);
        operand_1_register_to_read_1_tag_rrf_data: in std_logic_vector(22 downto 0);
        operand_1_register_to_read_2_tag_rrf_data: in std_logic_vector(22 downto 0);
        operand_2_register_to_read_1_tag_rrf_data: in std_logic_vector(22 downto 0);
        operand_2_register_to_read_2_tag_rrf_data: in std_logic_vector(22 downto 0);

        zero_flag_rrf_busy_bits_col  : in std_logic_vector(63 downto 0);
        carry_flag_rrf_busy_bits_col : in std_logic_vector(63 downto 0);
        c_flag_rrf_data : in std_logic_vector(2 downto 0);
        z_flag_rrf_data : in std_logic_vector(2 downto 0);

        operand_1_register_to_read_1: in std_logic_vector(22 downto 0);
        operand_1_register_to_read_2: in std_logic_vector(22 downto 0);
        operand_2_register_to_read_1: in std_logic_vector(22 downto 0);
        operand_2_register_to_read_2: in std_logic_vector(22 downto 0);

        cz_flag_arf_data : in std_logic_vector(29 downto 0);

        rob_is_free: in std_logic;
        sb_is_free: in std_logic;
        branch_predictor_bits: in std_logic_vector(1 downto 0);

        -- ALU RS Outputs
        data_to_write_to_alu_rs_for_i1: out std_logic_vector(control_bits_width + 91 downto 0);
        data_to_write_to_alu_rs_for_i2: out std_logic_vector(control_bits_width + 91 downto 0);
        alu_rs_write_enable: out std_logic_vector(1 downto 0);

        --LS RS Outputs
        data_to_write_to_ls_rs_for_i1: out std_logic_vector(control_bits_width + 91 downto 0);
        data_to_write_to_ls_rs_for_i2: out std_logic_vector(control_bits_width + 91 downto 0);
        ls_rs_write_enable: out std_logic_vector(1 downto 0);

        --BR RS Outputs
        data_to_write_to_br_rs_for_i1: out std_logic_vector(control_bits_width + 111 downto 0);
        data_to_write_to_br_rs_for_i2: out std_logic_vector(control_bits_width + 111 downto 0);
        br_rs_write_enable: out std_logic_vector(1 downto 0);

        read_addresses_of_arf: out std_logic_vector(11 downto 0); 
        write_tags_to_these_addresses_of_arf: out std_logic_vector(5 downto 0);
        
        write_tag_to_c_flag_arf : out std_logic_vector(5 downto 0);
        write_tag_to_z_flag_arf : out std_logic_vector(5 downto 0);
        c_flag_arf_write_enable : out std_logic;
        z_flag_arf_write_enable : out std_logic;

        read_addresses_of_rrf: out std_logic_vector(23 downto 0); 
		  
		  carry_tag_i1 : out std_logic_vector(5 downto 0);
		  carry_tag_i2 : out std_logic_vector(5 downto 0);
		  zero_tag_i1  : out std_logic_vector(5 downto 0);
		  zero_tag_i2  : out std_logic_vector(5 downto 0);
		  carry_rrf_tag_enable : out std_logic_vector(1 downto 0);
		  zero_rrf_tag_enable  : out std_logic_vector(1 downto 0);

        new_tags_of_rrf_for_writing_to_i1_destination: out std_logic_vector(5 downto 0);
        new_tags_of_rrf_for_writing_to_i2_destination: out std_logic_vector(5 downto 0);
        new_tags_of_rrf_for_writing_to_i1_pc: out std_logic_vector(5 downto 0);
        new_tags_of_rrf_for_writing_to_i2_pc: out std_logic_vector(5 downto 0);
        write_new_busy_bits_value_tags_etc_enable: out std_logic_vector(3 downto 0);

        data_to_write_to_rob_for_i1: out std_logic_vector(control_bits_width + 47 downto 0);
        data_to_write_to_rob_for_i2: out std_logic_vector(control_bits_width + 47 downto 0);
        rob_write_enable: out std_logic;

        data_to_write_to_sb_for_i1: out std_logic_vector(56 downto 0);
        data_to_write_to_sb_for_i2: out std_logic_vector(56 downto 0);
        sb_write_enable: out std_logic_vector(1 downto 0);

        stall_fetch: out std_logic
    );
end entity;

architecture design of dispatch is
    component tag_generator
        port (
            din               : in  std_logic_vector(63 downto 0);
            rrf_is_free       : out std_logic;
            rrf_tag_addresses : out std_logic_vector(23 downto 0)
        );
    end component;

    component flag_tag_generator
        port (
            din               : in  std_logic_vector(63 downto 0);
            rrf_is_free       : out std_logic;
            rrf_tag_addresses : out std_logic_vector(11 downto 0)
        );
    end component;

    signal rrf_is_free_signal: std_logic;
    signal z_rrf_is_free, c_rrf_is_free : std_logic;
    
    signal new_tags_of_rrf_signal: std_logic_vector(23 downto 0);
    signal new_z_tags, new_c_tags: std_logic_vector(11 downto 0);

    signal rs_write_i1_operand_1_mux_cascade_level_1_signal: std_logic_vector(15 downto 0);
    signal rs_write_i1_operand_2_mux_cascade_level_1_signal: std_logic_vector(15 downto 0);
    signal rs_write_i2_operand_1_mux_cascade_level_1_signal: std_logic_vector(15 downto 0);
    signal rs_write_i2_operand_2_mux_cascade_level_1_signal: std_logic_vector(15 downto 0);
    signal rs_write_i2_operand_1_mux_cascade_level_2_signal: std_logic_vector(15 downto 0);
    signal rs_write_i2_operand_2_mux_cascade_level_2_signal: std_logic_vector(15 downto 0);
    signal rs_write_i2_operand_1_mux_cascade_output_signal: std_logic_vector(15 downto 0);
    signal rs_write_i2_operand_2_mux_cascade_output_signal: std_logic_vector(15 downto 0);
    signal rs_write_i1_operand_1_mux_cascade_output_signal: std_logic_vector(15 downto 0);
    signal rs_write_i1_operand_2_mux_cascade_output_signal: std_logic_vector(15 downto 0);

    signal pz1, pz2, pc1, pc2 : std_logic_vector(5 downto 0);
    signal resolved_c_for_i1, resolved_z_for_i1 : std_logic_vector(22 downto 0);
    signal resolved_c_for_i2, resolved_z_for_i2 : std_logic_vector(22 downto 0);

    signal v1_for_i1, v2_for_i1, v1_for_i2, v2_for_i2: std_logic;

    signal full_flags_i1 : std_logic_vector(33 downto 0);
    signal full_flags_i2 : std_logic_vector(33 downto 0);
    signal dest_flags_i1 : std_logic_vector(17 downto 0);
    signal dest_flags_i2 : std_logic_vector(17 downto 0);

    signal c_flag_arf_dummy : std_logic_vector(22 downto 0);
    signal z_flag_arf_dummy : std_logic_vector(22 downto 0);
    signal c_flag_rrf_dummy : std_logic_vector(22 downto 0);
    signal z_flag_rrf_dummy : std_logic_vector(22 downto 0);

    signal c_from_arfrrf_valid : std_logic;
    signal z_from_arfrrf_valid : std_logic;
    signal c_valid_for_i1, z_valid_for_i1 : std_logic;
    signal c_valid_for_i2, z_valid_for_i2 : std_logic;
	 signal i1_is_branch, i2_is_branch : std_logic;

begin
	    i1_is_branch <= '1' when (address_of_register_to_write_to_1 = "000" or 
                              operation_type_1 = "0101" or operation_type_1 = "0110" or 
                              operation_type_1 = "0111" or operation_type_1 = "1000") else '0';
                              
    i2_is_branch <= '1' when (address_of_register_to_write_to_2 = "000" or 
                              operation_type_2 = "0101" or operation_type_2 = "0110" or 
                              operation_type_2 = "0111" or operation_type_2 = "1000") else '0';
										
	 carry_tag_i1 <= pc1;
	 carry_tag_i2 <= pc2;
	 zero_tag_i1  <= pz1;
	 zero_tag_i2  <= pz2;
	 

    read_addresses_of_arf <= addresses_of_register_to_read_from_1 & addresses_of_register_to_read_from_2;

    read_addresses_of_rrf <= operand_2_register_to_read_2(5 downto 0) & 
                             operand_2_register_to_read_1(5 downto 0) & 
                             operand_1_register_to_read_2(5 downto 0) & 
                             operand_1_register_to_read_1(5 downto 0);

    tag_generator_1: entity work.tag_generator port map (
        din => rrf_busy_bits_col,
        rrf_is_free => rrf_is_free_signal,
        rrf_tag_addresses => new_tags_of_rrf_signal
    );

    z_flag_tag_gen: entity work.flag_tag_generator port map (
        din => zero_flag_rrf_busy_bits_col,
        rrf_is_free => z_rrf_is_free,
        rrf_tag_addresses => new_z_tags
    );

    c_flag_tag_gen: entity work.flag_tag_generator port map (
        din => carry_flag_rrf_busy_bits_col,
        rrf_is_free => c_rrf_is_free,
        rrf_tag_addresses => new_c_tags
    );

    new_tags_of_rrf_for_writing_to_i1_destination <= new_tags_of_rrf_signal(11 downto 6);
    new_tags_of_rrf_for_writing_to_i2_destination <= new_tags_of_rrf_signal(5 downto 0);
    new_tags_of_rrf_for_writing_to_i1_pc <= new_tags_of_rrf_signal(23 downto 18);
    new_tags_of_rrf_for_writing_to_i2_pc <= new_tags_of_rrf_signal(17 downto 12);

    write_tags_to_these_addresses_of_arf(5 downto 3) <= address_of_register_to_write_to_1;
    write_tags_to_these_addresses_of_arf(2 downto 0) <= address_of_register_to_write_to_2;

    rs_write_i1_operand_1_mux_cascade_level_1_signal <= operand_1_register_to_read_1_tag_rrf_data(16 downto 1) when (operand_1_register_to_read_1_tag_rrf_data(0)='1') else "0000000000" & operand_1_register_to_read_1(5 downto 0);
    rs_write_i1_operand_2_mux_cascade_level_1_signal <= operand_1_register_to_read_2_tag_rrf_data(16 downto 1) when (operand_1_register_to_read_2_tag_rrf_data(0)='1') else "0000000000" & operand_1_register_to_read_2(5 downto 0);
--    rs_write_i1_operand_1_mux_cascade_output_signal <= rs_write_i1_operand_1_mux_cascade_level_1_signal when (operand_1_register_to_read_1(22)='1') else operand_1_register_to_read_1(21 downto 6);
--    rs_write_i1_operand_2_mux_cascade_output_signal <= rs_write_i1_operand_2_mux_cascade_level_1_signal when (operand_1_register_to_read_2(22)='1') else operand_1_register_to_read_2(21 downto 6);

    rs_write_i2_operand_1_mux_cascade_level_1_signal <= operand_2_register_to_read_1_tag_rrf_data(16 downto 1) when (operand_2_register_to_read_1_tag_rrf_data(0)='1') else "0000000000" & operand_2_register_to_read_1(5 downto 0);
    rs_write_i2_operand_2_mux_cascade_level_1_signal <= operand_2_register_to_read_2_tag_rrf_data(16 downto 1) when (operand_2_register_to_read_2_tag_rrf_data(0)='1') else "0000000000" & operand_2_register_to_read_2(5 downto 0);
    rs_write_i2_operand_1_mux_cascade_level_2_signal <= rs_write_i2_operand_1_mux_cascade_level_1_signal when (operand_2_register_to_read_1(22)='1') else operand_2_register_to_read_1(21 downto 6);
    rs_write_i2_operand_2_mux_cascade_level_2_signal <= rs_write_i2_operand_2_mux_cascade_level_1_signal when (operand_2_register_to_read_2(22)='1') else operand_2_register_to_read_2(21 downto 6);
--    rs_write_i2_operand_1_mux_cascade_output_signal <= "0000000000" & new_tags_of_rrf_signal(11 downto 6) when (dependency_bits(0)='1') else rs_write_i2_operand_1_mux_cascade_level_2_signal;
--    rs_write_i2_operand_2_mux_cascade_output_signal <= "0000000000" & new_tags_of_rrf_signal(11 downto 6) when (dependency_bits(1)='1') else rs_write_i2_operand_2_mux_cascade_level_2_signal;

--    v1_for_i1 <= (not operand_1_register_to_read_1(22)) or (operand_1_register_to_read_1(22) and operand_1_register_to_read_1_tag_rrf_data(0));
--    v2_for_i1 <= (not operand_1_register_to_read_2(22)) or (operand_1_register_to_read_2(22) and operand_1_register_to_read_2_tag_rrf_data(0));
--    v1_for_i2 <= '0' when (dependency_bits(0) = '1') else 
--             ((not operand_2_register_to_read_1(22)) or (operand_2_register_to_read_1(22) and operand_2_register_to_read_1_tag_rrf_data(0)));
--    v2_for_i2 <= '0' when (dependency_bits(1) = '1') else 
--             ((not operand_2_register_to_read_2(22)) or (operand_2_register_to_read_2(22) and operand_2_register_to_read_2_tag_rrf_data(0)));



    -- INSTRUCTION 1 OPERAND FETCH & PC BYPASS

    rs_write_i1_operand_1_mux_cascade_output_signal <= ip1 when (addresses_of_register_to_read_from_1(5 downto 3) = "000") else 
        rs_write_i1_operand_1_mux_cascade_level_1_signal when (operand_1_register_to_read_1(22)='1') else operand_1_register_to_read_1(21 downto 6);

    rs_write_i1_operand_2_mux_cascade_output_signal <= ip1 when (addresses_of_register_to_read_from_1(2 downto 0) = "000") else 
        rs_write_i1_operand_2_mux_cascade_level_1_signal when (operand_1_register_to_read_2(22)='1') else operand_1_register_to_read_2(21 downto 6);

    v1_for_i1 <= '1' when (addresses_of_register_to_read_from_1(5 downto 3) = "000") else 
        (not operand_1_register_to_read_1(22)) or (operand_1_register_to_read_1(22) and operand_1_register_to_read_1_tag_rrf_data(0));

    v2_for_i1 <= '1' when (addresses_of_register_to_read_from_1(2 downto 0) = "000") else 
        (not operand_1_register_to_read_2(22)) or (operand_1_register_to_read_2(22) and operand_1_register_to_read_2_tag_rrf_data(0));


 
    -- INSTRUCTION 2 OPERAND FETCH & PC BYPASS

    rs_write_i2_operand_1_mux_cascade_output_signal <= ip2 when (addresses_of_register_to_read_from_2(5 downto 3) = "000") else
        "0000000000" & new_tags_of_rrf_signal(11 downto 6) when (dependency_bits(0)='1') else rs_write_i2_operand_1_mux_cascade_level_2_signal;

    rs_write_i2_operand_2_mux_cascade_output_signal <= ip2 when (addresses_of_register_to_read_from_2(2 downto 0) = "000") else
        "0000000000" & new_tags_of_rrf_signal(11 downto 6) when (dependency_bits(1)='1') else rs_write_i2_operand_2_mux_cascade_level_2_signal;

    v1_for_i2 <= '1' when (addresses_of_register_to_read_from_2(5 downto 3) = "000") else
        '0' when (dependency_bits(0) = '1') else 
        ((not operand_2_register_to_read_1(22)) or (operand_2_register_to_read_1(22) and operand_2_register_to_read_1_tag_rrf_data(0)));

    v2_for_i2 <= '1' when (addresses_of_register_to_read_from_2(2 downto 0) = "000") else
        '0' when (dependency_bits(1) = '1') else 
        ((not operand_2_register_to_read_2(22)) or (operand_2_register_to_read_2(22) and operand_2_register_to_read_2_tag_rrf_data(0)));
		  
		  
    pz1 <= new_z_tags(11 downto 6);
    pz2 <= new_z_tags(5 downto 0);
    pc1 <= new_c_tags(11 downto 6);
    pc2 <= new_c_tags(5 downto 0);

    c_flag_arf_dummy <= cz_flag_arf_data(29)            -- [22]: carry busy (was hardwired '0')
                    & "000000000000000"                -- [21:7]: padding
                    & cz_flag_arf_data(1)              -- [6]: committed carry value
                    & cz_flag_arf_data(27 downto 22);  -- [5:0]: carry tag (was hardwired "000000")

    z_flag_arf_dummy <= cz_flag_arf_data(28)            -- [22]: zero busy (was hardwired '0')
                    & "000000000000000"
                    & cz_flag_arf_data(0)              -- [6]: committed zero value
                    & cz_flag_arf_data(21 downto 16);  -- [5:0]: zero tag (was hardwired "000000")

    c_flag_rrf_dummy <= c_flag_rrf_data(2) & "000000000000000" & c_flag_rrf_data(1) & "00000" & c_flag_rrf_data(0);
    z_flag_rrf_dummy <= z_flag_rrf_data(2) & "000000000000000" & z_flag_rrf_data(1) & "00000" & z_flag_rrf_data(0);

    c_from_arfrrf_valid <= (not c_flag_arf_dummy(22)) or c_flag_rrf_dummy(0);
    z_from_arfrrf_valid <= (not z_flag_arf_dummy(22)) or z_flag_rrf_dummy(0);

    c_valid_for_i1 <= (not i1_reads_c) or c_from_arfrrf_valid;
    z_valid_for_i1 <= (not i1_reads_z) or z_from_arfrrf_valid;

    c_valid_for_i2 <= '0'              when (i1_writes_c = '1' and i2_reads_c = '1') else
                    (not i2_reads_c) or c_from_arfrrf_valid;

    z_valid_for_i2 <= '0'              when (i1_writes_z = '1' and i2_reads_z = '1') else
                    (not i2_reads_z) or z_from_arfrrf_valid;

    resolved_c_for_i1 <= c_flag_rrf_dummy when (c_flag_arf_dummy(22) = '1' and c_flag_rrf_dummy(0) = '1') else c_flag_arf_dummy;
    resolved_z_for_i1 <= z_flag_rrf_dummy when (z_flag_arf_dummy(22) = '1' and z_flag_rrf_dummy(0) = '1') else z_flag_arf_dummy;

    resolved_c_for_i2 <= "1" & "0000000000000000" & pc1 when (i1_writes_c = '1') else resolved_c_for_i1;
    resolved_z_for_i2 <= "1" & "0000000000000000" & pz1 when (i1_writes_z = '1') else resolved_z_for_i1;

    write_tag_to_c_flag_arf <= pc2 when (i2_writes_c = '1') else pc1;
    

    write_tag_to_z_flag_arf <= pz2 when (i2_writes_z = '1') else pz1;
    

    
    dest_flags_i1 <= new_tags_of_rrf_signal(23 downto 18) & new_c_tags(11 downto 6) & new_z_tags(11 downto 6);
    dest_flags_i2 <= new_tags_of_rrf_signal(17 downto 12) & new_c_tags(5 downto 0) & new_z_tags(5 downto 0);


    full_flags_i1 <= dest_flags_i1
                & resolved_c_for_i1(5 downto 0)
                & resolved_z_for_i1(5 downto 0)
                & c_valid_for_i1          
                & z_valid_for_i1          
                & resolved_c_for_i1(6)
                & resolved_z_for_i1(6);

    full_flags_i2 <= dest_flags_i2
                & resolved_c_for_i2(5 downto 0)
                & resolved_z_for_i2(5 downto 0)
                & c_valid_for_i2          
                & z_valid_for_i2          
                & resolved_c_for_i2(6)
                & resolved_z_for_i2(6);


    rob_write_enable <= (rrf_is_free_signal and z_rrf_is_free and c_rrf_is_free and rob_is_free);
    data_to_write_to_rob_for_i1(control_bits_width + 47 downto 48) <= control_signals_for_i1;
    data_to_write_to_rob_for_i1(47 downto 32) <= ip1;
    data_to_write_to_rob_for_i1(31) <= not(br_rs_is_empty);
    data_to_write_to_rob_for_i1(30 downto 28) <= address_of_register_to_write_to_1;
    data_to_write_to_rob_for_i1(27 downto 22) <= new_tags_of_rrf_signal(11 downto 6);
    data_to_write_to_rob_for_i1(21 downto 19) <= current_branch_tag_i1;
    data_to_write_to_rob_for_i1(18 downto 16) <= "101";
    data_to_write_to_rob_for_i1(15 downto 0) <= (others => '0');

    data_to_write_to_rob_for_i2(control_bits_width + 47 downto 48) <= control_signals_for_i2;
    data_to_write_to_rob_for_i2(47 downto 32) <= ip2;
    data_to_write_to_rob_for_i2(31) <= not(br_rs_is_empty) or i1_is_branch;
    data_to_write_to_rob_for_i2(30 downto 28) <= address_of_register_to_write_to_2;
    data_to_write_to_rob_for_i2(27 downto 22) <= new_tags_of_rrf_signal(5 downto 0);
    data_to_write_to_rob_for_i2(21 downto 19) <= current_branch_tag_i2;
    data_to_write_to_rob_for_i2(18 downto 16) <= "101";
    data_to_write_to_rob_for_i2(15 downto 0) <= (others => '0');

    process(
        address_of_register_to_write_to_1,
        address_of_register_to_write_to_2,
        alu_rs_is_free,
        br_rs_is_free,
        branch_predictor_bits,
        c_rrf_is_free,
        control_signals_for_i1,
        control_signals_for_i2,
        current_branch_tag_i1,
        current_branch_tag_i2,
        full_flags_i1,
        full_flags_i2,
        dest_flags_i1,
        dest_flags_i2,
        immediate_of_operation_1,
        immediate_of_operation_2,
        ip1,
        ip2,
        ls_rs_is_free,
        new_tags_of_rrf_signal,
        operation_type_1,
        operation_type_2,
        rrf_is_free_signal,
        rs_write_i1_operand_1_mux_cascade_output_signal,
        rs_write_i1_operand_2_mux_cascade_output_signal,
        rs_write_i2_operand_1_mux_cascade_output_signal,
        rs_write_i2_operand_2_mux_cascade_output_signal,
        sb_is_free,
        v1_for_i1,
        v1_for_i2,
        v2_for_i1,
        v2_for_i2,
        z_rrf_is_free,
        rob_is_free,i2_writes_z,i2_writes_c,i1_writes_c,i1_writes_z
    )
    begin
		  carry_rrf_tag_enable <= i2_writes_c & i1_writes_c;
		  zero_rrf_tag_enable  <= i2_writes_z & i1_writes_z;
		  c_flag_arf_write_enable <= i1_writes_c or i2_writes_c;
		  z_flag_arf_write_enable <= i1_writes_z or i2_writes_z;
        data_to_write_to_alu_rs_for_i1 <= (others => '0');
        data_to_write_to_alu_rs_for_i2 <= (others => '0');
        alu_rs_write_enable            <= (others => '0');

        data_to_write_to_ls_rs_for_i1  <= (others => '0');
        data_to_write_to_ls_rs_for_i2  <= (others => '0');
        ls_rs_write_enable             <= (others => '0');

        data_to_write_to_br_rs_for_i1  <= (others => '0');
        data_to_write_to_br_rs_for_i2  <= (others => '0');
        br_rs_write_enable             <= (others => '0');

        write_new_busy_bits_value_tags_etc_enable <= (others => '1');

        data_to_write_to_sb_for_i1 <= (others => '0');
        data_to_write_to_sb_for_i2 <= (others => '0');
        sb_write_enable            <= "00";

        stall_fetch <= '0';

        if (rrf_is_free_signal = '0' or z_rrf_is_free = '0' or c_rrf_is_free = '0' or rob_is_free = '0') then
            stall_fetch <= '1';
        else
            
            if (address_of_register_to_write_to_1 = "000") then
                
                data_to_write_to_br_rs_for_i1(control_bits_width + 111 downto control_bits_width + 78) <= full_flags_i1;
                data_to_write_to_br_rs_for_i1(control_bits_width + 77 downto 78) <= control_signals_for_i1;
                data_to_write_to_br_rs_for_i1(77 downto 62) <= ip1;
                data_to_write_to_br_rs_for_i1(61) <= '1';
                data_to_write_to_br_rs_for_i1(60 downto 45) <= rs_write_i1_operand_1_mux_cascade_output_signal;
                data_to_write_to_br_rs_for_i1(44) <= v1_for_i1;
                data_to_write_to_br_rs_for_i1(43 downto 28) <= rs_write_i1_operand_2_mux_cascade_output_signal;
                data_to_write_to_br_rs_for_i1(27) <= v2_for_i1;
                data_to_write_to_br_rs_for_i1(26 downto 11) <=  immediate_of_operation_1;
                data_to_write_to_br_rs_for_i1(10 downto 5) <= new_tags_of_rrf_signal(11 downto 6);
                data_to_write_to_br_rs_for_i1(4 downto 2) <= current_branch_tag_i1;
                data_to_write_to_br_rs_for_i1(1) <= v1_for_i1 and v2_for_i1;
                data_to_write_to_br_rs_for_i1(0) <= branch_predictor_bits(0);

                if br_rs_is_free = '1' then
                    br_rs_write_enable(0) <= '1';
                else
                    stall_fetch <= '1';
                end if;
            else
                case operation_type_1 is
                    when "0000" | "0001" | "0100" => 
                        
                        data_to_write_to_alu_rs_for_i1(control_bits_width + 91 downto control_bits_width + 58) <= full_flags_i1;
                        data_to_write_to_alu_rs_for_i1(control_bits_width + 57 downto 58) <= control_signals_for_i1;
                        data_to_write_to_alu_rs_for_i1(57 downto 42) <= ip1;
                        data_to_write_to_alu_rs_for_i1(41) <= '1';
                        data_to_write_to_alu_rs_for_i1(40 downto 25) <= rs_write_i1_operand_1_mux_cascade_output_signal;
                        
                        if operation_type_1 = "0100" then
                            data_to_write_to_alu_rs_for_i1(40 downto 25) <= immediate_of_operation_1;
                            data_to_write_to_alu_rs_for_i1(23 downto 8) <= (others => '0');
                            data_to_write_to_alu_rs_for_i1(6) <= '1';
                            data_to_write_to_alu_rs_for_i1(24) <= '1';
                            data_to_write_to_alu_rs_for_i1(7) <= '1';
                        elsif operation_type_1 = "0001" then
                            data_to_write_to_alu_rs_for_i1(23 downto 8) <= immediate_of_operation_1;
                            data_to_write_to_alu_rs_for_i1(6) <= v1_for_i1;
                            data_to_write_to_alu_rs_for_i1(24) <= v1_for_i1;
                            data_to_write_to_alu_rs_for_i1(7) <= '1';
                        else
                            data_to_write_to_alu_rs_for_i1(23 downto 8) <= rs_write_i1_operand_2_mux_cascade_output_signal;
                            data_to_write_to_alu_rs_for_i1(6) <= v1_for_i1 and v2_for_i1;
                            data_to_write_to_alu_rs_for_i1(24) <= v1_for_i1;
                            data_to_write_to_alu_rs_for_i1(7) <= v2_for_i1;
                        end if;
                        
                        data_to_write_to_alu_rs_for_i1(5 downto 0) <= new_tags_of_rrf_signal(11 downto 6);

                        if alu_rs_is_free = '1' then
                            alu_rs_write_enable(0) <= '1';
                        else
                            stall_fetch <= '1';
                        end if;

                    when "0010" | "0011" => 
                        
                        data_to_write_to_ls_rs_for_i1(control_bits_width + 91 downto control_bits_width + 74) <= dest_flags_i1;
                        data_to_write_to_ls_rs_for_i1(control_bits_width + 73 downto control_bits_width + 58) <= immediate_of_operation_1;
                        data_to_write_to_ls_rs_for_i1(control_bits_width + 57 downto 58) <= control_signals_for_i1;
                        data_to_write_to_ls_rs_for_i1(57 downto 42) <= ip1;
                        data_to_write_to_ls_rs_for_i1(41) <= '1';
                        data_to_write_to_ls_rs_for_i1(6) <= v2_for_i1;
                        data_to_write_to_ls_rs_for_i1(40 downto 25) <= rs_write_i1_operand_2_mux_cascade_output_signal;
                        data_to_write_to_ls_rs_for_i1(24) <= v2_for_i1;
                        data_to_write_to_ls_rs_for_i1(23 downto 8) <= immediate_of_operation_1;
                        data_to_write_to_ls_rs_for_i1(7) <= '1';
                        data_to_write_to_ls_rs_for_i1(5 downto 0) <= new_tags_of_rrf_signal(11 downto 6);

                        if ls_rs_is_free = '1' then
                            ls_rs_write_enable(0) <= '1';
                        else
                            stall_fetch <= '1';
                        end if;
                        
                        if operation_type_1 = "0011" then
                            data_to_write_to_sb_for_i1(56) <= '1';
                            data_to_write_to_sb_for_i1(55 downto 40) <= ip1;
                            data_to_write_to_sb_for_i1(39 downto 24) <= (others => '0');
                            data_to_write_to_sb_for_i1(23) <= '0';
                            data_to_write_to_sb_for_i1(22 downto 7) <= rs_write_i1_operand_1_mux_cascade_output_signal;
                            data_to_write_to_sb_for_i1(6 downto 1) <= rs_write_i1_operand_1_mux_cascade_output_signal(5 downto 0);
                            data_to_write_to_sb_for_i1(0) <= v1_for_i1;
                            
                            if sb_is_free = '1' then
                                sb_write_enable(0) <= '1';
                            else
                                stall_fetch <= '1';
                            end if;
                        end if;

                    when "0101" | "0110" | "0111" | "1000" =>
                        
                        data_to_write_to_br_rs_for_i1(control_bits_width + 111 downto control_bits_width + 78) <= full_flags_i1;
                        data_to_write_to_br_rs_for_i1(control_bits_width + 77 downto 78) <= control_signals_for_i1;
                        data_to_write_to_br_rs_for_i1(77 downto 62) <= ip1;
                        data_to_write_to_br_rs_for_i1(61) <= '1';
                        data_to_write_to_br_rs_for_i1(60 downto 45) <= rs_write_i1_operand_1_mux_cascade_output_signal;
                        data_to_write_to_br_rs_for_i1(44) <= v1_for_i1;
                        data_to_write_to_br_rs_for_i1(43 downto 28) <= rs_write_i1_operand_2_mux_cascade_output_signal;
                        data_to_write_to_br_rs_for_i1(27) <= v2_for_i1;
                        data_to_write_to_br_rs_for_i1(26 downto 11) <= immediate_of_operation_1;
                        data_to_write_to_br_rs_for_i1(10 downto 5) <= new_tags_of_rrf_signal(11 downto 6);
                        data_to_write_to_br_rs_for_i1(4 downto 2) <= current_branch_tag_i1;
                        data_to_write_to_br_rs_for_i1(1) <= v1_for_i1 and v2_for_i1;
                        data_to_write_to_br_rs_for_i1(0) <= branch_predictor_bits(0);

                        if br_rs_is_free = '1' then
                            br_rs_write_enable(0) <= '1';
                        else
                            stall_fetch <= '1';
                        end if;
                        
                    when others => null;
                end case;
            end if;

       
            if (address_of_register_to_write_to_2 = "000") then
                
                data_to_write_to_br_rs_for_i2(control_bits_width + 111 downto control_bits_width + 78) <= full_flags_i2;
                data_to_write_to_br_rs_for_i2(control_bits_width + 77 downto 78) <= control_signals_for_i2;
                data_to_write_to_br_rs_for_i2(77 downto 62) <= ip2;
                data_to_write_to_br_rs_for_i2(61) <= '1';
                data_to_write_to_br_rs_for_i2(60 downto 45) <= rs_write_i2_operand_1_mux_cascade_output_signal;
                data_to_write_to_br_rs_for_i2(44) <= v1_for_i2;
                data_to_write_to_br_rs_for_i2(43 downto 28) <= rs_write_i2_operand_2_mux_cascade_output_signal;
                data_to_write_to_br_rs_for_i2(27) <= v2_for_i2;
                data_to_write_to_br_rs_for_i2(26 downto 11) <=  immediate_of_operation_2;
                data_to_write_to_br_rs_for_i2(10 downto 5) <= new_tags_of_rrf_signal(5 downto 0);
                data_to_write_to_br_rs_for_i2(4 downto 2) <= current_branch_tag_i2;
                data_to_write_to_br_rs_for_i2(1) <= v1_for_i2 and v2_for_i2;
                data_to_write_to_br_rs_for_i2(0) <= branch_predictor_bits(1);

                if br_rs_is_free = '1' then
                    br_rs_write_enable(1) <= '1';
                else
                    stall_fetch <= '1';
                end if;
            else
                case operation_type_2 is
                    when "0000" | "0001" | "0100" => 
                        
                        data_to_write_to_alu_rs_for_i2(control_bits_width + 91 downto control_bits_width + 58) <= full_flags_i2;
                        data_to_write_to_alu_rs_for_i2(control_bits_width + 57 downto 58) <= control_signals_for_i2;
                        data_to_write_to_alu_rs_for_i2(57 downto 42) <= ip2;
                        data_to_write_to_alu_rs_for_i2(41) <= '1';
                        data_to_write_to_alu_rs_for_i2(40 downto 25) <= rs_write_i2_operand_1_mux_cascade_output_signal;
                        
                        if operation_type_2 = "0100" then
                            data_to_write_to_alu_rs_for_i2(40 downto 25) <= immediate_of_operation_2;
                            data_to_write_to_alu_rs_for_i2(23 downto 8) <= (others => '0');
                            data_to_write_to_alu_rs_for_i2(6) <= '1';
                            data_to_write_to_alu_rs_for_i2(24) <= '1';
                            data_to_write_to_alu_rs_for_i2(7) <= '1';
                        elsif operation_type_2 = "0001" then
                            data_to_write_to_alu_rs_for_i2(23 downto 8) <= immediate_of_operation_2;
                            data_to_write_to_alu_rs_for_i2(6) <= v1_for_i2;
                            data_to_write_to_alu_rs_for_i2(24) <= v1_for_i2;
                            data_to_write_to_alu_rs_for_i2(7) <= '1';
                        else
                            data_to_write_to_alu_rs_for_i2(23 downto 8) <= rs_write_i2_operand_2_mux_cascade_output_signal;
                            data_to_write_to_alu_rs_for_i2(6) <= v1_for_i2 and v2_for_i2;
                            data_to_write_to_alu_rs_for_i2(24) <= v1_for_i2;
                            data_to_write_to_alu_rs_for_i2(7) <= v2_for_i2;
                        end if;

                        data_to_write_to_alu_rs_for_i2(5 downto 0) <= new_tags_of_rrf_signal(5 downto 0);

                        if alu_rs_is_free = '1' then
                            alu_rs_write_enable(1) <= '1';
                        else
                            stall_fetch <= '1';
                        end if;

                    when "0010" | "0011" => 
                        
                        data_to_write_to_ls_rs_for_i2(control_bits_width + 91 downto control_bits_width + 74) <= dest_flags_i2;
                        data_to_write_to_ls_rs_for_i2(control_bits_width + 73 downto control_bits_width + 58) <= immediate_of_operation_2;
                        data_to_write_to_ls_rs_for_i2(control_bits_width + 57 downto 58) <= control_signals_for_i2;
                        data_to_write_to_ls_rs_for_i2(57 downto 42) <= ip2;
                        data_to_write_to_ls_rs_for_i2(41) <= '1';
                        data_to_write_to_ls_rs_for_i2(6) <= v2_for_i2;
                        data_to_write_to_ls_rs_for_i2(40 downto 25) <= rs_write_i2_operand_2_mux_cascade_output_signal;
                        data_to_write_to_ls_rs_for_i2(24) <= v2_for_i2;
                        data_to_write_to_ls_rs_for_i2(23 downto 8) <= immediate_of_operation_2;
                        data_to_write_to_ls_rs_for_i2(7) <= '1';
                        data_to_write_to_ls_rs_for_i2(5 downto 0) <= new_tags_of_rrf_signal(5 downto 0);

                        if ls_rs_is_free = '1' then
                            ls_rs_write_enable(1) <= '1';
                        else
                            stall_fetch <= '1';
                        end if;

                        if operation_type_2 = "0011" then
                            data_to_write_to_sb_for_i2(56) <= '1';
                            data_to_write_to_sb_for_i2(55 downto 40) <= ip2;
                            data_to_write_to_sb_for_i2(39 downto 24) <= (others => '0');
                            data_to_write_to_sb_for_i2(23) <= '0';
                            data_to_write_to_sb_for_i2(22 downto 7) <= rs_write_i2_operand_1_mux_cascade_output_signal;
                            data_to_write_to_sb_for_i2(6 downto 1) <= rs_write_i2_operand_1_mux_cascade_output_signal(5 downto 0);
                            data_to_write_to_sb_for_i2(0) <= v1_for_i2;
                            if sb_is_free = '1' then
                                sb_write_enable(1) <= '1';
                            else
                                stall_fetch <= '1';
                            end if;
                        end if;

                    when "0101" | "0110" | "0111" | "1000" =>
                        
                        data_to_write_to_br_rs_for_i2(control_bits_width + 111 downto control_bits_width + 78) <= full_flags_i2;
                        data_to_write_to_br_rs_for_i2(control_bits_width + 77 downto 78) <= control_signals_for_i2;
                        data_to_write_to_br_rs_for_i2(77 downto 62) <= ip2;
                        data_to_write_to_br_rs_for_i2(61) <= '1';
                        data_to_write_to_br_rs_for_i2(60 downto 45) <= rs_write_i2_operand_1_mux_cascade_output_signal;
                        data_to_write_to_br_rs_for_i2(44) <= v1_for_i2;
                        data_to_write_to_br_rs_for_i2(43 downto 28) <= rs_write_i2_operand_2_mux_cascade_output_signal;
                        data_to_write_to_br_rs_for_i2(27) <= v2_for_i2;
                        data_to_write_to_br_rs_for_i2(26 downto 11) <= immediate_of_operation_2;
                        data_to_write_to_br_rs_for_i2(10 downto 5) <= new_tags_of_rrf_signal(5 downto 0);
                        data_to_write_to_br_rs_for_i2(4 downto 2) <= current_branch_tag_i2;
                        data_to_write_to_br_rs_for_i2(1) <= v1_for_i2 and v2_for_i2;
                        data_to_write_to_br_rs_for_i2(0) <= branch_predictor_bits(1);

                        if br_rs_is_free = '1' then
                            br_rs_write_enable(1) <= '1';
                        else
                            stall_fetch <= '1';
                        end if;
                        
                    when others => null;
                end case;
            end if;
        end if;

    end process;
end architecture;