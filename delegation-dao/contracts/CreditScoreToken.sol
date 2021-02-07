pragma solidity 0.5.2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract CreditScoreToken is ERC20, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;

    MarketSide public MARKET_SIDE; // 0 = Long, 1 = Short
    enum MarketSide { Long, Short }

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 marketSide
    ) public {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = 0;
        MARKET_SIDE = MarketSide(marketSide);
    }


    function mintAndSendToken(uint256 qtyToMint, address recipient) external onlyOwner {
        _mint(recipient, qtyToMint);
    }

    function redeemToken(uint256 qtyToRedeem, address redeemer) external onlyOwner {
        _burn(redeemer, qtyToRedeem);
    }
}
