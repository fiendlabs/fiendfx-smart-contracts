// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockFailedTransferFrom is ERC20Burnable, Ownable {
    error USDFFX__AmountMustBeMoreThanZero();
    error USDFFX__BurnAmountExceedsBalance();
    error USDFFX__NotZeroAddress();

    constructor(address initialOwner)
        ERC20("USDFFX", "USDFFX")
        Ownable(initialOwner)
    {
    }

        function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert USDFFX__AmountMustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert USDFFX__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function transferFrom(address, /*sender*/ address, /*recipient*/ uint256 /*amount*/ )
        public
        pure
        override
        returns (bool)
    {
        return false;
    }
}