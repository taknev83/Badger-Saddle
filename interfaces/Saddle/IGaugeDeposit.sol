// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// // To complete

interface IGaugeDeposit {
    //     function approve();

    function deposit(
        uint256 _value,
        address _addr,
        bool _claim_rewards
    ) external;

    function claim_rewards(address _user) external;

    function withdraw(uint256 _value) external;

    function claimable_reward(address _user, address _token_amount) external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    // function withdraw(uint256 _value, bool _claim_rewards) external;

    //     function withdraw();

    //     function claim_rewards();

    //     function claimable_rewards();
}
