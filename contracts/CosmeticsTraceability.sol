// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CosmeticsTraceability {
    struct Product {
        string name;              // Tên sản phẩm
        string batchID;           // Mã lô
        uint manufactureDate;     // Ngày sản xuất (timestamp)
        string origin;            // Nguồn gốc
        bool isAuthentic;         // Xác thực (true nếu chính hãng)
        string[] history;         // Lịch sử trạng thái (mảng string)
        address owner;            // Quyền sở hữu (address ETH của owner hiện tại)
    }

    mapping(uint => Product) public products; // Map ID sản phẩm -> chi tiết
    uint public productCount = 0;             // Đếm sản phẩm

    event ProductCreated(uint id, string name);
    event StatusUpdated(uint id, string newStatus);
    event OwnershipTransferred(uint id, address newOwner); // Event cho chuyển giao

    // Hàm tạo sản phẩm (chỉ nhà sản xuất gọi)
    function createProduct(
        string memory _name,
        string memory _batchID,
        uint _manufactureDate,
        string memory _origin
    ) public {
        productCount++;
        products[productCount] = Product(
            _name,
            _batchID,
            _manufactureDate,
            _origin,
            true,
            new string[](0), // Khởi tạo mảng rỗng đúng cú pháp
            msg.sender       // Owner ban đầu là người gọi hàm (nhà sản xuất)
        );
        products[productCount].history.push("Created by Manufacturer");
        emit ProductCreated(productCount, _name);
    }

    // Hàm cập nhật trạng thái (chỉ owner hiện tại gọi được)
    function updateStatus(uint _id, string memory _newStatus) public {
        require(_id <= productCount && _id > 0, "Invalid product ID");
        require(products[_id].owner == msg.sender, "Only owner can update"); // Restrict quyền
        products[_id].history.push(_newStatus);
        emit StatusUpdated(_id, _newStatus);
    }

    // Hàm chuyển giao quyền sở hữu (chỉ owner hiện tại gọi)
    function transferOwnership(uint _id, address _newOwner) public {
        require(_id <= productCount && _id > 0, "Invalid product ID");
        require(products[_id].owner == msg.sender, "Only current owner can transfer");
        require(_newOwner != address(0), "Invalid new owner address");
        products[_id].owner = _newOwner;
        products[_id].history.push(string(abi.encodePacked("Transferred ownership to ", toAsciiString(_newOwner))));
        emit OwnershipTransferred(_id, _newOwner);
    }

    // Hàm xác thực (người dùng quét QR, trả về thêm owner)
    function verifyProduct(uint _id)
        public
        view
        returns (
            string memory name,
            string memory batchID,
            uint manufactureDate,
            string memory origin,
            bool isAuthentic,
            string[] memory history,
            address owner  // Trả về owner
        )
    {
        require(_id <= productCount && _id > 0, "Invalid product ID");
        Product memory p = products[_id];
        return (
            p.name,
            p.batchID,
            p.manufactureDate,
            p.origin,
            p.isAuthentic,
            p.history,
            p.owner  // Mới
        );
    }

    // Helper để convert address thành string (đã sửa type conversion)
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
