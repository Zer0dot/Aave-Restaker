// SPDX-License-Identifier: agpl-3.0
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

pragma solidity 0.6.12;

interface IStakedToken is IERC20 {
  function stake(address onBehalfOf, uint256 amount) external ;

  function redeem(address to, uint256 amount) external;

  function cooldown() external;

  function claimRewards(address to, uint256 amount) external;

  function getTotalRewardsBalance(address staker) external view returns (uint256);
}