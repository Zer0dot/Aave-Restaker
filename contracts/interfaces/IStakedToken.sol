// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IStakedToken {
  function stake(address onBehalfOf, uint256 amount) external ;

  function redeem(address to, uint256 amount) external;

  function cooldown() external;

  function claimRewards(address to, uint256 amount) external;

  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);

  function getTotalRewardsBalance(address staker) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);
}