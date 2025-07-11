// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint public totalSupply = 0;
    address public owner;

    error OnlyOwner();
    error ZeroAddress();
    error InsufficientBalance();
    error InsufficientAllowance();

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) public allowances;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

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

    // Maybe move mint in another contract inheriting from this
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

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint) {
        return allowances[_owner][_spender];
    }

    function transferFrom(
        address _from,
        address _to,
        uint _amount
    ) public notZeroAddress(_from) notZeroAddress(_to) {
        // Check if _from == msg.sender
        if (allowances[_from][msg.sender] < _amount)
            revert InsufficientAllowance();
        allowances[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);
    }

    function approve(
        address _spender,
        uint _amount
    ) public notZeroAddress(_spender) {
        allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
    }

    function burn(uint _amount) public {
        if (balances[msg.sender] < _amount) revert InsufficientBalance();
        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
    }

    function burnFrom(
        address _from,
        uint _amount
    ) public notZeroAddress(_from) {
        if (allowances[_from][msg.sender] < _amount)
            revert InsufficientAllowance();
        allowances[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        totalSupply -= _amount;
        emit Transfer(_from, address(0), _amount);
    }
}
