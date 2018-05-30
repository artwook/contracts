pragma solidity ^0.4.20;

import './AKC.sol';

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

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
  }

}

contract Pausable is Ownable {
    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() { require(!paused); _; }
    modifier whenPaused() { require(paused); _; }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract Withdrawable is Ownable {
    function withdrawEther(address _to, uint _value) onlyOwner public returns(bool) {
        require(_to != address(0));
        require(address(this).balance >= _value);

        _to.transfer(_value);

        return true;
    }

    function withdrawTokens(ERC20 _token, address _to, uint _value) onlyOwner public returns(bool) {
        require(_to != address(0));

        return _token.transfer(_to, _value);
    }
}

contract ArtwookCoinCrowdsale is Pausable, Withdrawable {
  using SafeMath for uint;

  struct Step {
      uint priceTokenWei;
      uint minInvestEth;
      uint timestamp;
      uint tokensSold;
      uint collectedWei;

      bool transferBalance;
      bool sale;
      bool issue;
  }
  AKC public token;
  address public beneficiary = msg.sender;

  Step[] public steps;
  uint8 public currentStep = 0;
  uint public totalTokensSold = 0;
  uint public totalCollectedWei = 0;
  bool public crowdsaleClosed = false;
  uint public totalTokensForSale = 0;

  mapping(address => uint256) public canSell;

  event Purchase(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
  event Issue(address indexed holder, uint256 tokenAmount);
  event Sell(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
  event NewRate(uint256 rate);
  event NextStep(uint8 step);
  event CrowdsaleClose();

  function Crowdsale(address akctoken) public {
      require(token==address(0));
      /* token = new AKC(); */
      token = akctoken;
      // crowdsale only sale 50% of totalSupply
      totalTokensForSale = 100000000 * 10 ** 18;
      uint num1 = 1 ether;
      steps.push(Step(num1.div(5000000*100).mul(90), 0.01 ether, 1524105000, 0, 0, true, false, true));
      steps.push(Step(num1.div(5000000*100).mul(95), 0.01 ether, 1524105120, 0, 0, true, false, true));
      steps.push(Step(num1.div(5000000*100).mul(100), 0.01 ether, 1524105300, 0, 0, true, false, true));
  }

  // Fallback function to purchase tokens
  function() external payable  {
      purchase(msg.sender);
  }

  function purchase(address sender) whenNotPaused payable public {
      require(!crowdsaleClosed);
      require(now>steps[0].timestamp);

      if (now > steps[1].timestamp && currentStep < 1){
        currentStep = 1;
        emit NextStep(currentStep);
      }
      if (now > steps[2].timestamp && currentStep < 2){
        currentStep = 2;
        emit NextStep(currentStep);
      }
      Step memory step = steps[currentStep];

      require(msg.value >= step.minInvestEth);

      require(totalTokensSold < totalTokensForSale);

      uint sum = msg.value;
      uint amount = sum.mul(1 ether).div(step.priceTokenWei);
      uint retSum = 0;

      if(totalTokensSold.add(amount) > totalTokensForSale) {
          uint retAmount = totalTokensSold.add(amount).sub(totalTokensForSale);
          retSum = retAmount.mul(step.priceTokenWei).div(1 ether);

          amount = amount.sub(retAmount);
          sum = sum.sub(retSum);
      }

      totalTokensSold = totalTokensSold.add(amount);
      totalCollectedWei = totalCollectedWei.add(sum);
      steps[currentStep].tokensSold = step.tokensSold.add(amount);
      steps[currentStep].collectedWei = step.collectedWei.add(sum);

      if(currentStep == 0) {
          canSell[sender] = canSell[sender].add(amount);
      }

      token.mint(sender, amount);

      if(retSum > 0) {
          sender.transfer(retSum);
      }

      emit Purchase(sender, amount, sum);
  }

  function issue(address _to, uint256 _value) onlyOwner whenNotPaused public {
      require(!crowdsaleClosed);

      Step memory step = steps[currentStep];

      require(step.issue);
      /* require(step.tokensSold.add(_value) <= step.tokensForSale); */

      steps[currentStep].tokensSold = step.tokensSold.add(_value);

      if(currentStep == 0) {
          canSell[_to] = canSell[_to].add(_value);
      }

      token.mint(_to, _value);

      emit Issue(_to, _value);
  }

  function closeCrowdsale() onlyOwner public {
      require(!crowdsaleClosed);

      beneficiary.transfer(address(this).balance);
      /* token.mint(beneficiary, token.cap().sub(token.totalSupply())); */
      /* token.finishMinting(); */
      /* token.transferOwnership(beneficiary); */
      /* token.changeController(beneficiary); */
      token.setOwner(beneficiary);

      crowdsaleClosed = true;

      emit CrowdsaleClose();
  }
}
