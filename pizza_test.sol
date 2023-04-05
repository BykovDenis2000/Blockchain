// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
// <import file to test>
import "pizza_shop.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {
    PizzaShop pizza;
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // <instantiate contract>
        acc0 = TestsAccounts.getAccount(0); 
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
    }

    /// #sender: account-0
    function createShop() public {
        Assert.equal(msg.sender, acc0, "Invalid sender");
        pizza = new PizzaShop(msg.sender);
        Assert.equal(pizza.getOwner(), msg.sender, "Invalid owner");
    }

    /// #value: 10
    function checkPizzaOrder() public payable {
        pizza.addPizzaToCart(0, 1);
        Assert.equal(pizza.getCost(), 10, "Invalid cart cost");
        pizza.buyPizza{value:msg.value}();
        Assert.equal(pizza.getCost(), 0, "Invalid cart cost");
    }

    /// #value: 11
    function checkPizzaPurchase() public payable {
        pizza.addPizzaToCart(0, 1);
        Assert.equal(pizza.getCost(), 11, "Invalid cart cost");
        pizza.buyPizza{value:msg.value}();
        Assert.equal(pizza.getCost(), 0, "Invalid cart cost");
        pizza.clearCart();
    }

    /// #value: 12
    function checkClearCart() public payable {
        pizza.addPizzaToCart(0, 1);
        Assert.equal(pizza.getCost(), 12, "Invalid cart cost");
        pizza.clearCart();
        Assert.equal(pizza.getCost(), 0, "Cart is not cleared");
        pizza.clearCart();
    }

}
    