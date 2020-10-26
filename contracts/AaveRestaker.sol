//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IStakedToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract AaveRestaker is ERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IStakedToken stkAave;                           //stkAAVE interface
    IERC20 aave;                                    //AAVE interface                        
    uint256 public totalStkAave;                    //Total pool stkAAVE
    uint256 public poolRewards;                     //Total pool rewards to claim
    uint256 public totalShares;                     //Total pool shares

    //Initialize variables and approve stkAave
    constructor(address stkAaveAddress, address aaveAddress) ERC20("Pool-Staked AAVE", "pStkAAVE") public {
        stkAave = IStakedToken(stkAaveAddress);
        aave = IERC20(aaveAddress);
        
        totalShares = 0;
        totalStkAave = 0;
        poolRewards = 0;
        uint256 maxInt = uint256(-1);

        aave.safeApprove(address(stkAave), maxInt);
    }

    //Updates pool balances
    function updateStkAaveAndShares() internal {
        totalStkAave = stkAave.balanceOf(address(this));
        totalShares = totalSupply();
    }

    //Deposit function (1e18 shares begins as 1 AAVE)
    //First, fetch the pool's total staked AAVE
    //Then transfer in the caller's AAVE and stake it
    function deposit(uint256 amount) external {
        updateStkAaveAndShares();
        aave.safeTransferFrom(msg.sender, address(this), amount);
        stkAave.stake(address(this), amount);

        //Initialize the user's shares to mint and calculate the appropriate amount
        uint256 sharesToMint = 0;
        if (totalStkAave > 0 && totalShares > 0) {
            sharesToMint = amount.div(totalStkAave).mul(totalShares);
        } else if (totalStkAave == 0 && totalShares == 0) {
            sharesToMint = amount;
        }
        require(sharesToMint >= 0, "No shares to mint.");

        //Assign shares to depositor and update state variables
        _mint(msg.sender, sharesToMint);
        updateStkAaveAndShares();
    }

    //Check total pool pending AAVE rewards
    function checkRewards() external view returns (uint256) {
        return stkAave.getTotalRewardsBalance(address(this));
    }

    //Claims and re-invests AAVE rewards, then update the pool's total stkAAVE
    function claimAndStake() external {
        stkAave.claimRewards(address(this), uint(-1));
        uint256 aaveBalance = aave.balanceOf(address(this));

        require(aaveBalance > 0, "Cannot stake 0 tokens.");
        stkAave.stake(address(this), aaveBalance);

        updateStkAaveAndShares();
    }

    //Withdraws a set amount of shares to transfer stkAAVE back to the user
    //First, fetch the user's shares
    //Next, calculate the amount of stkAAVE to transfer to the user
    //Lastly, transfer them back. Can't use safeTransfer, so manually checking success
    function withdrawShares(uint256 shareCount) external {
        updateStkAaveAndShares(); //Security
        uint256 userShareCount = balanceOf(msg.sender);
        require(userShareCount > 0, "No pool ownership.");
        require(shareCount <= userShareCount, "Cannot withdraw more than what is owned.");
        uint256 stkAaveToWithdraw = shareCount.div(totalShares).mul(totalStkAave);
        bool success = stkAave.transfer(msg.sender, stkAaveToWithdraw);

        require(success, "Transfer failed.");
        _burn(msg.sender, shareCount);
        updateStkAaveAndShares();
    }

    //Returns the user's stkAAVE balance in the pool
    function stkAaveBalanceOf(address query) external view returns (uint256) {
        uint256 userStkAaveBalance = balanceOf(query).mul(totalStkAave).div(totalShares);
        return userStkAaveBalance;
    }
}