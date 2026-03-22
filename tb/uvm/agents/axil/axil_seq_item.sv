class axil_seq_item extends uvm_sequence_item;
  rand bit        is_write;
  rand bit [31:0] addr;
  rand bit [31:0] data;
       bit [31:0] rdata;
       bit [1:0]  resp;

  `uvm_object_utils_begin(axil_seq_item)
    `uvm_field_int(is_write, UVM_DEFAULT)
    `uvm_field_int(addr,     UVM_DEFAULT)
    `uvm_field_int(data,     UVM_DEFAULT)
    `uvm_field_int(rdata,    UVM_DEFAULT | UVM_NOCOMPARE)
    `uvm_field_int(resp,     UVM_DEFAULT | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name = "axil_seq_item");
    super.new(name);
  endfunction
endclass
