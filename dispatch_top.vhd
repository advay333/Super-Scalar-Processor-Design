library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dispatch_top is
    generic (control_bits_width : integer := 20);
    port (
        clk : in std_logic;
        rst : in std_logic;

        -- from respective RSs
        alu_rs_is_free: in std_logic;
        ls_rs_is_free: in std_logic;
        br_rs_is_free: in std_logic;
        br_rs_is_empty: in std_logic;

        -- from decode stage
        ip1: in std_logic_vector(15 downto 0);
        ip2: in std_logic_vector(15 downto 0);
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

        -- current_branch_tag_i1: in std_logic_vector(2 downto 0);
        -- current_branch_tag_i2: in std_logic_vector(2 downto 0);

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

architecture structural of dispatch_top is

    component dispatch is
        generic (control_bits_width : integer := 20);
        port (
            alu_rs_is_free: in std_logic;
            ls_rs_is_free: in std_logic;
            br_rs_is_free: in std_logic;
            br_rs_is_empty: in std_logic;
            ip1: in std_logic_vector(15 downto 0);
            ip2: in std_logic_vector(15 downto 0);
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
            
            
            data_to_write_to_alu_rs_for_i1: out std_logic_vector(control_bits_width + 91 downto 0);
            data_to_write_to_alu_rs_for_i2: out std_logic_vector(control_bits_width + 91 downto 0);
            alu_rs_write_enable: out std_logic_vector(1 downto 0);
            data_to_write_to_ls_rs_for_i1: out std_logic_vector(control_bits_width + 91 downto 0);
            data_to_write_to_ls_rs_for_i2: out std_logic_vector(control_bits_width + 91 downto 0);
            ls_rs_write_enable: out std_logic_vector(1 downto 0);
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
    end component;

    component branch_tag_register is
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            enable      : in  std_logic;
            tag_in      : in  unsigned(2 downto 0);
            tag_out     : out unsigned(2 downto 0)
        );
    end component;

    signal current_branch_tag   : unsigned(2 downto 0);
    signal next_branch_tag      : unsigned(2 downto 0);
    signal tag_update_enable    : std_logic;
    
    signal i1_is_branch         : std_logic;
    signal i2_is_branch         : std_logic;
    
    signal current_tag_i1_std   : std_logic_vector(2 downto 0);
    signal current_tag_i2_std   : std_logic_vector(2 downto 0);

begin

    i1_is_branch <= '1' when (address_of_register_to_write_to_1 = "000" or 
                              operation_type_1 = "0101" or operation_type_1 = "0110" or 
                              operation_type_1 = "0111" or operation_type_1 = "1000") else '0';
                              
    i2_is_branch <= '1' when (address_of_register_to_write_to_2 = "000" or 
                              operation_type_2 = "0101" or operation_type_2 = "0110" or 
                              operation_type_2 = "0111" or operation_type_2 = "1000") else '0';

    process(current_branch_tag, i1_is_branch, i2_is_branch, br_rs_is_empty)
        variable current_tag_int : integer range 0 to 7;
        variable i1_tag_int      : integer range 0 to 7;
        variable i2_tag_int      : integer range 0 to 7;
    begin
        if br_rs_is_empty = '1' then
            current_tag_int := 0; 
        else
            current_tag_int := to_integer(current_branch_tag);
        end if;

        if i1_is_branch = '1' then
            if i1_tag_int = 7 then
                i1_tag_int := 1;
				else 
					i1_tag_int := current_tag_int + 1;
            end if;
        else
            if current_tag_int = 0 then
                i1_tag_int := 0;
            else
                i1_tag_int := current_tag_int;
            end if;
        end if;

        if i2_is_branch = '1' then
            if i2_tag_int = 7 then
                i2_tag_int := 1;
				else 
					i2_tag_int := i1_tag_int + 1;
            end if;
        else
            i2_tag_int := i1_tag_int;
        end if;

        current_tag_i1_std <= std_logic_vector(to_unsigned(i1_tag_int, 3));
        current_tag_i2_std <= std_logic_vector(to_unsigned(i2_tag_int, 3));

        if (i1_is_branch = '1' or i2_is_branch = '1' or br_rs_is_empty = '1') then
            tag_update_enable <= '1';
            next_branch_tag   <= to_unsigned(i2_tag_int, 3);
        else
            tag_update_enable <= '0';
            next_branch_tag   <= current_branch_tag;
        end if;
    end process;

    branch_tag_inst : branch_tag_register
        port map (
            clk     => clk,
            rst     => rst,
            enable  => tag_update_enable,
            tag_in  => next_branch_tag,
            tag_out => current_branch_tag
        );

    dispatch_inst : dispatch
        generic map (
            control_bits_width => control_bits_width
        )
        port map (
            alu_rs_is_free => alu_rs_is_free,
            ls_rs_is_free => ls_rs_is_free,
            br_rs_is_free => br_rs_is_free,
            br_rs_is_empty => br_rs_is_empty,
            ip1 => ip1,
            ip2 => ip2,
            operation_type_1 => operation_type_1,
            operation_type_2 => operation_type_2,
            addresses_of_register_to_read_from_1 => addresses_of_register_to_read_from_1,
            addresses_of_register_to_read_from_2 => addresses_of_register_to_read_from_2,
            immediate_of_operation_1 => immediate_of_operation_1,
            immediate_of_operation_2 => immediate_of_operation_2,
            address_of_register_to_write_to_1 => address_of_register_to_write_to_1,
            address_of_register_to_write_to_2 => address_of_register_to_write_to_2,
            dependency_bits => dependency_bits,
            control_signals_for_i1 => control_signals_for_i1,
            control_signals_for_i2 => control_signals_for_i2,
            
            i1_reads_c => i1_reads_c,
            i1_writes_c => i1_writes_c,
            i1_reads_z => i1_reads_z,
            i1_writes_z => i1_writes_z,
            i2_reads_c => i2_reads_c,
            i2_writes_c => i2_writes_c,
            i2_reads_z => i2_reads_z,
            i2_writes_z => i2_writes_z,

            current_branch_tag_i1 => current_tag_i1_std,
            current_branch_tag_i2 => current_tag_i2_std,

            rrf_busy_bits_col => rrf_busy_bits_col,
            operand_1_register_to_read_1_tag_rrf_data => operand_1_register_to_read_1_tag_rrf_data,
            operand_1_register_to_read_2_tag_rrf_data => operand_1_register_to_read_2_tag_rrf_data,
            operand_2_register_to_read_1_tag_rrf_data => operand_2_register_to_read_1_tag_rrf_data,
            operand_2_register_to_read_2_tag_rrf_data => operand_2_register_to_read_2_tag_rrf_data,

            zero_flag_rrf_busy_bits_col => zero_flag_rrf_busy_bits_col,
            carry_flag_rrf_busy_bits_col => carry_flag_rrf_busy_bits_col,
            c_flag_rrf_data => c_flag_rrf_data,
            z_flag_rrf_data => z_flag_rrf_data,

            operand_1_register_to_read_1 => operand_1_register_to_read_1,
            operand_1_register_to_read_2 => operand_1_register_to_read_2,
            operand_2_register_to_read_1 => operand_2_register_to_read_1,
            operand_2_register_to_read_2 => operand_2_register_to_read_2,

            cz_flag_arf_data => cz_flag_arf_data,

            rob_is_free => rob_is_free,
            sb_is_free => sb_is_free,
            branch_predictor_bits => branch_predictor_bits,

            data_to_write_to_alu_rs_for_i1 => data_to_write_to_alu_rs_for_i1,
            data_to_write_to_alu_rs_for_i2 => data_to_write_to_alu_rs_for_i2,
            alu_rs_write_enable => alu_rs_write_enable,
            data_to_write_to_ls_rs_for_i1 => data_to_write_to_ls_rs_for_i1,
            data_to_write_to_ls_rs_for_i2 => data_to_write_to_ls_rs_for_i2,
            ls_rs_write_enable => ls_rs_write_enable,
            data_to_write_to_br_rs_for_i1 => data_to_write_to_br_rs_for_i1,
            data_to_write_to_br_rs_for_i2 => data_to_write_to_br_rs_for_i2,
            br_rs_write_enable => br_rs_write_enable,
            
            read_addresses_of_arf => read_addresses_of_arf,
            write_tags_to_these_addresses_of_arf => write_tags_to_these_addresses_of_arf,
            
            write_tag_to_c_flag_arf => write_tag_to_c_flag_arf,
            write_tag_to_z_flag_arf => write_tag_to_z_flag_arf,
            c_flag_arf_write_enable => c_flag_arf_write_enable,
            z_flag_arf_write_enable => z_flag_arf_write_enable,

            read_addresses_of_rrf => read_addresses_of_rrf,
				
				carry_tag_i1 => carry_tag_i1,
				carry_tag_i2 => carry_tag_i2,
				zero_tag_i1  => zero_tag_i1,
				zero_tag_i2  => zero_tag_i2,
				carry_rrf_tag_enable => carry_rrf_tag_enable,
				zero_rrf_tag_enable  => zero_rrf_tag_enable,
            new_tags_of_rrf_for_writing_to_i1_destination => new_tags_of_rrf_for_writing_to_i1_destination,
            new_tags_of_rrf_for_writing_to_i2_destination => new_tags_of_rrf_for_writing_to_i2_destination,
            new_tags_of_rrf_for_writing_to_i1_pc => new_tags_of_rrf_for_writing_to_i1_pc,
            new_tags_of_rrf_for_writing_to_i2_pc => new_tags_of_rrf_for_writing_to_i2_pc,
            write_new_busy_bits_value_tags_etc_enable => write_new_busy_bits_value_tags_etc_enable,
            data_to_write_to_rob_for_i1 => data_to_write_to_rob_for_i1,
            data_to_write_to_rob_for_i2 => data_to_write_to_rob_for_i2,
            rob_write_enable => rob_write_enable,
            data_to_write_to_sb_for_i1 => data_to_write_to_sb_for_i1,
            data_to_write_to_sb_for_i2 => data_to_write_to_sb_for_i2,
            sb_write_enable => sb_write_enable,
            stall_fetch => stall_fetch
        );

end architecture;