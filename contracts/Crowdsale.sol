pragma solidity ^0.4.20;

import './AKC.sol';

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error.
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
  }

}

/**
 * @title Pausable
 * @dev This let a contract have a paused status to pause and restart what contract want.
 *
 */
contract Pausable is Ownable {
    bool public paused = false;

    event Pause();
    event Unpause();

    /**
     * @dev Throws if paused is true.
     */
    modifier whenNotPaused() { require(!paused); _; }

    /**
     * @dev Throws if paused is false.
     */
    modifier whenPaused() { require(paused); _; }

    /**
     * @dev Set paused to true.
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev Set paused to false.
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

/**
 * @title Withdrawable
 * @dev Allow contract owner to withdrow Ether or ERC20 token from contract.
 *
 */
contract Withdrawable is Ownable {
    /**
    * @dev withdraw Ether from contract
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function withdrawEther(address _to, uint _value) onlyOwner public returns(bool) {
        require(_to != address(0));
        require(address(this).balance >= _value);

        _to.transfer(_value);

        return true;
    }

    /**
    * @dev withdraw ERC20 token from contract
    * @param _token ERC20 token contract adress.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function withdrawTokens(ERC20 _token, address _to, uint _value) onlyOwner public returns(bool) {
        require(_to != address(0));

        return _token.transfer(_to, _value);
    }
}

/**
 * @title ArtwookCoinCrowdsale
 * @dev AKC token sale contract.
 */
contract AKCCrowdsale is Pausable, Withdrawable {
  using SafeMath for uint;

  struct Step {
      uint priceTokenWei;
      uint minInvestEth;
      uint timestamp;
      uint tokensSold;
      uint collectedWei;

  }
  AKC public token;
  address public beneficiary;

  Step[] public steps;
  uint8 public currentStep = 0;
  uint public totalTokensSold = 0;
  uint public totalCollectedWei = 0;
  bool public crowdsaleClosed = false;
  uint public totalTokensForSale = 0;

  event Purchase(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
  event NextStep(uint8 step);
  event CrowdsaleClose();

  /**
  * @dev Initialize the crowdsale conditions.
  * @param akctoken AKC token contract adress.
  */
  function AKCCrowdsale(AKC akctoken, uint phase1, uint phase2, uint phase3, uint phase4, address multiSigWallet) public {
      require(token==address(0));
      /* token = new AKC(); */
      token = akctoken;
      beneficiary = multiSigWallet;
      // crowdsale only sale 4.5% of totalSupply
      totalTokensForSale = 9000000 ether;
      uint oneEther = 1 ether;
      /**
      * Crowdsale is conducted in three phases. Token exchange rate is 1Ether:3000AKC
      * The crowdsale starts on August 20, 2018.
      * 2018/07/20 - 2018/07/26   15% off on AKC token exchange rate.
      * 2018/07/27 - 2018/08/02   10% off on AKC token exchange rate.
      * 2018/08/03 - 2018/07/09   5% off on AKC token exchange rate.
      * 2018/07/10 - 2018/07/16   Original exchange rate.
      */
      steps.push(Step(oneEther.div(3450), 0.01 ether, phase1, 0, 0));
      steps.push(Step(oneEther.div(3300), 0.01 ether, phase2, 0, 0));
      steps.push(Step(oneEther.div(3150), 0.01 ether, phase3, 0, 0));
      steps.push(Step(oneEther.div(3000), 0.01 ether, phase4, 0, 0));
  }

  /**
  * @dev Fallback function that will delegate the request to purchase().
  */
  function() external payable  {
      purchase(msg.sender);
  }

  /**
  * @dev purchase AKC
  * @param sender The address to receive AKC.
  */
  function purchase(address sender) whenNotPaused payable public {
      require(!crowdsaleClosed);
      require(now>steps[0].timestamp);
      /*Update the step based on the current time.*/
      if (now > steps[1].timestamp && currentStep < 1){
        currentStep = 1;
        emit NextStep(currentStep);
      }
      if (now > steps[2].timestamp && currentStep < 2){
        currentStep = 2;
        emit NextStep(currentStep);
      }
      if (now > steps[3].timestamp && currentStep < 3){
        currentStep = 3;
        emit NextStep(currentStep);
      }
      /* Step memory step = steps[currentStep]; */

      require(msg.value >= steps[currentStep].minInvestEth);
      require(totalTokensSold < totalTokensForSale);

      uint sum = msg.value;
      uint amount = sum.div(steps[currentStep].priceTokenWei).mul(1 ether);
      uint retSum = 0;

      /* Calculate excess Ether */
      if(totalTokensSold.add(amount) > totalTokensForSale) {
          uint retAmount = totalTokensSold.add(amount).sub(totalTokensForSale);
          retSum = retAmount.mul(steps[currentStep].priceTokenWei).div(1 ether);
          amount = amount.sub(retAmount);
          sum = sum.sub(retSum);
      }

      /* Record purchase info */
      totalTokensSold = totalTokensSold.add(amount);
      totalCollectedWei = totalCollectedWei.add(sum);
      steps[currentStep].tokensSold = steps[currentStep].tokensSold.add(amount);
      steps[currentStep].collectedWei = steps[currentStep].collectedWei.add(sum);

      /* Mint and Send AKC */
      /* token.mint(sender, amount); */
      token.transfer(sender, amount);

      /* Return the excess Ether */
      if(retSum > 0) {
          sender.transfer(retSum);
      }

      beneficiary.transfer(address(this).balance);
      emit Purchase(sender, amount, sum);
  }

  /**
  * @dev close crowdsale.
  */
  function closeCrowdsale() onlyOwner public {
      require(!crowdsaleClosed);
      /* Transfer the Ether from the contract to the beneficiary's adress.*/
      beneficiary.transfer(address(this).balance);
      token.transfer(beneficiary, token.balanceOf(address(this)));
      /* Set AKC contract owner to beneficiary.*/
      /* token.setOwner(beneficiary); */
      crowdsaleClosed = true;
      emit CrowdsaleClose();
  }
}
