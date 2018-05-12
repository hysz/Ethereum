pragma solidity ^0.4.23;

pragma experimental ABIEncoderV2;

library LibResult {
    struct Result {
        uint256 a;
        uint256 b;
        uint256 c;
    }
}

contract Server {
    function foo()
        public pure
        returns (LibResult.Result memory result)
    {
        result.a = 1;
        result.b = 2;
        result.c = 3;
        return result;
    } 
}

contract Proxy {
    Server server;
    constructor() public {
        server = new Server();
    }
    
    function foo() public {
        bytes4 selector = server.foo.selector;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, selector)
           
            let success := call(
                gas,                    // forward all gas
                sload(server_slot),     // server address
                0x0,                    // no ether
                ptr,                    // pointer to start of input
                0x4,                    // length of input
                ptr,                    // write output over input
                0x0                     // output size
            )
            if eq(success, 0) {
                revert(0, 0)
            }
            
            let resultLen := returndatasize()
            returndatacopy(ptr, 0, resultLen)
            return(ptr, resultLen) 
        } 
    }
}

contract Client {
    Proxy proxy;
    
    event LogResult (
        LibResult.Result result
    );
    
    constructor() public {
        proxy = new Proxy();
    }
   
    function foo() public {
        LibResult.Result memory result;
        bytes4 selector = proxy.foo.selector;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, selector)
           
            let success := call(
                gas,                // forward all gas
                sload(proxy_slot),  // proxy address
                0x0,                // no ether
                ptr,                // pointer to start of input
                0x4,                // length of input
                ptr,                // write output over input
                0x0                 // output size
            )
            if eq(success, 0) {
                revert(0, 0)
            }
            
            let resultLen := returndatasize()
            returndatacopy(result, 0, resultLen)
        }  
        
         emit LogResult(result);
    }
}

