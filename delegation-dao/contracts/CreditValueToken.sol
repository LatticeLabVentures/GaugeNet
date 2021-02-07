pragma solidity ^0.5.16;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";


contract CreditValueToken is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        uint8 tokenDecimals
    ) public {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        _mint(msg.sender, initialSupply * 10**uint256(decimals));
    }
}
