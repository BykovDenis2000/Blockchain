// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract PizzaShop {
    // адрес владельца пиццерии
    address public owner; 

    // история заказов покупателя
    mapping(address => Pizza[]) public orderHistory;

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

    constructor() {
        owner = msg.sender;

        menu.push(Pizza("Margherita", 10, owner));
        menu.push(Pizza("Pepperoni", 12, owner ));
        menu.push(Pizza("Vegetarian", 11, owner ));
    }

    // функция заказа пиццы
    function buyPizza(uint256 _index) public payable {
        require(_index < menu.length, "Invalid pizza index");
        require(msg.value == menu[_index].price, "Not enough ether provided");
        
        // проверка количества заказов клиента (если заказов 10 - бесплатная пицца, если 5 - скидка 10%)
        if ((orderHistory[msg.sender].length % 10 == 0) && (orderHistory[msg.sender].length != 0)) {
            emit Reward(msg.sender, "Free pizza!");
            payable(msg.sender).transfer(menu[_index].price);
            setPizzaOwner(_index,msg.sender);
            orderHistory[msg.sender].push(menu[_index]);
            deleteFromShop(_index);
        } else if ((orderHistory[msg.sender].length % 5 == 0) && (orderHistory[msg.sender].length != 0)) {
            emit Reward(msg.sender, "10% discount on next purchase");
            payable(msg.sender).transfer(menu[_index].price* 1 / 10);
            setPizzaOwner(_index,msg.sender);
            orderHistory[msg.sender].push(menu[_index]);
            deleteFromShop(_index);
        } else {
            emit Purchase(msg.sender, menu[_index].name, menu[_index].price);
            setPizzaOwner(_index,msg.sender);
            orderHistory[msg.sender].push(menu[_index]);
            deleteFromShop(_index);
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
}
