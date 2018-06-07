pragma solidity ^0.4.23;

pragma experimental ABIEncoderV2;

library LibData {
    struct Input {
        uint256 a;
        uint256 b;
        uint256 c;
        bytes d;
    }
    uint public constant InputSize = 128;
    function getInputSize() public pure returns (uint) {
        return InputSize;
    }
    
    struct Output {
        uint256 a;
        uint256 b;
        uint256 c;
        bytes d;
        bytes e;
    }
    uint public constant OutputSize = 160;
    function getOutputSize() public pure returns (uint) {
        return OutputSize;
    }
}

contract Server {
    function foo(LibData.Input memory input)
        public
        returns (LibData.Output memory output)
    {
        // Derive output from input
        output.a = input.a + 1;
        output.b = input.b + 1;
        output.c = input.c + 1;
        uint len = 33;
        output.d = new bytes(len);
        for(uint i = 0; i < len; ++i) output.d[i] = byte(uint8(input.d[i])+1);
        output.e = new bytes(len);
        for(i = 0; i < len; ++i) output.e[i] = byte(uint8(input.d[i])+2);
        return output;
    }
}

contract Proxy {
    Server server;
    constructor() public {
        server = new Server();
    }
    
    function foo(LibData.Input input)
        public // Solidity does not yet support external with complex input data
        returns (LibData.Output output)
    {
        bytes4 selector = server.foo.selector;
        uint256 outputSize = LibData.getOutputSize();
        assembly {
            // Get free memory ptr
            let headerAreaStart := mload(0x40)
            // Calculate header size using calldata
            let cdSize := calldatasize()
            let headerAreaEnd := add(headerAreaStart, cdSize)
            // Store the selector of destination at beginning of header.
            // This overwrites the selector of this function (Proxy.foo)
            mstore(headerAreaStart, selector)
            // Copy calldata into header, skipping selector of Proxy.foo
            calldatacopy(add(headerAreaStart, 0x4), 0x4, cdSize)
            // Set free memory ptr to end of header area
            mstore(0x40, headerAreaEnd)
            // Forward input to server for processing
            let success := delegatecall(
                gas,                                    // forward all gas
                sload(server_slot),                     // server address
                headerAreaStart,                        // pointer to start of input
                sub(headerAreaEnd, headerAreaStart),    // length of input
                headerAreaStart,                        // write output over input
                outputSize                              // expected output size
            )
            // Throw (add custom handling logic here)
            if eq(success, 0) {
                revert(0, 0)
            }
            // Return server output to caller
            let resultLen := returndatasize()
            returndatacopy(output, 0, resultLen)
            return(output, resultLen) 
        } 
    }
}

contract Client {
    Proxy proxy;
    
    event LogData (
        LibData.Input,
        LibData.Output
    );
    
    constructor() public {
        proxy = new Proxy();
    }
   
    function foo() public {
        // Create some input
        LibData.Input memory input;
        input.a = 50;
        input.b = 60;
        input.c = 70;
        uint len = 33;
        input.d = new bytes(len);
        for(uint i = 0; i < len; ++i) input.d[i] = byte((i%0xe)+1);
        
        // Call Server via proxy
        LibData.Output memory output = proxy.foo(input);
        emit LogData(input, output);
        
        // Validate output
        require(output.a == input.a + 1, "Bad output.a");
        require(output.b == input.b + 1, "Bad output.b");
        require(output.c == input.c + 1, "Bad output.c");
        require(output.d.length == input.d.length, "Bad output.d.length");
        bool arraysMatch = true;
        for(i = 0; i < output.d.length; ++i) {
            if(output.d[i] != byte( uint8(input.d[i]) + 1)) {
                arraysMatch = false;
                break;
            }
        }
        require(arraysMatch, "Bad output.d");
        require(output.e.length == output.d.length, "Bad output.e.length");
        for(i = 0; i < output.e.length; ++i) {
            if(output.e[i] != byte( uint8(input.d[i]) + 2)) {
                arraysMatch = false;
                break;
            }
        }
        require(arraysMatch, "Bad output.e");
    }
}
