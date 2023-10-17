// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";



interface IDexRouter {
   

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function WETH() external pure returns (address);

}



contract Presale is Ownable(msg.sender)  {
   
    using SafeERC20 for IERC20;


    IERC20 public immutable WETH;

    mapping(address => uint256) public claimableTokens;
    mapping(address => uint256) public claimedTokens;
    mapping(address => bool) public acceptedCurrencies;

    IDexRouter public dexRouter;

    // todo change price
    uint256 public pricePerToken = 10000000;
    IERC20 public immutable PEAPE_TOKEN;


    uint256 public totalTokensSold;
    uint256 public totalRaised;

    bool public isParticipationEnabled;
    bool public isClaimEnabled;

    event onParticipate(address token,uint256 amountPaid,uint256 peapeReceived,uint256 ethReceived);
    event onClaim(uint256 claimAmount);


    constructor(
        address peapeTokenAddress,
        address _dexRouterAddress) {

        PEAPE_TOKEN = IERC20(peapeTokenAddress);
        WETH = IERC20(dexRouter.WETH());
        acceptedCurrencies[address(WETH)] = true;
        dexRouter= IDexRouter(_dexRouterAddress);
    }

    receive() external payable {}

    function flipStatus() public onlyOwner{
        isParticipationEnabled = !isParticipationEnabled;
    }

    function manageAcceptedCurrencies(address currency,bool isAdd) public onlyOwner{
        acceptedCurrencies[currency] = isAdd;
    }

    function enableClaim() public onlyOwner {
        isParticipationEnabled = false;
        PEAPE_TOKEN.safeTransferFrom(msg.sender, address(this), totalTokensSold);
        isClaimEnabled = true;
    }


    function baseTokenToPEAPEToken(uint256 baseTokenAmount) public view returns(uint256) {
        return baseTokenAmount*pricePerToken;
    }


    function swapToETH(
        address inputCurrency,
        uint256 inputAmount,
        uint256 expectedOutputAmount) internal {
        address[] memory path = new address[](2);
        path[0] = inputCurrency;
        path[1] = address(WETH);

        IERC20(inputCurrency).approve(address(dexRouter), inputAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            inputAmount,
            expectedOutputAmount,
            path,
            address(this),
            block.timestamp + 30
        );
    }

  

    function participate() public  payable {
        uint256 peapeAmount = _participate(msg.sender,msg.value);
        emit onParticipate(address(0),msg.value,peapeAmount,msg.value);

    }

    function _participate(address user,uint256 amountPaid) internal returns(uint256 peapeAmount) {
        require(isParticipationEnabled ,"Presale not active");

        peapeAmount = baseTokenToPEAPEToken(amountPaid);
        totalTokensSold += peapeAmount;
        claimableTokens[user] += peapeAmount;

    }



    function participateWithToken(IERC20 token,uint256 amount,uint256 expectedOutputAmount) public  {
        require(isParticipationEnabled ,"Presale not active");
        require(acceptedCurrencies[address(token)],"Token not whitelisted");

        uint256 preBalance = token.balanceOf(address(this));
        token.safeTransferFrom( msg.sender, address(this), amount);
        uint256 finalBalance = token.balanceOf(address(this)) - preBalance;


        uint256 preETHBalance = address(this).balance;
        swapToETH(address(token),finalBalance,expectedOutputAmount);
        uint256 finalETHBalance = address(this).balance-preETHBalance;
        uint256 peapeAmount = _participate(msg.sender,finalETHBalance);
        emit onParticipate(address(token),finalBalance,peapeAmount,finalETHBalance);
        
    }


    function claimTokens() public  {
        require(isClaimEnabled ,"Claim not Enabled");
        uint256 claimableAmount = claimableTokens[msg.sender];
        claimableTokens[msg.sender] = 0;
        claimedTokens[msg.sender] += claimableAmount;
        PEAPE_TOKEN.safeTransfer(msg.sender, claimableAmount);
        emit onClaim(claimableAmount);
    }



    function withdrawToken(IERC20 token) public onlyOwner{
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }


    function withdraw() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }




}
