pragma solidity ^0.4.17;

import "./ArtwookToken.sol";


contract CrowdsaleArtwookToken is ArtwookToken {
    uint256 public constant nativeDecimals = 8;

    /// @notice 60 million BOT tokens for sale
    uint256 public constant saleAmount = 100 * (10**6) * (10**decimals);

    // Crowdsale parameters
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public initialExchangeRate;
    uint256 public qtumCounter;
    bool private enableSale;


    // Events
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // jacky debug
    //event MonitorInput(uint256 value);
    //event MonitorExchange(uint256 amount);
    //event MonitorByStartBlock(uint256 blockNow, uint256 startBlock);
    //event MonitorByEndBlock(uint256 blockNow, uint256 endBlock);
    //event MonitorBuyStart(address indexed purchaser);
    /// @notice Creates new CrowdsaleArtwookToken contract
    /// @param _initialExchangeRate The exchange rate of Ether to BOT
    /// @param _presaleAmount The amount of BOT that will be available for presale
    function CrowdsaleArtwookToken(
        /// @param _fundingStartBlock The starting block of crowdsale
        /// @param _fundingEndBlock The ending block of crowdsale
        //uint256 _fundingStartBlock,
        //uint256 _fundingEndBlock,
        uint256 _initialExchangeRate,
        uint256 _presaleAmount)
        public
    {
        // require(_fundingStartBlock >= block.number);
        // require(_fundingEndBlock >= _fundingStartBlock);
        require(_initialExchangeRate > 0);

        // Converted to lowest denomination of BOT
        uint256 presaleAmountTokens = _presaleAmount * (10**decimals);
        require(presaleAmountTokens <= saleAmount);

        assert(nativeDecimals >= decimals);

        //fundingStartBlock = _fundingStartBlock;
        //fundingEndBlock = _fundingEndBlock;
        initialExchangeRate = _initialExchangeRate;

        // Mint the presale tokens, distribute to a receiver
        // Increase the totalSupply accordingly
        mintByOwner(owner, presaleAmountTokens);
    }

    /// @notice Fallback function to purchase tokens
    function() external payable {
        buyTokens(msg.sender);
    }

    /// @notice Allows buying tokens from different address than msg.sender
    /// @param _beneficiary Address that will contain the purchased tokens
    function buyTokens(address _beneficiary) public payable {
        // MonitorBuyStart(_beneficiary);
        // require(_beneficiary != address(0));
        //MonitorByStartBlock(block.number, fundingStartBlock);
        //require(block.number >= fundingStartBlock);
        //MonitorByEndBlock(block.number, fundingEndBlock);
        //require(block.number <= fundingEndBlock);
        require(enableSale == true);
        require(msg.value > 0);

        // MonitorInput(msg.value);

        uint256 tokenAmount = getTokenExchangeAmount(msg.value, initialExchangeRate, nativeDecimals, decimals);

        // MonitorExchange(tokenAmount);

        uint256 checkedSupply = totalSupply.add(tokenAmount);

        // Ensure new token increment does not exceed the sale amount
        assert(checkedSupply <= saleAmount);

        mintByPurchaser(_beneficiary, tokenAmount);
        TokenPurchase(msg.sender, _beneficiary, msg.value, tokenAmount);
        qtumCounter = qtumCounter + msg.value;
        owner.transfer(msg.value);
    }

    /// @notice Shows the amount of AKC the user will receive for amount of exchanged wei
    /// @param _weiAmount Exchanged wei amount to convert
    /// @param _exchangeRate Number of BOT per exchange token
    /// @param _nativeDecimals Number of decimals of the token being exchange for BOT
    /// @param _decimals Number of decimals of BOT token
    /// @return The amount of BOT that will be received
    function getTokenExchangeAmount(
        uint256 _weiAmount,
        uint256 _exchangeRate,
        uint256 _nativeDecimals,
        uint256 _decimals)
        public
        pure
        returns(uint256)
    {
        require(_weiAmount > 0);

        uint256 differenceFactor = (10**_nativeDecimals) / (10**_decimals);
        return _weiAmount.mul(_exchangeRate).div(differenceFactor);
    }

    /// @dev Function to enable crowdsale
    /// @return Boolean to signify successful minting
    function enableSaleByOwner() public onlyOwner returns (bool) {
        enableSale = true;
        return enableSale;
    }

    /// @dev Function to disable crowdsale
    /// @return Boolean to signify successful minting
    function disableSaleByOwner() public onlyOwner returns (bool) {
        enableSale = false;
        return enableSale;
    }

    /// @dev Function to get crowdsale status
    /// @return Boolean to signify successful minting
    function getSaleStatus() public onlyOwner view returns (bool) {
        return enableSale;
    }

    /// @dev Function allow owner to change exchange rate
    function setExchange(uint256 _initialExchangeRate) public onlyOwner {
        require(_initialExchangeRate > 0);
        initialExchangeRate = _initialExchangeRate;
    }

    /// @dev Function to allow crowdsale participants to mint tokens when purchasing
    /// @param _to Address to mint the tokens to
    /// @param _amount Amount of tokens that will be minted
    /// @return Boolean to signify successful minting
    function mintByPurchaser(address _to, uint256 _amount) private returns (bool) {
        return mint(_to, _amount);
    }


}
