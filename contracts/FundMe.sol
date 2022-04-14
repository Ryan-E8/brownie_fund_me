//SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

//importing from the @chainlink/contracts npm package, this is in interface - not contract. Interfaces don't have full function implementations, functions aren't completed. in this case just the function name and return type.
//Interfaces compile down to an ABI - Application Binary Interface. The ABI tells solidity and other programming languages how it can interact with another contract. What functions can be called on another contract. Anytime you want to interact with an already deploed smart contract, you will need it's ABI.
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol"; //Import SafeMath so overflow doesn't occur, Solidity 0.8 and later this isn't needed

contract FundMe {
    using SafeMathChainlink for uint256; //Uses SafeMathChainlink for all of our uint256's which will prevent overflow. We are attaching the SafeMath library to uint256

    //mapping an address to a uint256 which is our value
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders; //an array of funders who funded on our contract
    address public owner;
    AggregatorV3Interface public priceFeed;

    //Anything in this function will immediately execute when the contract is deployed
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender; //Sets owner address to the address that deploys the contract
    }

    //Payable keyword, this function can be used to pay for things, with eth/ethereum. msg.sender and msg.value are keywords in every contract call and transaction. Sender is the sender of the function call and value is how much they sent.
    function fund() public payable {
        //$50
        uint256 minimumUSD = 50 * 10**18; //Since we are using gwei terms, we are multiplying it by 10 raised to the 18th, 18 decimals
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        ); //If the conversion rate of msg.value isn't >= $50 then we will stop executing. We are doing a revert, revert the transaction and the user will get their money back as well as any unspent gas
        addressToAmountFunded[msg.sender] += msg.value; //when you call this fund function, someone can send a value because it's payable, and we are saving it to this addressToAmountFunded. Put amount into value field, enter wallet address and fund it.
        funders.push(msg.sender); //adds the msg.sender address to our funders array
        //What the ETH -> USD conversion rate, this is for a minimum value people can send
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        //Tuple = a list of objects of potentially different types whose numbers is a constant at compile-time.
        (, int256 answer, , , ) = priceFeed.latestRoundData(); //latestRoundData returns 5 different variables so we need these commas because we are ignoring those variables and only using answer
        //get error because answer is type int and we want to return a uint. We need to typecast it to uint256
        return uint256(answer * 10000000000); //this multiply by 10 decimals places is not needed, just uses a wei standard, wei has 18 decimals and it originally added with 8. 8 + 10 = 18
    }

    //1 gwei 1000000000, this function calls our getPrice function to get the price of ethereum, then multiply that by the amount we put in and returns it to USD with a bunch of weird decimals.
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; //Move the number you get by 18 decimals
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        // return (minimumUSD * precision) / price;
        // We fixed a rounding error found in the video by adding one!
        return ((minimumUSD * precision) / price) + 1;
    }

    modifier onlyOwner() {
        //Modifier: A modifier is used to change the behavior of a function in a declarative way
        require(msg.sender == owner); //requires that only the owner can withdraw the balance
        _; //Run the require statement first then where this undercore is, run the rest of our code
    }

    function withdraw() public payable onlyOwner {
        //We implemented the onlyOwner modifier, so before we do the transfer, we are going to run the require in the modifier
        msg.sender.transfer(address(this).balance); //this is a keyword in solidity, it refers to the contract you are currently in. .balance is the balance in ether of the contract
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            //our loop starts at 0 then will finish when funderIndex is greater than funders array
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0; //Clearing addressToAmountFunded
        }
        funders = new address[](0); //Setting funders array to a new blank address array
    }
}
