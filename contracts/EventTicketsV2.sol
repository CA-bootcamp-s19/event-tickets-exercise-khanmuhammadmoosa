pragma solidity ^0.5.0;

/*
    The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
 */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    uint   PRICE_TICKET = 100 wei;
    address payable public owner;
/*
    Create a variable to keep track of the event ID numbers.
*/
    uint public idGenerator;
    uint[] public idNumbers;
/*
    Define an Event struct, similar to the V1 of this contract.
    The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
    Choose the appropriate variable type for each field.
    The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
*/
    struct Event {
    string description;
    string website;
    uint totalTickets;
    uint sales;
    mapping(address => uint) buyers;
    bool isOpen;
}
/*
    Create a mapping to keep track of the events.
    The mapping key is an integer, the value is an Event struct.
    Call the mapping "events".
*/
    mapping(uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

/*
    Create a modifier that throws an error if the msg.sender is not the owner.
*/
    modifier onlyOwner(){require(msg.sender == owner); _;}
    modifier isOpen(uint _eventID){require(events[_eventID].isOpen, "Sale of tickets now over"); _;}

    constructor() public{
        owner = msg.sender;
        idGenerator = 0;
    }
/*
    Define a function called addEvent().
    This function takes 3 parameters, an event description, a URL, and a number of tickets.
    Only the contract owner should be able to call this function.
    In the function:
        - Set the description, URL and ticket number in a new event.
        - set the event to open
        - set an event ID
        - increment the ID
        - emit the appropriate event
        - return the event's ID
*/
    function addEvent(string memory _description, string memory _website, uint _totalTickets) public onlyOwner returns(uint){
    uint eventID = idGenerator;
    events[eventID] = Event({description: _description, website: _website, totalTickets: _totalTickets, sales: 0, isOpen: true});
    idGenerator += 1;
    emit LogEventAdded(_description, _website, _totalTickets, eventID);
    return(eventID);
    }
/*
    Define a function called readEvent().
    This function takes one parameter, the event ID.
    The function returns information about the event this order:
        1. description
        2. URL
        3. tickets available
        4. sales
        5. isOpen
*/
    function readEvent(uint _eventID) public view returns(string memory _description, string memory _website, uint _totalTickets, uint _sales, bool _isOpen)
    {
    Event memory myEvent = events[_eventID];
    return(myEvent.description, myEvent.website, myEvent.totalTickets, myEvent.sales, myEvent.isOpen);
    }
/*
    Define a function called buyTickets().
    This function allows users to buy tickets for a specific event.
    This function takes 2 parameters, an event ID and a number of tickets.
    The function checks:
        - that the event sales are open
        - that the transaction value is sufficient to purchase the number of tickets
        - that there are enough tickets available to complete the purchase
    The function:
        - increments the purchasers ticket count
        - increments the ticket sale count
        - refunds any surplus value sent
        - emits the appropriate event
*/
    function buyTickets(uint _eventID, uint _ticketsPurchased) public payable isOpen(_eventID) {
    require(msg.value >= _ticketsPurchased * PRICE_TICKET, "Not sufficient funds");
    require(events[_eventID].totalTickets - events[_eventID].sales >= _ticketsPurchased, "Not enough tickets left, sorry");

    Event storage myEvent = events[_eventID];
    myEvent.buyers[msg.sender] += _ticketsPurchased;
    myEvent.sales += _ticketsPurchased;
    uint amountToRefund = msg.value - (PRICE_TICKET *_ticketsPurchased);
    msg.sender.transfer(amountToRefund);
    emit LogBuyTickets(msg.sender, _eventID, _ticketsPurchased);
    }
/*
    Define a function called getRefund().
    This function allows users to request a refund for a specific event.
    This function takes one parameter, the event ID.
    TODO:
        - check that a user has purchased tickets for the event
        - remove refunded tickets from the sold count
        - send appropriate value to the refund requester
        - emit the appropriate event
*/

//we are refunding all the tickets I guess "just one parameter event ID"
    function getRefund(uint _eventID) public isOpen(_eventID){
    require(events[_eventID].buyers[msg.sender] > 0, "You do not have any tickets");
//require(events[_eventID].buyers[msg.sender] > _ticketsRefunded, "You do not have any tickets");

    Event storage myEvent = events[_eventID];
    uint ticketsOwned = myEvent.buyers[msg.sender];
    myEvent.buyers[msg.sender] -= ticketsOwned;
    myEvent.sales -= ticketsOwned;
    uint amountToRefund = PRICE_TICKET * ticketsOwned;
    msg.sender.transfer(amountToRefund);
    emit LogGetRefund(msg.sender, _eventID, ticketsOwned);
    }
/*
    Define a function called getBuyerNumberTickets()
    This function takes one parameter, an event ID
    This function returns a uint, the number of tickets that the msg.sender has purchased.
*/
    function getBuyerNumberTickets(uint _eventID) public view returns(uint ticketsPurchased)
    {
    return(events[_eventID].buyers[msg.sender]);
    }
/*
    Define a function called endSale()
    This function takes one parameter, the event ID
    Only the contract owner can call this function
    TODO:
        - close event sales
        - transfer the balance from those event sales to the contract owner
        - emit the appropriate event
*/
function endSale(uint _eventID) public isOpen(_eventID) onlyOwner{
    events[_eventID].isOpen = false;
    uint _profits = events[_eventID].sales * PRICE_TICKET;
    owner.transfer(_profits);
    emit LogEndSale(owner, _profits, _eventID);
    }
}