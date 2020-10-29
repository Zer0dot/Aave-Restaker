//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IStakedToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract AaveRestaker is ERC20 {
    using SafeERC20 for IERC20;
    using SafeERC20 for IStakedToken;
    using SafeMath for uint256;

    address public manager;                 //Strategist address (where the fees go)
    IStakedToken stkAave;                   //stkAAVE interface
    IERC20 aave;                            //AAVE interface                        
    uint256 public totalStkAave;            //Total pool stkAAVE
    uint256 public poolRewards;             //Total pool rewards to claim
    uint256 public totalShares;             //Total pool shares
    uint256 public fee;                     //Current fee in bps (1 = 0.01%) (Charged on compounding ONLY)
    /*
    REMOVED MAX FEE, REASON: There is no need for a fee cap, 
    the fee is public and only charged upon compounding.
    Thus, no losses can occur for holders. Should the manager become a DAO,
    it is encouraged that fees be thoroughly calculated to maintain
    profitability over simply non-compounding stkAAVE.
    uint256 public maxFee;                  //Max fee in bps
    */

    

    //Initialize variables and approve stkAave
    constructor(address stkAaveAddress, address aaveAddress, uint256 _fee, address _manager) ERC20("Pool-Staked AAVE", "pStkAAVE") public {
        stkAave = IStakedToken(stkAaveAddress);
        aave = IERC20(aaveAddress);
        
        totalShares = 0;
        totalStkAave = 0;
        poolRewards = 0;
        uint256 maxInt = uint256(-1);

        fee = _fee;
        manager = _manager;

        aave.safeApprove(address(stkAave), maxInt);
    }

    event Deposit(
        address indexed _from,
        uint256 _value
    );

    event ClaimAndStake(
        uint256 _value,
        uint256 _fee
    );

    event Withdraw(
        address indexed _from,
        uint256 _shares
    );

    event FeeChanged(
        uint256 _newFee
    );

    modifier onlyManager {
        require(msg.sender == manager, "Only the manager can call this function.");
        _;
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
            sharesToMint = amount.mul(totalShares).div(totalStkAave);
        } else if (totalStkAave == 0 && totalShares == 0) {
            sharesToMint = amount;
        }
        require(sharesToMint > 0, "No shares to mint.");

        //Assign shares to depositor and update state variables
        _mint(msg.sender, sharesToMint);

        updateStkAaveAndShares();
        emit Deposit(msg.sender, amount);
    }

    //Check total pool pending AAVE rewards
    function checkRewards() external view returns (uint256) {
        return stkAave.getTotalRewardsBalance(address(this));
    }

    //Claims and re-invests AAVE rewards, then update the pool's total stkAAVE
    function claimAndStake() external onlyManager {
        stkAave.claimRewards(address(this), uint(-1));
        uint256 aaveBalance = aave.balanceOf(address(this));
        require(aaveBalance > 0, "Cannot stake 0 tokens.");

        //Calculate fee
        uint256 aaveFee = aaveBalance.mul(fee).div(10000);
        
        //Transfer AAVE fee
        aave.safeTransfer(manager, aaveFee);

        //Stake AAVE
        stkAave.stake(address(this), aaveBalance);

        updateStkAaveAndShares();
        emit ClaimAndStake(aaveBalance, aaveFee);
    }

    //Withdraws a set amount of shares to transfer stkAAVE back to the user
    //First, fetch the user's shares
    //Next, calculate the amount of stkAAVE to transfer to the user
    //Lastly, transfer them back. Can't use safeTransfer, so manually checking success
    function withdrawShares(uint256 shareCount) external {
        updateStkAaveAndShares(); //Security
        uint256 userShareCount = balanceOf(msg.sender);
        require(userShareCount > 0, "No pool ownership.");
        shareCount = shareCount > userShareCount ? userShareCount : shareCount; 
        uint256 stkAaveToWithdraw = shareCount.mul(totalStkAave).div(totalShares);

        _burn(msg.sender, shareCount);
        stkAave.safeTransfer(msg.sender, stkAaveToWithdraw);

        updateStkAaveAndShares();
        emit Withdraw(msg.sender, shareCount);
    }

    //Returns the user's stkAAVE balance in the pool
    function stkAaveBalanceOf(address query) external view returns (uint256) {
        require(balanceOf(query) > 0, "Queried address has no shares.");
        uint256 userStkAaveBalance = balanceOf(query).mul(totalStkAave).div(totalShares);
        return userStkAaveBalance;
    }

    function transferManager(address target) external onlyManager {
        manager = target;
    }

    function changeFeeBps(uint256 newFee) external onlyManager {
        fee = newFee;
        emit FeeChanged(newFee);
    }
}