pragma solidity ^0.4.19;

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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

}

contract BasicToken is ERC20Basic, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract MintableToken is StandardToken {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() { require(!mintingFinished); _; }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

    function finishMinting() onlyOwner canMint public returns(bool) {
        mintingFinished = true;

        emit MintFinished();

        return true;
    }
}

contract CappedToken is MintableToken {
    uint256 public cap;

    function CappedToken(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        require(totalSupply.add(_amount) <= cap);

        return super.mint(_to, _amount);
    }
}

contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;

        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);

        emit Burn(burner, _value);
    }
}

contract ArtwookCoin is CappedToken, BurnableToken {
    string  public  constant name = "Artwook Coin";
    string  public  symbol = "AKC";
    uint    public  constant decimals = 18;
    function ArtwookCoin() CappedToken(200000000 * 10 ** decimals) public {

    }
    function transferOwner(address _from, address _to, uint256 _value) onlyOwner canMint public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }
}

//=====================crowdsale======================
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
  ArtwookCoin public token;
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

  function Crowdsale() public {
      require(token==address(0));
      token = new ArtwookCoin();
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
      token.mint(beneficiary, token.cap().sub(token.totalSupply()));
      token.finishMinting();
      token.transferOwnership(beneficiary);

      crowdsaleClosed = true;

      emit CrowdsaleClose();
  }
}
