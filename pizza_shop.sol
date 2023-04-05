// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PizzaShop {
    // адрес владельца пиццерии
    address public owner; 
    // токен ERC20
    ERC20 public loyaltyToken;
    // история заказов покупателя
    mapping(address => Pizza[]) public orderHistory;
    // бонусные баллы покупателя
    mapping(address => uint256) public bonusPoints;
    // стоимость товаров в корзине
    mapping(address => uint256) public cartCost;
    // пиццы в корзине
    mapping(address => Pizza[]) public pizzaCart;

    // пицца
    struct Pizza {
        string name;
        uint256 price;
        address owner;
    }

    // меню
    Pizza[] private menu;

    // событие обычной покупки
    event Purchase(address indexed buyer, string pizzaName, uint256 amount);

    // событие когда заказ со скидкой / бесплатный
    event Reward(address indexed buyer, string rewardType);

    constructor(address own) {
        owner = own;
        loyaltyToken = new LoyaltyToken();
        menu.push(Pizza("Margherita", 10, owner));
        menu.push(Pizza("Pepperoni",  12, owner));
        menu.push(Pizza("Vegetarian", 11, owner));
    }

    function addPizzaToCart(uint256 _index, uint256 _size) public {
        require(_index < menu.length, "Invalid pizza index");
        require(_size != 1 || _size != 2 || _size != 3, "Invalid pizza size");
        uint256 totalCost = menu[_index].price * _size;

        // Применение скидки на основе бонусных баллов
        while (bonusPoints[msg.sender] >= 10) {
            bonusPoints[msg.sender] -= 10;
            loyaltyToken.transferFrom(msg.sender, address(this), 10);
            totalCost -= 1;
        }
        pizzaCart[msg.sender].push(menu[_index]);
        setPizzaOwner(_index, msg.sender);
        deleteFromShop(_index);
        cartCost[msg.sender] += totalCost;
    }

    function getCost() public view returns (uint256) {
        return cartCost[msg.sender];
    }

    function clearCart() public {
        cartCost[msg.sender] = 0;
        for(uint256 i = 0; i < pizzaCart[msg.sender].length; i++) {
            menu.push(pizzaCart[msg.sender][i]);
        }

        while(pizzaCart[msg.sender].length > 0) {
            pizzaCart[msg.sender].pop();
        }
    }

    // функция заказа пиццы
    function buyPizza() public payable {

        require(msg.value >= cartCost[msg.sender], "Not enough ether provided");

        // добавление бонусных баллов на аккаунт клиента
        bonusPoints[msg.sender] += cartCost[msg.sender] / 10;
        loyaltyToken.transfer(msg.sender, bonusPoints[msg.sender]);
        // проверка количества заказов клиента (если заказов 10 - бесплатная пицца, если 5 - скидка 10%)
        if ((orderHistory[msg.sender].length % 10 == 0) && (orderHistory[msg.sender].length != 0)) {
            emit Reward(msg.sender, "Free pizza!");
            payable(msg.sender).transfer(cartCost[msg.sender]);
            for(uint256 i = 0; i < pizzaCart[msg.sender].length; i++) {
                orderHistory[msg.sender].push(pizzaCart[msg.sender][i]);
            }
        } else if ((orderHistory[msg.sender].length % 5 == 0) && (orderHistory[msg.sender].length != 0)) {
            emit Reward(msg.sender, "10% discount on next purchase");
            payable(msg.sender).transfer(cartCost[msg.sender]* 1 / 10);
            for(uint256 i = 0; i < pizzaCart[msg.sender].length; i++) {
                orderHistory[msg.sender].push(pizzaCart[msg.sender][i]);
            }
        } else {
            for(uint256 i = 0; i < pizzaCart[msg.sender].length; i++) {
                emit Purchase(msg.sender, pizzaCart[msg.sender][i].name, pizzaCart[msg.sender][i].price);
                orderHistory[msg.sender].push(pizzaCart[msg.sender][i]);
            }
        }
        cartCost[msg.sender] = 0;
        while(pizzaCart[msg.sender].length > 0) {
            pizzaCart[msg.sender].pop();
        }
    }

    // вывод средств с адреса контракта на счет владельца
    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        payable(owner).transfer(address(this).balance);
    }

    // добавление новой пиццы в меню
    function addPizza(string memory _name, uint256 _price) public {
        require(msg.sender == owner, "Only the owner can add pizzas");
        menu.push(Pizza(_name, _price, owner));
    }
    
    // смена владельца
    function setPizzaOwner(uint256 _index, address _newOwner) private {
        require(menu[_index].owner != _newOwner, "The owner cannot be the same");
        menu[_index].owner = _newOwner;
    }

    // вывод меню
    function getMenu() public view returns (Pizza[] memory) {
        return menu;
    }

    // удаление пиццы из меню
    function deleteFromShop(uint256 index) private {
        require(index < menu.length);
        menu[index] = menu[menu.length - 1];
        menu.pop();
    }    
    
    function getOwner() public view returns (address) {
        return owner;
    }

    function getTokenBalance(address _address) public view returns (uint256) {
        return loyaltyToken.balanceOf(_address);
    }
}
contract LoyaltyToken is ERC20 {
    constructor() ERC20("Pizza Loyalty Token", "PLT") {
        _mint(msg.sender, 1000000000000000000000000); // инициализация 1 млрд токенов
    }
}