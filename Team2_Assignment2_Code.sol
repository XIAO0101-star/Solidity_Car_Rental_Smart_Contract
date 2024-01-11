// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract CarRental{

    //This part creates and defines all the variables needed.
    address payable public manager; //Manager of ABC car rental company
    address payable[] public customer; //Customers list of ABC car rental company

    //Structure that stores information about cars
    struct CarInfo{
        uint256 CarId; //Index of cars to be rented
        string CarName; //Vehicle type of the car
        bool isAvailable; //Whether the car is available for rental
        uint256 RentalPrice; //Unit price to rent the car (daily price)
        string LicenseNumber; //License number of the car
    }

    //Structure that stores information about rental orders
    struct Rental{
        uint256 RentalId; //Index of the rental order
        uint256 CarId; //Index of the car to be rented
        uint256 CustomerId; //Index of the customer who rent the car
        address renter; //Owner of the car (manager)
        uint256 startTime; //When the rental begins
        uint256 endTime; //When the rental ends
        uint256 rentalFee; //The calculation result of rental fee
        bool isReturned; //Whether the rented car is returned
        bool isDamaged; //Whether the rented car is damaged
        uint256 damageFee; //The compensation of damage caused by rentee
    }

    //Structure that stores information about customers
    struct Customer{
        uint256 CustomerId;
        address customerAddress;
        uint256 deposit;
    }

    // Define msg.sender and mapping key-value pairs
    constructor() payable{
        manager = payable(msg.sender);
    }

    mapping(uint256 => CarInfo) public cars;
    mapping(uint256 => Rental) public rentals;
    mapping(uint256 => Customer) public customers;
    uint256 public carCount;
    uint256 public rentalCount;
    uint256 public customerCount;
    bool public isAllReturned = false;

    modifier onlyManager(){
        require(msg.sender == manager,"Only owner can perform this action.");
        _;
    }
    
    //Customers should first submit deposit to this contract. 
    //Rental fee and damage compensation should be deducted from this deposit.
    function submitDeposit() public payable {
        require(msg.value > 20); //The deposit should be larger than 20 Wei.
        customer.push(payable(msg.sender));
        customers[customerCount] = Customer(customerCount, msg.sender, msg.value);
        customerCount++;
    }

    //Input cars' information, including Car's name, rental price for a day and license number.
    function addCar(string memory _name, uint256 _rentalPrice, string memory _License) public onlyManager{
        carCount++; //This step produce a unique Car ID for the new car.
        cars[carCount] = CarInfo(carCount, _name, true, _rentalPrice, _License); //Store inputs into structure.
    }

    //Create new rental order by inputting Car ID and the time this rental order begins.
    function rentCar(uint256 _carId, uint256 _startTime, uint256 _customerId) public onlyManager{
        require(cars[_carId].isAvailable,"The car you want to rent is not available."); //Check the wanted car's availability. If not available, this function could not be carried out.
        rentalCount++; //This step produce a unique order ID for the new rental order.
        cars[_carId].isAvailable = false; //Change the status of the car from "available" to "not available".
        rentals[rentalCount] = Rental(rentalCount, _carId, _customerId, msg.sender, _startTime, _startTime, 0, false, false, 0); //Store inputs into structure.
    }

    //Return the car and deduct all fees from the deposit.
    function returnCar(uint256 _rentalId, uint256 _endTime, bool _damaged, uint256 _damageFee) public payable onlyManager{
        require(!rentals[_rentalId].isReturned, "Car has already been returned."); //Check whether the order has already been completed. If completed already, this function cannot be carried out.
        rentals[_rentalId].isReturned = true; //Set order status to "returned".
        rentals[_rentalId].isDamaged = _damaged; //Check whether the car is damaged when returned.
        rentals[_rentalId].endTime = _endTime; //Store end time for this order.
        rentals[_rentalId].damageFee = _damageFee; //Store the compensation amount needed when car is damaged.
        cars[rentals[_rentalId].CarId].isAvailable = true; // Set car's availability to "true".
        rentals[_rentalId].rentalFee = cars[rentals[_rentalId].CarId].RentalPrice * (rentals[_rentalId].endTime - rentals[_rentalId].startTime); //Calcualte rental fee.
        if(_damaged){
            manager.transfer(rentals[_rentalId].rentalFee + rentals[_rentalId].damageFee);
            customers[rentals[_rentalId].CustomerId].deposit -= (rentals[_rentalId].rentalFee + rentals[_rentalId].damageFee); //If damaged, the deduction should include two parts: rental fee and damage compensation.
        } else{
            manager.transfer(rentals[_rentalId].rentalFee);
            customers[rentals[_rentalId].CustomerId].deposit -= rentals[_rentalId].rentalFee; //If not damaged, the deduction should only include rental fee.
        } 
    }

    //Return the deposit balance to the customer. Customer ID starts from 0.
    function returnDeposit(uint256 _rentalId) public{
        require(isAllReturned, "Not all orders made by the same customer returned."); //Only when all orders under the same customer are returned could the contract return the deposit.
        require(rentals[_rentalId].isReturned, "Payment on this rental has not completed."); //Check whether previous deduction has been completed.
        payable(customer[rentals[_rentalId].CustomerId]).transfer(customers[rentals[_rentalId].CustomerId].deposit);
        isAllReturned = false;    
    }

    //Check whether the wanted car is available or not.
    function getCarAvailability (uint256 _carId) public view returns (bool){
        return cars[_carId].isAvailable;
    }

    //Check whether all the orders under the same customer are all returned.
    function getCustomerReturn (uint256 _customerId) public{
        for(uint i=1; i<=rentalCount; i++){
            if(rentals[i].CustomerId == _customerId){
                if (rentals[i].isReturned == true){
                    isAllReturned = true;
                } else {
                    isAllReturned = false;
                    break;
                }
            }
        }
    }
}