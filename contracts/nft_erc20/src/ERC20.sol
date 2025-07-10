// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint public totalSupply = 0;
    address private owner;

    error OnlyOwner();
    error ZeroAddress();
    error InsufficientBalance();

    mapping(address => uint) private balances;

    event Transfer(address indexed from, address indexed to, uint value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier notZeroAddress(address _to) {
        if (_to == address(0)) revert ZeroAddress();
        _;
    }

    function _mint(address _to, uint _amount) private notZeroAddress(_to) {
        totalSupply += _amount;
        balances[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
    }

    function mint(address to, uint amount) public onlyOwner notZeroAddress(to) {
        _mint(to, amount);
    }

    function balanceOf(address account) public view returns (uint) {
        return balances[account];
    }

    function transfer(address _to, uint _amount) public notZeroAddress(_to) {
        if (balances[msg.sender] < _amount) revert InsufficientBalance();

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
    }
}
