pragma solidity ^0.4.0;

// pragma experimental ABIEncoderV2;

// WORK IN PROGRESS //

contract Ballot {

   function test1() returns (string memory) {
       bytes memory permutations = findPermutations("greg");
       return readPermutation(permutations, 0);
   }
   
  function test2() returns (string memory) {
       bytes memory permutations = findPermutations("greg");
       return readPermutation(permutations, 1);
   }
   
  function getNumberOfPermutations(bytes memory permutations) returns (uint256 numberOfPermutations) {
      assembly {
          numberOfPermutations := div(mload(permutations), 0x40)
      }
  }
   
  function test() public {
      bytes memory permutations = findPermutations("bex");
      uint256 nPermutations = getNumberOfPermutations(permutations);
      emit PermutationCount(nPermutations);
      for(uint256 i = 0; i < nPermutations; i++) {
          emit Permutation(i, readPermutation(permutations, i));
      }
  }
  
  event PermutationCount(
      uint256 numberOfPermutations
      );
      
   event Permutation(
       uint256 index,
      string permutation  
   );
   
   event Bytes (
       bytes b
   );
   
   function testCount() public {
       bytes memory permutations = findPermutations("greg");
       uint256 nPermutations = getNumberOfPermutations(permutations);
       emit PermutationCount(nPermutations);
   }
   
  //function test3() returns uint256 {
      
  //}
    
  function readPermutation(bytes memory permutations, uint256 permutationIndex) public pure returns (string memory permutation) {
      assembly {
          let permutationOffset := mul(permutationIndex, 0x40)
          let permutationLength := mload(add(0x20 /*bytes length*/, add(permutations, permutationOffset)))
          let permutationValue := mload(add(0x20 /* bytes length */, add(permutations, add(permutationOffset, 0x20))))
          mstore(permutation, permutationLength)
          mstore(add(permutation, 0x20), permutationValue)
      }
  }
  
  function getB(string memory greg) public pure returns (bytes memory p) {
      p = new bytes(42);
      return p;
  }

  function findPermutations(string memory s) public pure returns (bytes memory retval) { //returns (string[] permutations) {
      //swapped = s;
      
      //permutations = new string[](3);
      //return;
      assembly {
           // let begin := mload(0x40)

          // MEMORY VERSION
          //mstore(swapped, mload(s))
          //mstore(add(swapped, 0x20), mload(add(s, 0x20)))
          //mstore8(add(swapped, 0x20), mload(add(s, 0x2)))
          //mstore8(add(swapped, 0x21), mload(add(s, 0x1)))
          
          // EFFICIENT VERSION
          //let sLen := mload(s)
          //mstore(swapped, sLen)
          //let sVal := mload(add(s, 0x20))
          //mstore(add(swapped, 0x20), sVal)
          //mstore8(add(swapped, 0x20), div(sVal, 0x1000000000000000000000000000000000000000000000000000000000000))
          //mstore8(add(swapped, 0x21), div(sVal, 0x100000000000000000000000000000000000000000000000000000000000000))
          
          
          // USING INDICES
          let sLength := mload(s)
          
          let nPermutations := 0x1
          for {let i := 2} lt(i, sLength) {i := add(i,1)} {
              nPermutations := mul(nPermutations, i)
          }
          let permutatios := mload(0x40)
          mstore(0x40, add(mload(0x40), add(0x20 /* length */, mul(0x40, nPermutations))))
          
          function swap(s,i,j,sLen) {
            let sVal := mload(add(s, 0x20))
          
            let pIpos := add(add(s, 0x20), i)
            let pJpos := add(add(s, 0x20), j)

            let sIVal := div(sVal, exp(2, sub(256, mul(8, add(i, 1)))))
            let sJVal := div(sVal, exp(2, sub(256, mul(8, add(j, 1)))))
            mstore8(pIpos, sJVal)
            mstore8(pJpos, sIVal)
          }
          
          function permute(s,i,sLen,permutations) {
           if eq(i,sub(sLen, 1)) {
               let newLen := add(mload(permutations), 1)
               mstore(permutations, newLen)
               mstore(add(permutations, add(0x20 /* permutations length */, mul(0x40, sub(newLen, 1)) /* perms up to now */ )), sLen)
               mstore(add(permutations, add(0x40 /* permutations length + 1 word for len */, mul(0x40, sub(newLen, 1)) /* perms up to now */ )), mload(add(s, 0x20)))
            }
            if lt(i, sub(sLen, 1)) {
                for {let j := i} lt(j, sLen) {j := add(j,1)} {
                    swap(s, i, j, sLen)
                    permute(s, add(i,1), sLen, permutations)
                    swap(s, i, j, sLen)
                }
            }
          }
          
          permute(s, 0, sLength, permutatios)
          mstore(permutatios, mul(0x40, mload(permutatios)))
          retval := permutatios
      }
      
      
     // return swapped;
   //  return permutations;
  }
}
