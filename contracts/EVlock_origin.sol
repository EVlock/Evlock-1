pragma solidity ^0.4.21;

import "./EIP20Interface.sol";
import "./SafeMath.sol";

contract EVlock is EIP20Interface {
    using SafeMath for uint256;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    mapping (uint256 => address) public seller;
    mapping (address => uint256) public sellingAmount;
    mapping (address => uint256) public sellingPrice;


    mapping (address => uint256) public sellSucceed;
    mapping (address => uint256) public sellFailed;

    mapping (address => mapping (address => uint256)) public proceeded;

    uint256 public constant RATE = 1000000;
    string public name;                     // fancy name: EVlock Token
    uint8 public decimals;                  // How many decimals to show.
    string public symbol;                   // EVT
    address public owner;                   // Contract PUblisher
    uint256 seq = 0;
    uint256 donatedEV = 0;
    
    function () payable {
        createTokens();
    }
    
    function EVlock() public {
        balances[msg.sender] = 1000000;               // Give the creator all initial tokens
        totalSupply = 1000000;                        // Update total supply
        name = "EVlock Token";                                   // Set the name for display purposes
        decimals = 0;                            // Amount of decimals for display purposes
        symbol = "EVTT";                               // Set the symbol for display purposes
        owner = msg.sender;   // Owner is me!
    }
    
    function createTokens() payable{    
        
        /* ���� �Լ��� ȣ���� �������� �������� Coin�� Onwer ���� Transaction�ϸ�,
         * �׿� ���ÿ� �ڽ��� ���� �ݾ׿� ����ϰ� ��ū�� ��´�.
         * ��ū�� totlaSupply�� �ø���. */

        require(msg.value > 0);
        uint256 tokens = msg.value.mul(RATE);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        totalSupply = totalSupply.add(tokens);
        owner.transfer(msg.value); // ex) $(����������ּ�).transfer(�ݾ�)
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        /* �Լ��� ȣ���� ������ ��ū�� �������� _to ���� �۱��Ѵ� */
     
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        /* ����� ��ū��ŭ From - To �۱�! */
        
        uint256 allowance = allowed[_from][msg.sender]; 
        require(balances[_from] >= _value && allowance >= _value && _value > 0);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {

        /* ȣ���� ������ ��ū���� return */
        
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {

        /* �Լ��� ȣ���� ������ Ư�� �������� �۱� �����ϰ� Map�� ����. */

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {

        /* From - To �� �۱� �����ϰ� ��ϵǾ��ִ� ��ū�� ������ �����ش� */

        return allowed[_owner][_spender];
    }
    
    function registerSelling(uint256 _amount, uint256 _price) public returns (bool success) {

        /* Seller �� ��ŭ ���ݿ� ��ŭ �Ȱ��� ��� */
        require(_price > 0 && _amount > 0);
        seq = seq.add(1);
        seller[seq] = msg.sender;
        sellingAmount[msg.sender] = _amount;
        sellingPrice[msg.sender] = _price;
        return true;
    }
    
    function buyEV(uint256 _seq, uint256 _amount) public returns (bool success) {

        /* Buyer�� ��ū���� Ư�� Seller�� ��ǰ�� �����ϰ� Token�� ���� */

        require(_seq > 0 && _amount > 0 && sellingAmount[seller[_seq]] >= _amount);
        sellingAmount[seller[_seq]] = sellingAmount[seller[_seq]].sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(sellingPrice[seller[_seq]]*_amount);
        balances[seller[_seq]] = balances[seller[_seq]].add(sellingPrice[seller[_seq]]*_amount);
        return true;
    }
    
    function donateEV(uint256 _amount) public returns (bool success) {

        /* ��ū ��� */ // �ٵ� Payable �� �� �ƴ���..? 

        require(_amount > 0);
        donatedEV = donatedEV.add(_amount);
        return true;
    }

    function creditPointOf(address _owner) public returns (uint creditPoint) {
        if (sellFailed[_owner] == 0) {
            return 100;
        } else {
            creditPoint = (sellSucceed[_owner]*100) / (sellSucceed[_owner]+sellFailed[_owner]);
            return creditPoint;
        }
    }

    function plusCredit(address _from, address _to) public{
        sellSucceed[_from] += 1;
        sellSucceed[_to] += 1;
    }

    /* �۾��� */
    function refund(address _from, address _to, uint256 _value) public returns (bool succeed) {
        sellFailed[_from].add(1);
        sellFailed[_to].add(1);
        uint amountSold = sellingAmount[_from] * proceeded[_from][_to] / 100 ;
        uint priceSold = _value * proceeded[_from][_to] / 100;

        transferFrom(_from, _to, priceSold);
        sellingAmount[_from] = 0;
        sellingPrice[_from] = 0;
        return succeed;
    }
}
