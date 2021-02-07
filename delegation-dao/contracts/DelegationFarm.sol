pragma solidity >=0.4.21 <0.6.0;

import "./CreditValueToken.sol";
import "./CreditCostToken.sol";
import "./CreditRiskToken.sol";
import "./CreditScoreToken.sol";
import "./CreditWorkflowToken.sol";

contract TokenFarm{
    string public name = "Delegation Farm";
    address public owner;
    CreditValueToken public creditValueToken;
    CreditCostToken public creditCostToken;

    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    constructor(creditValueToken _creditValueToken, creditCostToken _creditCostToken) public{
        creditValueToken = _creditValueToken;
        creditCostToken = _creditCostToken;
        owner = msg.sender;
    }

    function stakeTokens(uint _amount) public {

        require(_amount>0, "amount cannot be 0");

        creditValueToken.transferFrom(msg.sender, address(this), _amount);

        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    function unstakeTokens() public {
        uint balance = stakingBalance[msg.sender];
        require(balance > 0, "staking balance cannot be 0");
        creditValueToken.transfer(msg.sender, balance);
        creditCostToken.transfer(msg.sender, balance);
        stakingBalance[msg.sender]=0;
        isStaking[msg.sender]=false;
    }

    function issueToken() public{
        require(msg.sender == owner, "caller must be the owner");
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];
            if(balance>0) {
                creditCostToken.transfer(recipient, balance);
                creditValueToken.transfer(recipient, balance);
            }
        }
    }
}
