function memcpy(
        uint256 dest,
        uint256 source,
        uint256 length
    )
        internal
        
    {
        
        assembly {
            // Get the number of words to copy
            let lenFullWords := div(add(length, 0x1F), 0x20)
            let remainder := mod(length, 0x20)
            
            if gt(remainder, 0) {
                lenFullWords := sub(lenFullWords, 1)
            }

            // Copy full words
            let offset := 0
            for {offset := 0} lt(offset, mul(0x20, lenFullWords)) {offset := add(offset, 0x20)} {
                mstore(add(dest, offset),  mload(add(source, offset)))
            }
            
            // Copy remaining bytes
            if gt(remainder, 0) {
                let maxMask := 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                
                let cpyMaskFactor := exp(2, mul(8, sub(0x20, remainder)))
                let cpyMask := mul(div(maxMask, cpyMaskFactor), cpyMaskFactor)
                let cpyBytes := and(cpyMask, mload(add(source, offset)))
                
                let keepMaskFactor := exp(2, mul(8, remainder))
                let keepMask := div(mul(maxMask, keepMaskFactor), keepMaskFactor)
                let keepBytes := and(keepMask, mload(add(dest, offset)))
                
                let newWord := or(cpyBytes, keepBytes)
                mstore(add(dest, offset), newWord)
            }
        }
    }
